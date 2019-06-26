const truffleAssert = require('truffle-assertions')
const RulesEnforcer = artifacts.require('./components/RulesEnforcer.sol')
const ServiceRegistry = artifacts.require('./HSTServiceRegistry.sol')

const common = require('./common.js')
const { sign, verifyIdentity, daysOn, daysToSeconds, createIdentity } = require('./utilities')

let instances
let user
contract('Testing RulesEnforcer and HSTServiceRegistry', function (accounts) {
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


describe('Checking RulesEnforcer functionality', async() =>{


  it('RulesEnforcer can be created', async () => {
    newRulesEnforcer = await RulesEnforcer.new(
        instances.DateTime.address,
        {from: user.address}
      )
      console.log("RulesEnforcer Address", newRulesEnforcer.address)
      console.log("User", user.address)
  })

  it('RulesEnforcer exists', async () => {
    userId = await newRulesEnforcer.ownerEIN();
  })


})


describe('Checking HSTServiceRegistry functionality', async() =>{


  it('HSTServiceRegistry can be created', async () => {
    newServiceRegistry = await ServiceRegistry.new(
        newRulesEnforcer.address,
        instances.IdentityRegistry.address,
        {from: user.address}
      )
      console.log("HSTServiceRegistry Address", newServiceRegistry.address)
      console.log("User", user.address)
  })

  it('HSTServiceRegistry exists', async () => {
    userId = await newServiceRegistry.ownerEIN();
  })


})


})
