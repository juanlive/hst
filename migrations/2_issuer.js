console.log(accounts)
const HSTIssuer = artifacts.require('./HSTIssuer.sol')


module.exports = async function(deployer) {
	console.log(accounts);
	console.log("1");

	await deployer.deploy(HSTIssuer,
		1,
		0x0123346,
		"Hydro Security token for testing purposes",
		"HTST",
		18)
  	console.log("2");
};
