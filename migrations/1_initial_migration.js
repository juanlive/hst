const HSToken = artifacts.require('./HSToken.sol')
const AddressSet = artifacts.require('./_testing/AddressSet/AddressSet.sol')
const IdentityRegistry = artifacts.require('./_testing/IdentityRegistry.sol')

const HydroToken = artifacts.require('./_testing/HydroToken.sol')

const SafeMath = artifacts.require('./zeppelin/math/SafeMath.sol')
const Ownable = artifacts.require('./zeppelin/math/Ownable.sol')
const Snowflake = artifacts.require('./Snowflake.sol')
// const Status = artifacts.require('./resolvers/Status.sol')

const StringUtils = artifacts.require('./resolvers/ClientRaindrop/StringUtils.sol')
const ClientRaindrop = artifacts.require('./resolvers/ClientRaindrop/ClientRaindrop.sol')
const OldClientRaindrop = artifacts.require('./_testing/OldClientRaindrop.sol')


module.exports = async function(deployer) {
	await deployer.deploy(AddressSet)
  deployer.link(AddressSet, IdentityRegistry)

  await deployer.deploy(SafeMath)
  deployer.link(SafeMath, HydroToken)
  deployer.link(SafeMath, Snowflake)


  await deployer.deploy(StringUtils)
  deployer.link(StringUtils, ClientRaindrop)
  deployer.link(StringUtils, OldClientRaindrop)

  await deployer.deploy(Ownable)


await deployer.deploy(HydroToken)
await deployer.deploy(IdentityRegistry)

console.log("SafeMath", SafeMath.address);
console.log("HydroToken",HydroToken.address);


const deployToken = async () => {
	await deployer.deploy(HSToken,
		1,
		"0xa7f15e4e66334e8214dfd97d5214f1f8f11c90f25bbe44b344944ed9efed7e29",
		"Hydro Security",
		"HTST",
		18,
		HydroToken.address, // HydroToken Rinkeby
		IdentityRegistry.address, // IdentityRegistry Rinkeby
		{gas: 6000000})

	console.log("HSToken",HSToken.address);
  	}

  	  deployer.link(SafeMath, HSToken)
  	  deployer.link(Ownable, HSToken)

};
