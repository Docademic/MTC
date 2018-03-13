pragma solidity ^0.4.0;

import "../ownership/Ownable.sol";

contract Destroyable is Ownable{
    /**
     * @notice Allows to destroy the contract and return the tokens to the owner.
     */
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}
