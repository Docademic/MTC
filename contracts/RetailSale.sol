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
    bool public closed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event CrowdsaleClose(uint totalAmountRaised, bool fundingGoalReached);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function CrowdSale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward,
        uint tokensPerEth,
        uint bonusEachToken,
        uint decimalsDifftoEth,
        uint fundingGoalInEthers,
        uint hardCapInEth,
        uint startTimeInSeconds,
        uint durationInMinutes
    ) public {
        beneficiary = ifSuccessfulSendTo;
        tokenReward = token(addressOfTokenUsedAsReward);
        price = tokensPerEth * 1 ether;
        bonus = bonusEachToken;
        decDiff = decimalsDifftoEth;
        fundingGoal = fundingGoalInEthers * 1 ether;
        hardCap = hardCapInEth * 1 ether;
        startTime = startTimeInSeconds;
        deadline = startTimeInSeconds + durationInMinutes * 1 minutes;
    }

    /**
     * Do purchase process
     *
     */
    function purchase() internal {
        uint amount = msg.value;
        uint vp = amount * price;
        uint tokens = ((vp + ((vp * bonus) / 100)) / 10 ** decDiff) / 1 ether;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transferFrom(beneficiary, msg.sender, tokens);
        checkGoalReached();
        FundTransfer(msg.sender, amount, true);
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
    hardCapNotReached
    public {
        purchase();
    }

    /**
     * The function called only from shiftsale
     *
     */
    function shiftSalePurchase()
    payable
    isOpen
    afterStart
    hardCapNotReached
    public returns (bool success) {
        purchase();
        return true;
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

    modifier hardCapNotReached() {
        require(amountRaised < hardCap);
        _;
    }

    /**
     * Check if goal was reached
     *
     */
    function checkGoalReached() internal {
        if (amountRaised >= fundingGoal && !fundingGoalReached) {
            fundingGoalReached = true;
            GoalReached(beneficiary, amountRaised);
        }
    }

    /**
     * Close the crowdsale
     *
     */
    function closeCrowdsale()
    isOwner
    public {
        crowdsaleClosed = true;
        CrowdsaleClose(amountRaised, fundingGoalReached);
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
    public {
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}
