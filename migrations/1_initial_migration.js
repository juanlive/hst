const HSTIssuer = artifacts.require('./HSTIssuer.sol')

module.exports = function(deployer) {
	await deployer.deploy(HSTIssuer)
  	
};
