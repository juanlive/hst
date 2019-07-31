const ClientRaindrop = artifacts.require('./resolvers/ClientRaindrop/ClientRaindrop.sol')
const DateTime = artifacts.require('./components/DateTime.sol')
const HydroToken = artifacts.require('./_testing/HydroToken.sol')
const HSTBuyerRegistry = artifacts.require('./components/HSTBuyerRegistry.sol')
const HSTokenRegistry = artifacts.require('./components/HSTokenRegistry.sol')
const HSTServiceRegistry = artifacts.require('./components/HSTServiceRegistry.sol')
const IdentityRegistry = artifacts.require('./_testing/IdentityRegistry.sol')
const KYCResolver = artifacts.require('./samples/KYCResolver.sol')
const OldClientRaindrop = artifacts.require('./_testing/OldClientRaindrop.sol')
const Snowflake = artifacts.require('./Snowflake.sol')


async function initialize (owner, users) {
  const instances = {}

  instances.DateTime = await DateTime.new( { from: owner })
  console.log("    common - Date Time", instances.DateTime.address)

  instances.HydroToken = await HydroToken.new({ from: owner })
  console.log("    common - Hydro Token", instances.HydroToken.address)

  for (let i = 0; i < users.length; i++) {
    await instances.HydroToken.transfer(
      users[i].address,
      web3.utils.toBN(1000).mul(web3.utils.toBN(1e18)),
      { from: owner }
    )
  }

  instances.IdentityRegistry = await IdentityRegistry.new({ from: owner })
  console.log("    common - Identity Registry", instances.IdentityRegistry.address)

  instances.Snowflake = await Snowflake.new(
    instances.IdentityRegistry.address, instances.HydroToken.address, { from: owner }
  )
  console.log("    common - Snowflake", instances.Snowflake.address)

  instances.OldClientRaindrop = await OldClientRaindrop.new({ from: owner })
  console.log("    common - Old Client Raindrop", instances.OldClientRaindrop.address)

  instances.ClientRaindrop = await ClientRaindrop.new(
    instances.Snowflake.address, instances.OldClientRaindrop.address, 0, 0, { from: owner }
  )
  await instances.Snowflake.setClientRaindropAddress(
    instances.ClientRaindrop.address, { from: owner }
  )
  console.log("    common - Client Raindrop", instances.ClientRaindrop.address)

  instances.KYCResolver = await KYCResolver.new( {from: owner })
  console.log("    common - KYC Resolver", instances.KYCResolver.address)

  instances.BuyerRegistry = await HSTBuyerRegistry.new(
    instances.DateTime.address, { from: owner }
  )
  console.log("    common - Buyer Registry", instances.BuyerRegistry.address)

  instances.TokenRegistry = await HSTokenRegistry.new( { from: owner } )
  console.log("    common - Token Registry", instances.TokenRegistry.address)

  instances.ServiceRegistry = await HSTServiceRegistry.new(
    instances.IdentityRegistry.address, instances.TokenRegistry.address, { from: owner }
  )
  instances.TokenRegistry.setAddresses(
    instances.IdentityRegistry.address,
    instances.ServiceRegistry.address,
    { from: owner }
  )
  console.log("    common - Service Registry", instances.ServiceRegistry.address)
  
  await instances.BuyerRegistry.setAddresses(
    instances.IdentityRegistry.address,
    instances.TokenRegistry.address,
    instances.ServiceRegistry.address,
    { from: owner }
  )

  console.log("    common - finishing and returning instances")

  return instances
}


module.exports = {
  initialize: initialize
}
