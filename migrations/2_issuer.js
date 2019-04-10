console.log(accounts)
const HSTIssuer = artifacts.require('./HSTIssuer.sol')


module.exports = async function(deployer) {
	console.log(accounts);
	console.log("1");

	await deployer.deploy(HSTIssuer,
		1,
		"Hydro Test ST",
		"Hydro Security token for testing purposes",
		"HTST",
		18,
		10000000000,
		10000000000000000,
		new Date(),
		new Date() + 10 * 24 * 60 * 60 * 1000,
		new Date() + 100 * 24 * 60 * 60 * 1000,
		10000000 * 10**18,
		new Date() + 5 * 24 * 60 * 60 * 1000,

		true,
		false,
		false,
		false,
		true,
		true,
		true,
		true,
		false,
		false,

		0,
		10000000000000,
		10000000000,
		14 * 24 * 60 * 60 * 1000,
		5,
		20)
  	console.log("2");
};
