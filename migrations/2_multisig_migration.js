let MultiSigWallet = artifacts.require("MultiSigWallet");

function getNAccounts(accounts,n){
	let newAccounts = [];
	accounts.some((account) => {
		newAccounts.push(account);
		return newAccounts.length === n;
	});
	return newAccounts;
}

module.exports = function (deployer, network, accounts) {
	let multiSigOwners = getNAccounts(accounts,3);
	console.log("multiSigOwners");
	console.log(multiSigOwners);
	deployer.deploy(MultiSigWallet, multiSigOwners, 2, 3);
};