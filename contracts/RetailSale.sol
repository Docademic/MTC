pragma solidity ^0.4.18;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) public;
}

contract CrowdSale {
    address public beneficiary;
    uint public startTime;
    uint public deadline;
    uint public price;
    uint public decDiff;
    token public tokenReward;
    bool public crowdsaleClosed = false;

    event FundTransfer(address backer);
    event CrowdsaleClose();

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function CrowdSale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward,
        uint tokensPerEth,
        uint decimalsDifftoEth,
        uint startTimeInSeconds,
        uint durationInMinutes
    ) public {
        beneficiary = ifSuccessfulSendTo;
        tokenReward = token(addressOfTokenUsedAsReward);
        price = tokensPerEth * 1 ether;
        decDiff = decimalsDifftoEth;
        startTime = startTimeInSeconds;
        deadline = startTimeInSeconds + durationInMinutes * 1 minutes;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function()
    payable
    isOpen
    afterStart
    public {
        uint vp = msg.value * price;
        uint tokens = vp / 10 ** decDiff / 1 ether;
        tokenReward.transferFrom(beneficiary, msg.sender, tokens);
        FundTransfer(msg.sender);
    }



    modifier afterStart() {
        require(now >= startTime);
        _;
    }

    modifier afterDeadline() {
        require(now >= deadline);
        _;
    }

    modifier previousDeadline() {
        require(now <= deadline);
        _;
    }

    modifier isOwner() {
        require(msg.sender == beneficiary);
        _;
    }

    modifier isClosed() {
        require(crowdsaleClosed);
        _;
    }

    modifier isOpen() {
        require(!crowdsaleClosed);
        _;
    }

    /**
     * Close the crowdsale
     *
     */
    function closeCrowdsale()
    isOwner
    public {
        crowdsaleClosed = true;
        CrowdsaleClose();
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal()
    afterDeadline
    isClosed
    isOwner
    public {

        if (beneficiary.send(this.balance)) {
            FundTransfer(beneficiary);
        }

    }
}
