const truffleAssert = require('truffle-assertions')
const IdentityRegistry = artifacts.require('./components/IdentityRegistry.sol')
const SnowflakeOwnable = artifacts.require('./components/SnowflakeOwnable.sol')

const common = require('./common.js')
const { sign, verifyIdentity, daysOn, daysToSeconds, createIdentity } = require('./utilities')

let instances
let newSnowflakeOwnable
let user0
let user1
let ein0
let ein1
let ownerEIN

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

  user0 = users[0]

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
    //     console.log('IdentityRegistry Address', newIdentityRegistry.address)
    //     console.log('User', user0.address)
    // })


    // Try to create duplicate identity
    it('IdentityRegistry create Identity (exists, should revert)', async () => {
      await truffleAssert.reverts(
        instances.IdentityRegistry.createIdentity(
          user0.address,
          accounts,
          accounts,
          {from: user0.address}),
          'The passed address has an identity but should not..'
      )
    })

    // Retrieve EIN for an Identity from IdentityRegistry
    it('IdentityRegistry retrieve EIN', async () => {
      ein0 = await instances.IdentityRegistry.getEIN(
        user0.address,
        {from: user0.address}
      )
      console.log('      EIN user[0]', ein0)
    })

  })


  describe('Checking SnowflakeOwnable functionality', async() =>{

    // Create SnowflakeOwnable contract
    it('SnowflakeOwnable can be created', async () => {
      newSnowflakeOwnable = await SnowflakeOwnable.new(
        //instances.IdentityRegistry.address,
        {from: user0.address}
      )
        console.log('      SnowflakeOwnable Address', newSnowflakeOwnable.address)
        console.log('      user[0]', user0.address)
    })

    it('SnowflakeOwnable exists', async () => {
      ownerEIN = await newSnowflakeOwnable.ownerEIN({from: user0.address})
      console.log('      Owner EIN', ownerEIN)
    })

    it('SnowflakeOwnable set Identity Registry', async () => {
      console.log('      Identity Registry Address', instances.IdentityRegistry.address)
      await newSnowflakeOwnable.setIdentityRegistryAddress(
        instances.IdentityRegistry.address,
        {from: user0.address}
      )
    })

    it('SnowflakeOwnable get Identity Registry Address', async () => {
      _snowIDaddress = await newSnowflakeOwnable.getIdentityRegistryAddress(
        {from: user0.address}
      )
      console.log('      snowflake ownable identity registry address', _snowIDaddress)
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable owner EIN', ownerEIN)
    })

    // Try to transfer ownership to an identity which does not exist
    // owner is users[0]
    it('Snowflake ownable transfer ownership (no identity, should revert)', async () => {
      await truffleAssert.reverts(
        newSnowflakeOwnable.setOwnerEIN(
          9,
          {from: user0.address}),
          'New owner identity must exist'
      )
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable new owner EIN after transfer 1', ownerEIN)
    })

    // Try to transfer ownership without being the owner
    // owner is users[0]
    it('Snowflake ownable transfer ownership (not the owner, should revert)', async () => {
      user1 = users[1]
      ein1 = await instances.IdentityRegistry.getEIN(
        user1.address,
        {from: user1.address}
      )
      console.log('      EIN users[1]', ein1)
      await truffleAssert.reverts(
        newSnowflakeOwnable.setOwnerEIN(
          ein1,
          {from: user1.address}),
          'Must be the EIN owner to call this function'
      )
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable new owner EIN after transfer 2', ownerEIN)
    })

    // Transfer ownership being the owner
    // owner is users[0]
    it('Snowflake ownable transfer ownership', async () => {
      await newSnowflakeOwnable.setOwnerEIN(
        ein1,
        {from: user0.address}
      )
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable new owner EIN after transfer 3', ownerEIN)
    })

  })

})
=======
return;
const truffleAssert = require('truffle-assertions')
const IdentityRegistry = artifacts.require('./components/IdentityRegistry.sol')
const SnowflakeOwnable = artifacts.require('./components/SnowflakeOwnable.sol')

