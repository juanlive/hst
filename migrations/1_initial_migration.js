const HSTIssuer = artifacts.require('./HSTIssuer.sol')
const AddressSet = artifacts.require('./_testing/AddressSet/AddressSet.sol')
const IdentityRegistry = artifacts.require('./_testing/IdentityRegistry.sol')

const HydroToken = artifacts.require('./_testing/HydroToken.sol')

const SafeMath = artifacts.require('./zeppelin/math/SafeMath.sol')
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
console.log("OK");
	await deployer.deploy(HSTIssuer,  {networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      websockets: true
    }}},
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
  	
};
