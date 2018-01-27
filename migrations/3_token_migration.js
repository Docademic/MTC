let MultiSigWallet = artifacts.require("MultiSigWallet");
let MTC = artifacts.require("Mtc");
let CrowdSale = artifacts.require("Crowdsale");

module.exports = function (deployer, network, accounts) {
	let multisig;
	MultiSigWallet.deployed().then((instance) => {
		multisig = instance;
		deployer.deploy(MTC, "Medical Token Currency", "MTC", 10 ** 24, 15, multisig.address).then(() => {
			deployer.deploy(CrowdSale,multisig.address,3500,Date.now()/1000,60,1200,MTC.address);
		});
	});
};