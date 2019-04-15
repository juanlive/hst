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
  	

  	  deployer.link(SafeMath, HSToken)
  	  deployer.link(Ownable, HSToken)

};
