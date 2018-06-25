pragma solidity ^0.4.21;

import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";
import "./util/Destroyable.sol";

interface Token {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address who) view external returns (uint256);
}

contract TokenVault is Ownable, Destroyable {
    using SafeMath for uint256;

    Token public token;

    /**
     * @dev Constructor.
     * @param _token The token address
     */
    constructor(address _token) public{
        require(_token != address(0));
        token = Token(_token);
    }

    /**
     * @dev Get the token balance of the contract.
     * @return _balance The token balance of this contract in wei
     */
    function Balance() view public returns (uint256 _balance) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Get the token balance of the contract.
     * @return _balance The token balance of this contract in ether
     */
    function BalanceEth() view public returns (uint256 _balance) {
        return token.balanceOf(address(this)) / 1 ether;
    }

    /**
     * @dev Allows the owner to flush the tokens of the contract.
     */
    function transferTokens(address _to, uint256 amount) public onlyOwner {
        token.transfer(_to, amount);
    }


    /**
     * @dev Allows the owner to flush the tokens of the contract.
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
