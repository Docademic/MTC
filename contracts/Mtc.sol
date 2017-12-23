pragma solidity ^0.4.18;
/**
 * Changes by https://www.docademic.com/
 */

import "./token/StandardToken.sol";
import "./ownership/Ownable.sol";

contract Mtc is StandardToken, Ownable {
  event WalletFunded(address wallet, uint256 amount);
  
  string public name;
  string public symbol;
  uint8 public decimals;
  address public wallet;

  function Mtc(string _name, string _symbol, uint256 _totalSupply, uint8 _decimals, address _multiSig) public {
    require(_multiSig != address(0));
    require(_multiSig != msg.sender);
    require(_totalSupply > 0);
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    decimals = _decimals;
    wallet = _multiSig;

    /** todos los tokens a la cartera principal */
    fundWallet(_multiSig, _totalSupply);

    /** transferimos el ownership */
    transferOwnership(_multiSig);
 }

 function fundWallet(address _wallet, uint256 _amount) internal {
     /** validaciones */
    require(_wallet != address(0));
    require(_amount > 0);
     
     balances[_wallet] = balances[_wallet].add(_amount);

     /** notificamos la operación */
     WalletFunded(_wallet, _amount);
     Transfer(address(0), _wallet, _amount);
 }
}