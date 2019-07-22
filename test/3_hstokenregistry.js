return;
const truffleAssert = require('truffle-assertions')
const HSTokenRegistry = artifacts.require('./HSTokenRegistry.sol')

const common = require('./common.js')
const { createIdentity } = require('./utilities')

let instances
let user

contract('Testing HSTokenRegistry', function (accounts) {
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
    instances = await common.initialize(owner.public, users);
  })


  it('Snowflake identities created for all accounts', async() => {
    for (let i = 0; i < users.length; i++) {
      await createIdentity(users[i], instances)
    }
  })


  describe('Checking HSTokenRegistry functionality', async() =>{

    it('HSTokenRegistry can be created', async () => {
      console.log("      Identity Registry Address", instances.IdentityRegistry.address);
      console.log("      User", user.address);
      newTokenRegistry = await HSTokenRegistry.new(
          instances.IdentityRegistry.address,
          {from: user.address}
      );
    })
    
    it('HSTokenRegistry exists', async () => {
      registryAddress = await newTokenRegistry.address;
      console.log("      Token Registry address", registryAddress);
    })

    it('Create token dummy address', async () => {
      tokenDummyAddress = instances.IdentityRegistry.address;
      console.log("      Token dummy address", tokenDummyAddress);
    })

    it('Appoint a new token', async () => {
      result = await newTokenRegistry.appointToken(
        web3.utils.fromAscii('TestToken'),
        web3.utils.fromAscii('TEST'),
        tokenDummyAddress,
        'just a test',
        10,
        {from: user.address}
      );
      //console.log("      Token was created", result);
    })

    // it('Get token symbol', async () => {
    //   tokenSymbol = await web3.utils.toAscii(
    //     newTokenRegistry.getSecuritiesTokenSymbol(
    //       tokenDummyAddress,
    //       {from: user.address}
    //     )
    //   );
    //   console.log("      Token symbol", tokenSymbol);
    // })

    it('Get token symbol', async () => {
      tokenSymbol = await newTokenRegistry.getSecuritiesTokenSymbol(
        tokenDummyAddress,
        {from: user.address}
      );
      console.log("      Token symbol", tokenSymbol);
    })

  })

})
