pragma solidity ^0.4.18;

interface Crowdsale {
    function safeWithdrawal() public;
}

interface Token {
    function transfer(address _to, uint256 _value) public;
}

contract ShiftSale {

    Crowdsale public crowdSale;
    Token public token;

    address public crowdSaleAddress;
    address[] public owners;
    bytes32 private secret;
    mapping (address => bool) public isOwner;
    uint public fee;
    /*
     *  Constants
     */
    uint constant public MAX_OWNER_COUNT = 10;

    event FundTransfer(uint amount);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);

    /// @dev Contract constructor sets initial Token, Crowdsale and the secret password to access the public methods.
    /// @param _crowdSale Address of the Crowdsale contract.
    /// @param _token Address of the Token contract.
    /// @param _owners An array containing the owner addresses.
    /// @param _fee The Shapeshift transaction fee to cover gas expenses.
    function ShiftSale(
        address _crowdSale,
        address _token,
        address[] _owners,
        uint _fee
    ) public {
        crowdSaleAddress = _crowdSale;
        crowdSale = Crowdsale(_crowdSale);
        token = Token(_token);
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        fee = _fee;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }
    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }
    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }
    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function()
    payable
    public {
        if(crowdSaleAddress.send(msg.value-fee)){
            FundTransfer(msg.value-fee);
        }
    }
    /// @dev Allows to add a new owner. Transaction has to be sent by an owner.
    /// @param owner Address of new owner.
    function addOwner(address owner)
    public
    ownerDoesNotExist(owner)
    notNull(owner)
    ownerExists(msg.sender)
    {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }
    /// @dev Allows to remove an owner. Transaction has to be sent by an owner.
    /// @param owner Address of owner.
    function removeOwner(address owner)
    public
    ownerExists(msg.sender)
    ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        OwnerRemoval(owner);
    }
    /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by an owner.
    /// @param owner Address of owner to be replaced.
    /// @param newOwner Address of new owner.
    function replaceOwner(address owner, address newOwner)
    public
    ownerExists(msg.sender)
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
    notNull(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }
    /// @dev Returns list of owners.
    /// @return List of owner addresses.
    function getOwners()
    public
    constant
    returns (address[])
    {
        return owners;
    }
    /// @dev Allows to transfer MTC tokens. Can only be executed by an owner.
    /// @param _to Destination address.
    /// @param _value quantity of MTC tokens to transfer.
    /// @param _secret The secret code used as password.
    function transfer(address _to, uint256 _value)
    ownerExists(msg.sender)
    public{
        token.transfer(_to, _value);
    }
    /// @dev Allows to withdraw the ETH from the CrowdSale contract. Transaction has to be sent by an owner.
    /// @param _secret The secret code used as password.
    function withdrawal()
    ownerExists(msg.sender)
    public{
        crowdSale.safeWithdrawal();
    }
    /// @dev Allows to refund the ETH to destination address. Transaction has to be sent by an owner.
    /// @param _to Destination address.
    /// @param _value Wei to transfer.
    /// @param _secret The secret code used as password.
    function refund(address _to, uint256 _value)
    ownerExists(msg.sender)
    public{
        _to.transfer(_value);
    }
    /// @dev Allows to change the fee value. Transaction has to be sent by an owner.
    /// @param _fee New value for the fee.
    /// @param _secret The secret code used as password.
    function setFee(uint _fee)
    ownerExists(msg.sender)
    public{
        fee = _fee;
    }

}
