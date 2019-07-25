const truffleAssert = require('truffle-assertions')
const HSTokenRegistry = artifacts.require('./HSTokenRegistry.sol')
const HSTServiceRegistry = artifacts.require('./components/HSTServiceRegistry.sol')
const HSTRulesEnforcer = artifacts.require('./components/HSTRulesEnforcer.sol')

const common = require('./common.js')
const { createIdentity } = require('./utilities')

let instances
let user0
let user1
let ein0
let ein1

contract('Testing: HSTokenRegistry + HSTServiceRegistry + HSTRulesEnforcer', function (accounts) {
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
  user1 = users[1]


  it('common contracts deployed', async () => {
    instances = await common.initialize(owner.public, users);
  })


  it('Snowflake identities created for all accounts', async() => {
    for (let i = 0; i < users.length; i++) {
      await createIdentity(users[i], instances)
    }
  })


  describe('Checking HSTokenRegistry functionality - basic', async() => {

    it('HSTokenRegistry can be created', async () => {
      console.log("      Identity Registry Address", instances.IdentityRegistry.address);
      console.log("      User 0", user0.address);
      newTokenRegistry = await HSTokenRegistry.new(
          instances.IdentityRegistry.address,
          {from: user0.address}
      );
    })
    
    it('HSTokenRegistry exists', async () => {
      registryAddress = await newTokenRegistry.address;
      console.log("      Token Registry address", registryAddress);
    })
    
  })


  describe('Checking HSTServiceRegistry functionality - basic', async() => {

    it('HSTServiceRegistry can be created', async () => {
      newServiceRegistry = await HSTServiceRegistry.new(
          instances.IdentityRegistry.address,
          newTokenRegistry.address,
          {from: user0.address}
        )
        console.log("      HSTServiceRegistry Address", newServiceRegistry.address)
        console.log("      User 0", user0.address)
    })
  
    it('HSTServiceRegistry exists', async () => {
      _serviceRegistryAddress = await newServiceRegistry.address;
      console.log("      HSTServiceRegistry address", _serviceRegistryAddress)
    })
        
  })


  describe('Checking HSTRulesEnforcer functionality - basic', async() => {

    it('HSTRulesEnforcer can be created', async () => {
      newRulesEnforcer = await HSTRulesEnforcer.new(
          instances.DateTime.address,
          {from: user0.address}
        )
        console.log("      HSTRulesEnforcer Address", newRulesEnforcer.address)
        console.log("      User 0", user0.address)
    })
  
    it('HSTRulesEnforcer set registries addresses', async () => {
      await newRulesEnforcer.setAddresses(
        newTokenRegistry.address,
        newServiceRegistry.address,
        {from: user0.address}
      )
    })

    it('HSTServiceRegistry set default rules enforcer address', async () => {
      await newServiceRegistry.setDefaultRulesEnforcer(
        newRulesEnforcer.address,
        {from: user0.address}
      )
    })

    // TO DO
    // it('      HSTRulesEnforcer exists', async () => {
    //   _rulesOwner = await newRulesEnforcer.ownerEIN();
    //   console.log("      HSTRulesEnforcer owner", _rulesOwner)
    // })

  })


  describe('Checking HSTokenRegistry functionality - token creation', async() => {

    it('Set service registry address in token registry', async () => {
      await newTokenRegistry.setServiceRegistryAddress(newServiceRegistry.address),
      user0.address;
      console.log("      Service registry address was set");
    })

    it('Create token dummy address', async () => {
      tokenDummyAddress = '0xf58161d60b2133b1339563fc3e38a8e80410b08c';
      console.log("      Token dummy address", tokenDummyAddress);
    })

    it('Appoint a new token', async () => {
      result = await newTokenRegistry.appointToken(
        web3.utils.fromAscii('TestToken'),
        web3.utils.fromAscii('TEST'),
        tokenDummyAddress,
        'just-a-test',
        10,
        {from: user0.address}
      );
      //console.log("      Token was created", result);
    })

    it('Get token symbol', async () => {
      _tokenSymbol = await newTokenRegistry.getSecuritiesTokenSymbol(
        web3.utils.fromAscii('TestToken')
      );
      console.log("      Token symbol", web3.utils.toAscii(_tokenSymbol));
    })

    it('Get token address', async () => {
      _tokenAddress = await newTokenRegistry.getSecuritiesTokenAddress(
        web3.utils.fromAscii('TestToken')
      );
      console.log("      Token address", _tokenAddress);
    })

    it('Get token owner EIN', async () => {
      _tokenOwnerEIN = await newTokenRegistry.getSecuritiesTokenOwnerEIN(
        web3.utils.fromAscii('TestToken'),
      );
      console.log("      Token owner EIN", _tokenOwnerEIN);
    })

    it('Get token description', async () => {
      _tokenDescription = await newTokenRegistry.getSecuritiesTokenDescription(
        web3.utils.fromAscii('TestToken')
      );
      console.log("      Token description", _tokenDescription);
    })

    it('Get token decimals', async () => {
      _tokenDecimals = await newTokenRegistry.getSecuritiesTokenDecimals(
        web3.utils.fromAscii('TestToken')
      );
      console.log("      Token decimals", _tokenDecimals.toNumber());
    })

  })


  describe('Checking HSTServiceRegistry functionality - token categories creation', async() => {

    it('Token categories exist', async () => {
      _category1 = await newServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("MLA"));
      console.log("      MLA category", _category1);
      _category2 = await newServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("KYC"));
      console.log("      KYC category", _category2);
      _category3 = await newServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("AML"));
      console.log("      AML category", _category3);
      _category4 = await newServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("CFT"));
      console.log("      CFT category", _category4);
    })

  })


  describe('Checking HSTServiceRegistry functionality - additional', async() => {

    it('HSTServiceRegistry - add category', async () => {
      await newServiceRegistry.addCategory(
        tokenDummyAddress,
        web3.utils.fromAscii("TEST"),
        'just-a-test-category',
        {from: user0.address}
        )
    })
  
    it('HSTServiceRegistry - get category', async () => {
      _categoryDescription = await newServiceRegistry.getCategory(
        tokenDummyAddress,
        web3.utils.fromAscii("TEST"),
        {from: user0.address}
      )    
      console.log("      HSTServiceRegistry category description", _categoryDescription)
    })
    
    it('HSTServiceRegistry - add service', async () => {
      await newServiceRegistry.addService(
        tokenDummyAddress,
        19,
        web3.utils.fromAscii("TEST"),
        {from: user0.address}
        )
    })

    it('HSTServiceRegistry - get service', async () => {
      _serviceCategory = await newServiceRegistry.getService(
        tokenDummyAddress,
        19,
        {from: user0.address}
      )    
      console.log("      HSTServiceRegistry service category", web3.utils.toAscii(_serviceCategory))
    })

    it('HSTServiceRegistry - is provider true', async () => {
      await newServiceRegistry.isProvider(
        tokenDummyAddress,
        19,
        {from: user0.address}
      )    
    })

    it('HSTServiceRegistry - remove service', async () => {
      await newServiceRegistry.removeService(
        tokenDummyAddress,
        19,
        {from: user0.address}
      )    
    })

    it('HSTServiceRegistry - get service after removal', async () => {
      _serviceCategory = await newServiceRegistry.getService(
        tokenDummyAddress,
        19,
        {from: user0.address}
      )    
      console.log("      HSTServiceRegistry service category", web3.utils.toAscii(_serviceCategory))
    })

    it('HSTServiceRegistry - is provider false', async () => {
      await newServiceRegistry.isProvider(
        tokenDummyAddress,
        19,
        {from: user0.address}
      )    
    })
    
  })

  // TO DO review output values
  describe('Checking HSTRulesEnforcer functionality - token rules', async() => {

    it('HSTRulesEnforcer - assign token values', async () => {
      await newRulesEnforcer.assignTokenValues(
        tokenDummyAddress,
        '21',
        '50000',
        '5000',
        true,
        {from: user0.address}
      )
    })

    it('HSTRulesEnforcer - get token values - minimum age', async () => {
      _minimumAge = await newRulesEnforcer.getTokenMinimumAge(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTRulesEnforcer minimum age", _minimumAge.toNumber())
    })

    it('HSTRulesEnforcer - get token values - minimum net worth', async () => {
      _minimumNetWorth = await newRulesEnforcer.getTokenMinimumNetWorth(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTRulesEnforcer minimum net worth", _minimumNetWorth.toNumber())
    })
    
    it('HSTRulesEnforcer - get token values - minimum salary', async () => {
      _minimumSalary = await newRulesEnforcer.getTokenMinimumSalary(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTServiceRegistry minimum salary", _minimumSalary.toNumber())
    })
    
    it('HSTRulesEnforcer - get token values - investor status required', async () => {
      _investorStatus = await newRulesEnforcer.getTokenInvestorStatusRequired(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTServiceRegistry investor status required", _investorStatus)
    })

  })


  describe('Checking HSTRulesEnforcer functionality - country ban', async() => {

    it('HSTRulesEnforcer - ban country', async () => {
      await newRulesEnforcer.addCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
    })

    it('HSTRulesEnforcer - get country ban', async () => {
      _countryBanStatus = await newRulesEnforcer.getCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
      console.log("      HSTRulesEnforcer country ban status", _countryBanStatus)
    })

    it('HSTRulesEnforcer - lift country ban', async () => {
      await newRulesEnforcer.liftCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
    })

    it('HSTRulesEnforcer - get country ban', async () => {
      _countryBanStatus = await newRulesEnforcer.getCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
      console.log("      HSTRulesEnforcer country ban status", _countryBanStatus)
    })

  })


  describe('Checking HSTRulesEnforcer functionality - buyers', async() => {

    it('HSTRulesEnforcer - add buyer', async () => {
      await newRulesEnforcer.addBuyer(
        '21',
        'Test first name',
        'Test last name',
        web3.utils.fromAscii('GMB'),
        '1984',
        '12',
        '12',
        '100000',
        '5000',
        {from: user0.address}
      )
    })

    it('HSTRulesEnforcer - get buyer data - first name', async () => {
      _userFirstName = await newRulesEnforcer.getBuyerFirstName(
        '21',
        {from: user0.address}
      )
      console.log("      HSTRulesEnforcer get first name", _userFirstName)
    })

  })


})
