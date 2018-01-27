const async = require('async')
let MultiSigWallet = artifacts.require("MultiSigWallet");
let MTC = artifacts.require("MTC");
let CrowdSale = artifacts.require("CrowdSale");
let ShiftSale = artifacts.require("ShiftSale");

function getNAccounts(accounts,n){
	let newAccounts = [];
	accounts.some((account) => {
		newAccounts.push(account);
		return newAccounts.length === n;
	});
	return newAccounts;
}

module.exports = function (deployer, network, accounts) {
	
	
	let owners = getNAccounts(accounts,3);
	console.log("multiSigOwners");
	console.log(owners);
	async.waterfall([
		(cb)=> {
			deployer.deploy(MultiSigWallet, owners, 2, 3).then(() => {
				cb();
			});
		},
		(cb) => {
			deployer.deploy(MTC, "Medical Token Currency", "MTC", 10 ** 24, 15, MultiSigWallet.address).then(() => {
				cb();
			});
		},
		(cb) => {
			deployer.deploy(CrowdSale,MultiSigWallet.address,3500,Date.now()/1000,60,1200,MTC.address).then(() => {
				cb()
			});
		},
		(cb) => {
			deployer.deploy(ShiftSale,CrowdSale.address,MTC.address,owners, 10**15).then(() => {
				cb();
			})
		}
	],(err) => {
		console.log("END");
	})
	
};