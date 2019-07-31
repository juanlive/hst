const truffleAssert = require('truffle-assertions')
//const HSTServiceRegistry = artifacts.require('./components/HSTServiceRegistry.sol')
//const HSTBuyerRegistry = artifacts.require('./components/HSTBuyerRegistry.sol')
//const HSTokenRegistry = artifacts.require('./components/HSTokenRegistry.sol')
//const IdentityRegistry = artifacts.require('./components/IdentityRegistry.sol')

const common = require('./common.js')
const { createIdentity } = require('./utilities')

let instances

// system owner
let user0
let ein0

// token owner
let user1
let ein1

// kyc/aml/cft provider
let user2
let ein2


contract('Testing: HSTokenRegistry + HSTServiceRegistry + HSTBuyerRegistry', function (accounts) {

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
  user2 = users[2]


  describe('Preparing infrastructure', async() => {

    it('Common contracts deployed', async () => {
      instances = await common.initialize(owner.public, users);
    })

    it('Snowflake identities created for all accounts', async() => {
      for (let i = 0; i < users.length; i++) {
        await createIdentity(users[i], instances);
      }
    })

    // Retrieve EINs for all Identities from IdentityRegistry

    it('IdentityRegistry retrieve EIN - first', async () => {
      ein0 = await instances.IdentityRegistry.getEIN(
        user0.address,
        {from: user0.address}
      )
      console.log("      User 0 => EIN 0 => value 1", ein0);
    })

    it('IdentityRegistry retrieve EIN - second', async () => {
      ein1 = await instances.IdentityRegistry.getEIN(
        user1.address,
        {from: user1.address}
      )
      console.log("      User 1 => EIN 1 => value 2", ein1);
    })

    it('IdentityRegistry retrieve EIN - third', async () => {
      ein2 = await instances.IdentityRegistry.getEIN(
        user2.address,
        {from: user2.address}
      )
      console.log("      User 2 => EIN 2 => value 3", ein2);
    })

  })


  describe('Checking HSTokenRegistry functionality - basic', async() => {

    // it('HSTokenRegistry can be created', async () => {
    //   console.log("      Identity Registry Address", instances.IdentityRegistry.address);
    //   console.log("      User 0", user0.address);
    //   newTokenRegistry = await HSTokenRegistry.new( {from: user0.address} );
    // })
    
    it('HSTokenRegistry exists', async () => {
      registryAddress = await instances.TokenRegistry.address;
      console.log("      Token Registry address", registryAddress);
    })

  })


  describe('Checking HSTServiceRegistry functionality - basic', async() => {

    // it('HSTServiceRegistry can be created', async () => {
    //   newServiceRegistry = await HSTServiceRegistry.new(
    //       instances.IdentityRegistry.address,
    //       instances.TokenRegistry.address,
    //       {from: user0.address}
    //     )
    //     console.log("      HSTServiceRegistry Address", newServiceRegistry.address)
    //     console.log("      User 0", user0.address)
    // })
  
    it('HSTServiceRegistry exists', async () => {
      _serviceRegistryAddress = await instances.ServiceRegistry.address;
      console.log("      HSTServiceRegistry address", _serviceRegistryAddress)
    })

    it('HSTokenRegistry set addresses', async () => {
      console.log('      Service Registry Address', instances.ServiceRegistry.address)
      await instances.TokenRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.ServiceRegistry.address,
        {from: user0.address}
      )
    })

  })


  describe('Checking HSTBuyerRegistry functionality - basic', async() => {

    // it('HSTBuyerRegistry can be created', async () => {
    //   newBuyerRegistry = await HSTBuyerRegistry.new(
    //       instances.DateTime.address,
    //       {from: user0.address}
    //     )
    //     console.log("      HSTBuyerRegistry Address", newBuyerRegistry.address)
    //     console.log("      User 0", user0.address)
    // })
  
    it('HSTBuyerRegistry set registries addresses', async () => {
      await instances.BuyerRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.TokenRegistry.address,
        instances.ServiceRegistry.address,
        {from: user0.address}
      )
    })

    it('HSTServiceRegistry set registries addresses', async () => {
      await instances.ServiceRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.TokenRegistry.address,
        {from: user0.address}
      )
    })

    // TO DO
    // it('      HSTBuyerRegistry exists', async () => {
    //   _rulesOwner = await newBuyerRegistry.ownerEIN();
    //   console.log("      HSTBuyerRegistry owner", _rulesOwner)
    // })

  })


  describe('Checking HSTokenRegistry functionality - token creation', async() => {

    it('Set service registry address in token registry', async () => {
      await instances.TokenRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.ServiceRegistry.address,
        {from: user0.address}
      );
      console.log("      Service registry address was set");
    })

    it('Create token dummy address', async () => {
      tokenDummyAddress = '0xf58161d60b2133b1339563fc3e38a8e80410b08c';
      console.log("      Token dummy address", tokenDummyAddress);
    })

    it('Appoint a new token', async () => {
      await instances.TokenRegistry.appointToken(
        tokenDummyAddress,
        web3.utils.fromAscii('TEST'),
        web3.utils.fromAscii('TestToken'),
        'just-a-test',
        10,
        {from: user1.address}
      );
      //console.log("      Token was created", result);
    })

    it('Get token owner EIN', async () => {
      _tokenOwnerEIN = await instances.TokenRegistry.getSecuritiesTokenOwnerEIN(
        tokenDummyAddress
      );
      console.log("      Token owner EIN", _tokenOwnerEIN.toNumber());
    })

    it('Get token symbol', async () => {
      _tokenSymbol = await instances.TokenRegistry.getSecuritiesTokenSymbol(
        tokenDummyAddress
      );
      console.log("      Token symbol", web3.utils.toAscii(_tokenSymbol));
    })

    it('Get token name', async () => {
      _tokenName = await instances.TokenRegistry.getSecuritiesTokenName(
        tokenDummyAddress
      );
      console.log("      Token address", web3.utils.toAscii(_tokenName));
    })

    it('Get token description', async () => {
      _tokenDescription = await instances.TokenRegistry.getSecuritiesTokenDescription(
        tokenDummyAddress
      );
      console.log("      Token description", _tokenDescription);
    })

    it('Get token decimals', async () => {
      _tokenDecimals = await instances.TokenRegistry.getSecuritiesTokenDecimals(
        tokenDummyAddress
      );
      console.log("      Token decimals", _tokenDecimals.toNumber());
    })

  })


  describe('Checking HSTServiceRegistry functionality - token categories creation', async() => {

    it('Token categories exist', async () => {
      _category1 = await instances.ServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("MLA"));
      console.log("      MLA category", _category1);
      _category2 = await instances.ServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("KYC"));
      console.log("      KYC category", _category2);
      _category3 = await instances.ServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("AML"));
      console.log("      AML category", _category3);
      _category4 = await instances.ServiceRegistry.getCategory(tokenDummyAddress, web3.utils.fromAscii("CFT"));
      console.log("      CFT category", _category4);
    })

  })


  describe('Checking HSTServiceRegistry functionality - additional', async() => {

    it('HSTServiceRegistry - add category', async () => {
      await instances.ServiceRegistry.addCategory(
        tokenDummyAddress,
        web3.utils.fromAscii("TEST"),
        'just-a-test-category',
        {from: user1.address}
      )
    })
  
    it('HSTServiceRegistry - get category', async () => {
      _categoryDescription = await instances.ServiceRegistry.getCategory(
        tokenDummyAddress,
        web3.utils.fromAscii("TEST"),
        {from: user0.address}
      )    
      console.log("      HSTServiceRegistry category description", _categoryDescription)
    })
    
    it('HSTServiceRegistry - add service', async () => {
      await instances.ServiceRegistry.addService(
        tokenDummyAddress,
        '3',
        web3.utils.fromAscii("KYC"),
        {from: user1.address}
        )
    })

    it('HSTServiceRegistry - get service', async () => {
      _serviceCategory = await instances.ServiceRegistry.getService(
        tokenDummyAddress,
        '3',
        {from: user0.address}
      )    
      console.log("      HSTServiceRegistry service category", web3.utils.toAscii(_serviceCategory))
    })

    it('HSTServiceRegistry - is provider true', async () => {
      await instances.ServiceRegistry.isProvider(
        tokenDummyAddress,
        '3',
        {from: user0.address}
      )    
    })

    it('HSTServiceRegistry - remove service', async () => {
      await instances.ServiceRegistry.removeService(
        tokenDummyAddress,
        '3',
        {from: user1.address}
      )    
    })

    it('HSTServiceRegistry - get service after removal', async () => {
      _serviceCategory = await instances.ServiceRegistry.getService(
        tokenDummyAddress,
        '3',
        {from: user0.address}
      )    
      console.log("      HSTServiceRegistry service category", web3.utils.toAscii(_serviceCategory))
    })

    it('HSTServiceRegistry - is provider false', async () => {
      await instances.ServiceRegistry.isProvider(
        tokenDummyAddress,
        '3',
        {from: user0.address}
      )    
    })
    
  })

  // TO DO review output values
  describe('Checking HSTBuyerRegistry functionality - token rules', async() => {

    it('HSTBuyerRegistry - assign token values', async () => {
      await instances.BuyerRegistry.assignTokenValues(
        tokenDummyAddress,
        '21',
        '50000',
        '5000',
        true,
        {from: user0.address}
      )
    })

    it('HSTBuyerRegistry - get token values - minimum age', async () => {
      _minimumAge = await instances.BuyerRegistry.getTokenMinimumAge(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry minimum age", _minimumAge.toNumber())
    })

    it('HSTBuyerRegistry - get token values - minimum net worth', async () => {
      _minimumNetWorth = await instances.BuyerRegistry.getTokenMinimumNetWorth(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry minimum net worth", _minimumNetWorth.toNumber())
    })
    
    it('HSTBuyerRegistry - get token values - minimum salary', async () => {
      _minimumSalary = await instances.BuyerRegistry.getTokenMinimumSalary(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTServiceRegistry minimum salary", _minimumSalary.toNumber())
    })
    
    it('HSTBuyerRegistry - get token values - investor status required', async () => {
      _investorStatus = await instances.BuyerRegistry.getTokenInvestorStatusRequired(
        tokenDummyAddress,
        {from: user0.address}
      )
      console.log("      HSTServiceRegistry investor status required", _investorStatus)
    })

  })


  describe('Checking HSTBuyerRegistry functionality - country ban', async() => {

    it('HSTBuyerRegistry - ban country', async () => {
      await instances.BuyerRegistry.addCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
    })

    it('HSTBuyerRegistry - get country ban', async () => {
      _countryBanStatus = await instances.BuyerRegistry.getCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry country ban status", _countryBanStatus)
    })

    it('HSTBuyerRegistry - lift country ban', async () => {
      await instances.BuyerRegistry.liftCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
    })

    it('HSTBuyerRegistry - get country ban', async () => {
      _countryBanStatus = await instances.BuyerRegistry.getCountryBan(
        tokenDummyAddress,
        web3.utils.fromAscii('GMB'),
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry country ban status", _countryBanStatus)
    })

  })


  describe('Checking HSTBuyerRegistry functionality - buyer data', async() => {

    it('HSTBuyerRegistry - add buyer', async () => {
      await instances.BuyerRegistry.addBuyer(
        '21',
        'Test first name',
        'Test last name',
        web3.utils.fromAscii('GMB'),
        '1984',
        '12',
        '12',
        '100000',
        '50000',
        {from: user0.address}
      )
    })

    it('HSTBuyerRegistry - get buyer data - first name', async () => {
      _buyerFirstName = await instances.BuyerRegistry.getBuyerFirstName(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get first name", _buyerFirstName)
    })

    it('HSTBuyerRegistry - get buyer data - last name', async () => {
      _buyerLastName = await instances.BuyerRegistry.getBuyerLastName(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get last name", _buyerLastName)
    })

    it('HSTBuyerRegistry - get buyer data - iso country code', async () => {
      _buyerCountryCode = await instances.BuyerRegistry.getBuyerIsoCountryCode(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get country code", web3.utils.toAscii(_buyerCountryCode))
    })

    it('HSTBuyerRegistry - get buyer data - birthday', async () => {
      _buyerBirthday = await instances.BuyerRegistry.getBuyerBirthTimestamp(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get birthday", _buyerBirthday.toNumber())
    })

    it('HSTBuyerRegistry - get buyer data - net worth', async () => {
      _buyerNetWorth = await instances.BuyerRegistry.getBuyerNetWorth(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get net worth", _buyerNetWorth.toNumber())
    })

    it('HSTBuyerRegistry - get buyer data - salary', async () => {
      _buyerSalary = await instances.BuyerRegistry.getBuyerSalary(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get salary", _buyerSalary.toNumber()) 
    })

    it('HSTBuyerRegistry - get buyer data - accredited investor status', async () => {
      _buyerInvestorStatus = await instances.BuyerRegistry.getBuyerInvestorStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry get accredited investor status", _buyerInvestorStatus)
    })

    it('HSTBuyerRegistry - get buyer data - kyc status', async () => {
      _buyerKycStatus = await instances.BuyerRegistry.getBuyerKycStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry kyc status", _buyerKycStatus)
    })

    it('HSTBuyerRegistry - get buyer data - aml status', async () => {
      _buyerAmlStatus = await instances.BuyerRegistry.getBuyerAmlStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry aml status", _buyerAmlStatus)
    })

    it('HSTBuyerRegistry - get buyer data - cft status', async () => {
      _buyerCftStatus = await instances.BuyerRegistry.getBuyerCftStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry cft status", _buyerCftStatus)
    })

  })


  describe('Checking HSTBuyerRegistry functionality - change buyer status', async() => {

    it('HSTServiceRegistry - add service', async () => {
      await instances.ServiceRegistry.addService(
        tokenDummyAddress,
        '3',
        web3.utils.fromAscii("KYC"),
        {from: user1.address}
        )
    })

    it('HSTBuyerRegistry - add kyc for buyer', async () => {
      await instances.BuyerRegistry.addKycServiceToBuyer(
        '21',
        tokenDummyAddress,
        '3',
        {from: user1.address}
      )
    })

    it('HSTServiceRegistry - add service', async () => {
      await instances.ServiceRegistry.addService(
        tokenDummyAddress,
        '3',
        web3.utils.fromAscii("AML"),
        {from: user1.address}
        )
    })

    it('HSTBuyerRegistry - add aml for buyer', async () => {
      await instances.BuyerRegistry.addAmlServiceToBuyer(
        '21',
        tokenDummyAddress,
        '3',
        {from: user1.address}
      )
    })

    it('HSTServiceRegistry - add service', async () => {
      await instances.ServiceRegistry.addService(
        tokenDummyAddress,
        '3',
        web3.utils.fromAscii("CFT"),
        {from: user1.address}
        )
    })

    it('HSTBuyerRegistry - add cft for buyer', async () => {
      await instances.BuyerRegistry.addCftServiceToBuyer(
        '21',
        tokenDummyAddress,
        '3',
        {from: user1.address}
      )
    })

    it('HSTBuyerRegistry - get buyer data - kyc status', async () => {
      _buyerKycStatus = await instances.BuyerRegistry.getBuyerKycStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry kyc status", _buyerKycStatus)
    })

    it('HSTBuyerRegistry - get buyer data - aml status', async () => {
      _buyerAmlStatus = await instances.BuyerRegistry.getBuyerAmlStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry aml status", _buyerAmlStatus)
    })

    it('HSTBuyerRegistry - get buyer data - cft status', async () => {
      _buyerCftStatus = await instances.BuyerRegistry.getBuyerCftStatus(
        '21',
        {from: user0.address}
      )
      console.log("      HSTBuyerRegistry cft status", _buyerCftStatus)
    })

  })

})
