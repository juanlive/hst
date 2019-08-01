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


async function createUsers (accounts) {
  const users = [
    // system owner
    {
      hydroID: 'own',
      address: accounts[0],
      recoveryAddress: accounts[0],
      private: '0x2665671af93f210ddb5d5ffa16c77fcf961d52796f2b2d7afd32cc5d886350a8',
      id: 1
    },
    // token owner
    {
      hydroID: 'fir',
      address: accounts[1],
      recoveryAddress: accounts[1],
      private: '0x6bf410ff825d07346c110c5836b33ec76e7d1ee051283937392180b732aa3aff',
      id: 2
    },
    // kyc service provider
    {
      hydroID: 'sec',
      address: accounts[2],
      recoveryAddress: accounts[2],
      private: '0xccc3c84f02b038a5d60d93977ab11eb57005f368b5f62dad29486edeb4566954',
      id: 3
    },
    // general users
    {
      hydroID: 'thi',
      address: accounts[3],
      recoveryAddress: accounts[3],
      private: '0xfdf12368f9e0735dc01da9db58b1387236120359024024a31e611e82c8853d7f',
      id: 4
    },
    {
      hydroID: 'fou',
      address: accounts[4],
      recoveryAddress: accounts[4],
      private: '0x44e02845db8861094c519d72d08acb7435c37c57e64ec5860fb15c5f626cb77c',
      id: 5
    },
    {
      hydroID: 'fif',
      address: accounts[5],
      recoveryAddress: accounts[5],
      private: '0x12093c3cd8e0c6ceb7b1b397724cd82c4d84f81263f56a44f11d8bd3a61ffccb',
      id: 6
    },
    {
      hydroID: 'six',
      address: accounts[6],
      recoveryAddress: accounts[6],
      private: '0xf65450adda73b32e056ed24246d8d370e49fc88b427f96f37bbf23f6b132b93b',
      id: 7
    },
    {
      hydroID: 'sev',
      address: accounts[7],
      recoveryAddress: accounts[7],
      private: '0x34a1f9ed996709f629d712d5b267d23f37be82bf8003a023264f71005f6486e6',
      id: 8
    },
    {
      hydroID: 'eig',
      address: accounts[8],
      recoveryAddress: accounts[8],
      private: '0x1711e5c516428d875c14dac234f36bbf3b4622aeac00566483a8087ed5a97297',
      id: 9
    },
    {
      hydroID: 'nin',
      address: accounts[9],
      recoveryAddress: accounts[9],
      private: '0xce5e2ea9c47caba88b3421d75023bd8c359e2aaf897e519a10a256d931028ca1',
      id: 10
    }
  ]
  return users;
}


async function initialize (ownerAddress, users) {

  const instances = {}

  instances.DateTime = await DateTime.new( { from: ownerAddress })
  console.log("    common - Date Time", instances.DateTime.address)

  instances.HydroToken = await HydroToken.new({ from: ownerAddress })
  console.log("    common - Hydro Token", instances.HydroToken.address)

  for (let i = 0; i < users.length; i++) {
    await instances.HydroToken.transfer(
      users[i].address,
      web3.utils.toBN(1000).mul(web3.utils.toBN(1e18)),
      { from: ownerAddress }
    )
  }

  instances.IdentityRegistry = await IdentityRegistry.new({ from: ownerAddress })
  console.log("    common - Identity Registry", instances.IdentityRegistry.address)

  instances.Snowflake = await Snowflake.new(
    instances.IdentityRegistry.address, instances.HydroToken.address, { from: ownerAddress }
  )
  console.log("    common - Snowflake", instances.Snowflake.address)

  instances.OldClientRaindrop = await OldClientRaindrop.new({ from: ownerAddress })
  console.log("    common - Old Client Raindrop", instances.OldClientRaindrop.address)

  instances.ClientRaindrop = await ClientRaindrop.new(
    instances.Snowflake.address, instances.OldClientRaindrop.address, 0, 0, { from: ownerAddress }
  )
  await instances.Snowflake.setClientRaindropAddress(
    instances.ClientRaindrop.address, { from: ownerAddress }
  )
  console.log("    common - Client Raindrop", instances.ClientRaindrop.address)

  instances.KYCResolver = await KYCResolver.new( {from: ownerAddress })
  console.log("    common - KYC Resolver", instances.KYCResolver.address)

  instances.BuyerRegistry = await HSTBuyerRegistry.new(
    instances.DateTime.address, { from: ownerAddress }
  )
  console.log("    common - Buyer Registry", instances.BuyerRegistry.address)

  instances.TokenRegistry = await HSTokenRegistry.new( { from: ownerAddress } )
  console.log("    common - Token Registry", instances.TokenRegistry.address)

  instances.ServiceRegistry = await HSTServiceRegistry.new( { from: ownerAddress } )
  console.log("    common - Service Registry", instances.ServiceRegistry.address)


  await instances.ServiceRegistry.setAddresses(
    instances.IdentityRegistry.address,
    instances.TokenRegistry.address,
    { from: ownerAddress }
  )
  // await instances.ServiceRegistry.setIdentityRegistryAddress(
  //   instances.IdentityRegistry.address,
  //   { from: ownerAddress }
  // )

  await instances.TokenRegistry.setAddresses(
    instances.IdentityRegistry.address,
    instances.ServiceRegistry.address,
    { from: ownerAddress }
  )
  // await instances.TokenRegistry.setIdentityRegistryAddress(
  //   instances.IdentityRegistry.address,
  //   { from: ownerAddress }
  // )
  
  await instances.BuyerRegistry.setAddresses(
    instances.IdentityRegistry.address,
    instances.TokenRegistry.address,
    instances.ServiceRegistry.address,
    { from: ownerAddress }
  )
  // await instances.BuyerRegistry.setIdentityRegistryAddress(
  //   instances.IdentityRegistry.address,
  //   { from: ownerAddress }
  // )

  console.log("    common - finishing and returning instances")

  return instances
}


module.exports = {
  createUsers: createUsers,
  initialize: initialize
}
