const truffleAssert = require('truffle-assertions')
const IdentityRegistry = artifacts.require('./components/IdentityRegistry.sol')
const SnowflakeOwnable = artifacts.require('./components/SnowflakeOwnable.sol')

const common = require('./common.js')
const { sign, verifyIdentity, daysOn, daysToSeconds, createIdentity } = require('./utilities')

let instances
let user
contract('Testing SnowflakeOwnable', function (accounts) {
  const owner = {
    public: accounts[0]
  }

  const users = [
    {
      hydroID: 'abc',
      address: accounts[1],
      recoveryAddress: accounts[1],
      private: '0x6bf410ff825d07346c110c5836b33ec76e7d1ee051283937392180b732aa3aff',
      id: 1
    },
    {
      hydroID: 'thr',
      address: accounts[3],
      recoveryAddress: accounts[3],
      private: '0xfdf12368f9e0735dc01da9db58b1387236120359024024a31e611e82c8853d7f',
      id: 2
    },
        {
      hydroID: 'for',
      address: accounts[4],
      recoveryAddress: accounts[4],
      private: '0x44e02845db8861094c519d72d08acb7435c37c57e64ec5860fb15c5f626cb77c',
      id: 3
    }
  ]

  user = users[0]

  it('common contracts deployed', async () => {
    instances = await common.initialize(owner.public, users)
  })

  it('Snowflake identities created for all accounts', async() => {
  for (let i = 0; i < users.length; i++) {
    await createIdentity(users[i], instances)
  }
})


describe('Checking IdentityRegistry functionality', async() =>{

  // Create IdentityRegistry contract
  // it('IdentityRegistry can be created', async () => {
  //   newIdentityRegistry = await IdentityRegistry.new()
  //     console.log("IdentityRegistry Address", newIdentityRegistry.address)
  //     console.log("User", user.address)
  // })


  // crear un test con revert
  it('IdentityRegistry create Identity (exists, should revert)', async () => {
    await truffleAssert.reverts(
      instances.IdentityRegistry.createIdentity(
        user.address,
        accounts,
        accounts,
        {from: user.address}),
        "The passed address has an identity but should not.."
    )
  })

  // Retrieve EIN for an Identity from IdentityRegistry
  it('IdentityRegistry retrieve EIN', async () => {
    await instances.IdentityRegistry.getEIN(
      user.address,
      {from: user.address}
    )
  })

})


describe('Checking SnowflakeOwnable functionality', async() =>{

  // Create SnowflakeOwnable contract
  it('SnowflakeOwnable can be created', async () => {
    newSnowflakeOwnable = await SnowflakeOwnable.new(
      //instances.IdentityRegistry.address,
      {from: user.address}
    )
      console.log("SnowflakeOwnable Address", newSnowflakeOwnable.address)
      console.log("User", user.address)
  })

  it('SnowflakeOwnable exists', async () => {
    userId = await newSnowflakeOwnable.ownerEIN({from: user.address})
    console.log("Owner EIN", userId)
    console.log("Owner address", newSnowflakeOwnable.owner())
  })

  it('SnowflakeOwnable set Identity Registry', async () => {
    console.log("Identity Registry Address", instances.IdentityRegistry.address)
    await newSnowflakeOwnable.setIdentityRegistryAddress(
      instances.IdentityRegistry.address,
      {from: user.address}
    )
  })

  it('SnowflakeOwnable get owner EIN', async () => {
    await newSnowflakeOwnable.getOwnerEIN(
      {from: user.address}
    )
  })




})

})
