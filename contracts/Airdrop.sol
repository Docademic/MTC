pragma solidity ^0.4.24;

import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";
import "./util/Destroyable.sol";

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address who) view external returns (uint256);
}

contract Airdrop is Ownable, Destroyable {
    using SafeMath for uint256;

    /*
     *   Structs
     */
    // Holder of tokens
    struct Beneficiary {
        uint256 balance;
        uint256 airdrop;
        bool isBeneficiary;
    }

    /*
     *  State
     */
    //todo: Add token distribution behavior (control, limit, etc...)
    bool public filled;
    bool public airdropped;
    uint256 public tokensRequired;
    Token public token;
    mapping(address => Beneficiary) public beneficiaries;
    address[] public addresses;


    /*
     *  Events
     */
    event NewBeneficiary(address _beneficiary);
    event SnapshotTaken(uint256 _totalBalance, uint256 _totalAirdrop, uint256 _numberOfBeneficiaries, uint256 _numberOfAirdrops);
    event Airdropped(uint256 _totalAirdrop, uint256 _numberOfAirdrops);
    event TokenChanged(address _prevToken, address _token);
    event Cleaned(uint256 _numberOfBeneficiaries);

    /*
     *  Modifiers
     */
    modifier isNotBeneficiary(address _beneficiary) {
        require(!beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isBeneficiary(address _beneficiary) {
        require(beneficiaries[_beneficiary].isBeneficiary);
        _;
    }
    modifier isFilled() {
        require(filled);
        _;
    }
    modifier isNotFilled() {
        require(!filled);
        _;
    }
    modifier wasAirdropped() {
        require(airdropped);
        _;
    }
    modifier wasNotAirdropped() {
        require(!airdropped);
        _;
    }

    /*
     *  Behavior
     */

    /**
     * @dev Constructor.
     * @param _token The token address
     */
    constructor(address _token) public{
        require(_token != address(0));
        token = Token(_token);
    }

    /**
     * @dev Allows the sender to register itself as a beneficiary for the airdrop.
     */
    function() payable public {
        addBeneficiary(msg.sender);
    }


    /**
     * @dev Allows the sender to register itself as a beneficiary for the airdrop.
     */
    function register() public {
        addBeneficiary(msg.sender);
    }

    /**
     * @dev Allows the owner to register a beneficiary for the airdrop.
     * @param _beneficiary The address of the beneficiary
     */
    function registerBeneficiary(address _beneficiary) public
    onlyOwner {
        addBeneficiary(_beneficiary);
    }

    /**
     * @dev Add a beneficiary for the airdrop.
     * @param _beneficiary The address of the beneficiary
     */
    function addBeneficiary(address _beneficiary) private
    isNotBeneficiary(_beneficiary) {
        require(_beneficiary != address(0));
        beneficiaries[_beneficiary] = Beneficiary({
            balance : 0,
            airdrop : 0,
            isBeneficiary : true
            });
        addresses.push(_beneficiary);
        emit NewBeneficiary(_beneficiary);
    }

    /**
     * @dev Take the balance of all the beneficiaries.
     */
    function takeSnapshot() public
    onlyOwner
    isNotFilled
    wasNotAirdropped {
        uint256 totalBalance = 0;
        uint256 totalAirdrop = 0;
        uint256 airdrops = 0;
        for (uint i = 0; i < addresses.length; i++) {
            uint256 balance = token.balanceOf(addresses[i]);
            //todo: make airdrop calculation
            uint256 airdrop = 0;
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            beneficiary.isBeneficiary = false;
            beneficiary.balance = balance;
            beneficiary.airdrop = airdrop;
            totalBalance = totalBalance.add(balance);
            if (airdrop > 0) {
                totalAirdrop = totalAirdrop.add(airdrop);
                airdrops = airdrops.add(1);
            }
        }
        tokensRequired = totalAirdrop;
        filled = true;
        emit SnapshotTaken(totalBalance, totalAirdrop, addresses.length, airdrops);
    }

    /**
     * @dev Start the airdrop.
     */
    function airdrop() public
    onlyOwner
    isFilled
    wasNotAirdropped {
        uint256 airdrops = 0;
        uint256 totalAirdrop = 0;
        for (uint256 i = 0; i < addresses.length; i++)
        {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            if (beneficiary.airdrop > 0) {
                require(token.transfer(addresses[i], beneficiary.airdrop));
                totalAirdrop = totalAirdrop.add(beneficiary.airdrop);
                airdrops = airdrops.add(1);
            }
        }
        tokensRequired = tokensRequired.sub(totalAirdrop);
        airdropped = true;
        emit Airdropped(totalAirdrop, airdrops);
    }

    /**
     * @dev Reset all the balances to 0 and the state to false.
     */
    function clean() public
    onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++)
        {
            Beneficiary storage beneficiary = beneficiaries[addresses[i]];
            beneficiary.balance = 0;
            beneficiary.airdrop = 0;
        }
        filled = false;
        airdropped = false;
        emit Cleaned(addresses.length);
    }

    /**
     * @dev Get the remain MTC on the contract.
     * @return _balance The token balance of this contract
     */
    function Balance() view public returns (uint256 _balance) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Allows the owner to change the token address.
     * @param _token New token address.
     */
    function changeToken(address _token) public
    onlyOwner {
        emit TokenChanged(address(token), _token);
        token = Token(_token);

    }

    /**
     * @dev Allows the owner to flush the eth.
     */
    function flushEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    /**
     * @dev Allows the owner to flush the eth.
     */
    function flushTokens() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Allows the owner to destroy the contract and return the tokens to the owner.
     */
    function destroy() public onlyOwner {
        token.transfer(owner, token.balanceOf(address(this)));
        selfdestruct(owner);
    }
}
