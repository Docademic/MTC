pragma solidity ^0.4.18;

interface Crowdsale {
    function safeWithdrawal() public;
}

interface Token {
    function transfer(address _to, uint256 _value) public;
}

contract ShiftSale {

    Crowdsale public crowdSale;
    address public crowdSaleAddress;
    Token public token;
    uint public fee;
    bytes32 private secret;

    modifier validate(string _secret){
        require(secret==sha256(_secret));
        _;
    }

    event FundTransfer(uint amount);

    /// @dev Contract constructor sets initial Token, Crowdsale and the secret password to access the public methods.
    /// @param _crowdSale Address of the Crowdsale contract.
    /// @param _token Address of the Token contract.
    /// @param _secret The secret code used as password.
    function ShiftSale(
        address _crowdSale,
        address _token,
        string _secret,
        uint _fee
    ) public {
        crowdSaleAddress = _crowdSale;
        crowdSale = Crowdsale(_crowdSale);
        token = Token(_token);
        secret = sha256(_secret);
        fee = _fee;
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

    /// @dev Allows to transfer MTC tokens. Transaction has to be sent with the secret password.
    /// @param _to Destination address.
    /// @param _value quantity of MTC tokens to transfer.
    /// @param _secret The secret code used as password.
    function transfer(address _to, uint256 _value, string _secret)
    validate(_secret)
    public{
        token.transfer(_to, _value);
    }

    /// @dev Allows to withdraw the ETH from the CrowdSale contract. Transaction has to be sent with the secret password.
    /// @param _secret The secret code used as password.
    function withdrawal(string _secret)
    validate(_secret)
    public{
        crowdSale.safeWithdrawal();
    }

    /// @dev Allows to refund the ETH to destination address. Transaction has to be sent with the secret password.
    /// @param _to Destination address.
    /// @param _value Wei to transfer.
    /// @param _secret The secret code used as password.
    function refund(address _to, uint256 _value, string _secret)
    validate(_secret)
    public{
        _to.transfer(_value);
    }

    /// @dev Allows to change the fee value. Transaction has to be sent with the secret password.
    /// @param _fee New value for the fee.
    /// @param _secret The secret code used as password.
    function setFee(uint _fee,string _secret)
    validate(_secret)
    public{
        fee = _fee;
    }

    /// @dev Allows to change the secret password. Transaction has to be sent with the secret password.
    /// @param _newSecret The new secret code used as password.
    /// @param _secret The secret code used as password.
    function setSecret(string _newSecret,string _secret)
    validate(_secret)
    public{
        secret = sha256(_newSecret);
    }

}
