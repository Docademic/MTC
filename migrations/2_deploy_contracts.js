const Token = artifacts.require("Mtc");
module.exports = function (deployer, network, accounts) {
    // const startTime = web3.eth.getBlock(web3.eth.blockNumber).timestamp + 1 // one second in the future
    // const endTime = startTime + (86400 * 20) // 20 days
    // const rate = new web3.BigNumber(1000)
    // const wallet = accounts[0]

    // deployer.deploy(TestSale, startTime, endTime, rate, wallet)
    const name = "Medical Token Currency"
    const symbol = "MTC"
    const initial_supply = 1000000000000000000000000
    const decimals = 15
    const wallet = "0x3dd201a65ad5120d8971b599fb6c7a287afb23c2"

    deployer.deploy(Token, name, symbol, initial_supply, decimals, wallet)
};