const common = require('./common.js')
const { sign, verifyIdentity, daysOn, daysToSeconds, createIdentity } = require('./utilities')

let instances
let newSnowflakeOwnable
let user0
let user1
let ein0
let ein1
let ownerEIN

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

  user0 = users[0]

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
    //     console.log('IdentityRegistry Address', newIdentityRegistry.address)
    //     console.log('User', user0.address)
    // })


    // Try to create duplicate identity
    it('IdentityRegistry create Identity (exists, should revert)', async () => {
      await truffleAssert.reverts(
        instances.IdentityRegistry.createIdentity(
          user0.address,
          accounts,
          accounts,
          {from: user0.address}),
          'The passed address has an identity but should not..'
      )
    })

    // Retrieve EIN for an Identity from IdentityRegistry
    it('IdentityRegistry retrieve EIN', async () => {
      ein0 = await instances.IdentityRegistry.getEIN(
        user0.address,
        {from: user0.address}
      )
      console.log('      EIN user[0]', ein0)
    })

  })


  describe('Checking SnowflakeOwnable functionality', async() =>{

    // Create SnowflakeOwnable contract
    it('SnowflakeOwnable can be created', async () => {
      newSnowflakeOwnable = await SnowflakeOwnable.new(
        //instances.IdentityRegistry.address,
        {from: user0.address}
      )
        console.log('      SnowflakeOwnable Address', newSnowflakeOwnable.address)
        console.log('      user[0]', user0.address)
    })

    it('SnowflakeOwnable exists', async () => {
      ownerEIN = await newSnowflakeOwnable.ownerEIN({from: user0.address})
      console.log('      Owner EIN', ownerEIN)
    })

    it('SnowflakeOwnable set Identity Registry', async () => {
      console.log('      Identity Registry Address', instances.IdentityRegistry.address)
      await newSnowflakeOwnable.setIdentityRegistryAddress(
        instances.IdentityRegistry.address,
        {from: user0.address}
      )
    })

    it('SnowflakeOwnable get Identity Registry Address', async () => {
      _snowIDaddress = await newSnowflakeOwnable.getIdentityRegistryAddress(
        {from: user0.address}
      )
      console.log('      snowflake ownable identity registry address', _snowIDaddress)
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable owner EIN', ownerEIN)
    })

    // Try to transfer ownership to an identity which does not exist
    // owner is users[0]
    it('Snowflake ownable transfer ownership (no identity, should revert)', async () => {
      await truffleAssert.reverts(
        newSnowflakeOwnable.setOwnerEIN(
          9,
          {from: user0.address}),
          'New owner identity must exist'
      )
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable new owner EIN after transfer 1', ownerEIN)
    })

    // Try to transfer ownership without being the owner
    // owner is users[0]
    it('Snowflake ownable transfer ownership (not the owner, should revert)', async () => {
      user1 = users[1]
      ein1 = await instances.IdentityRegistry.getEIN(
        user1.address,
        {from: user1.address}
      )
      console.log('      EIN users[1]', ein1)
      await truffleAssert.reverts(
        newSnowflakeOwnable.setOwnerEIN(
          ein1,
          {from: user1.address}),
          'Must be the EIN owner to call this function'
      )
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable new owner EIN after transfer 2', ownerEIN)
    })

    // Transfer ownership being the owner
    // owner is users[0]
    it('Snowflake ownable transfer ownership', async () => {
      await newSnowflakeOwnable.setOwnerEIN(
        ein1,
        {from: user0.address}
      )
    })

    it('SnowflakeOwnable get owner EIN', async () => {
      ownerEIN = await newSnowflakeOwnable.getOwnerEIN(
        {from: user0.address}
      )
      console.log('      snowflake ownable new owner EIN after transfer 3', ownerEIN)
    })

  })

})

