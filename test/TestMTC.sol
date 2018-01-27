pragma solidity ^0.4.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MTC.sol";

contract TestMTC {

    function testName() public {
        MTC mtc = MTC(DeployedAddresses.MTC());
        uint expected = 1000000000;
        address multisig = address("0x4022e93637a6e35a9da09cbd02c605c7d4b24d99");
        Assert.equal(mtc.balanceOf(multisig), expected, "Name Incorrect");
    }

}