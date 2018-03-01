pragma solidity ^0.4.18;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public;
}

contract RetailSale {
    address public beneficiary;
    uint public price;
    uint public bonus = 0;
    uint public bonusStart = 0;
    uint public bonusEnd = 0;
    uint public milestone = 0;
    uint public milestoneBonus = 0;
    bool public milestoneReached = false;
    uint public minPurchase;
    bool public closed = true;
    token public tokenReward;

    event FundTransfer(address backer, uint amount, uint bonus, uint tokens);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function RetailSale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward,
        uint tokensPerEth,
        uint _minPurchase
    ) public {
        beneficiary = ifSuccessfulSendTo;
        tokenReward = token(addressOfTokenUsedAsReward);
        price = tokensPerEth;
        minPurchase = _minPurchase;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function()
    payable
    isOpen
    aboveMinValue
    public {
        uint amount = msg.value;
        uint vp = amount * price;
        uint b = 0;
        uint tokens = 0;
        if (now >= bonusStart && now <= bonusEnd) {
            b = bonus;
        }
        if (this.balance >= milestone && !milestoneReached) {
            b = milestoneBonus;
            milestoneReached = true;
        }
        if (b == 0) {
            tokens = vp / 1 ether;
        } else {
            tokens = (vp + ((vp * b) / 100)) / 1 ether;
        }
        tokenReward.transferFrom(beneficiary, msg.sender, tokens);
        FundTransfer(msg.sender, msg.value, b, tokens);
    }

    modifier aboveMinValue() {
        require(msg.value >= minPurchase);
        _;
    }

    modifier isOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    modifier isClosed() {
        require(closed);
        _;
    }

    modifier isOpen() {
        require(!closed);
        _;
    }

    /**
     * Toggle the crowdsale state
     * @param _closed the new state bool.
     */
    function toggleCrowdsale(bool _closed)
    isOwner
    public {
        closed = _closed;
    }

    /**
     * Set the new min purchase value
     * @param _minPurchase the new minpurchase value in wei.
     */
    function setMinPurchase(uint _minPurchase)
    isOwner
    public {
        minPurchase = _minPurchase;
    }

    /**
     * Change the bonus percentage
     * @param _bonus the new bonus percentage.
     * @param _bonusStart When the bonus starts in seconds.
     * @param _bonusEnd When the bonus ends in seconds.
     */
    function changeBonus(uint _bonus, uint _bonusStart, uint _bonusEnd)
    isOwner
    public {
        bonus = _bonus;
        bonusStart = _bonusStart;
        bonusEnd = _bonusEnd;
    }

    /**
     * Change the next milestone
     * @param _milestone The next milestone amount in wei
     * @param _milestoneBonus The bonus of the next milestone
     */
    function setNextMilestone(uint _milestone, uint _milestoneBonus)
    isOwner
    public {
        milestone = _milestone;
        milestoneBonus = _milestoneBonus;
        milestoneReached = false;
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal()
    isClosed
    isOwner
    public {

        beneficiary.transfer(this.balance);

    }

}
