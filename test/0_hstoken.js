const truffleAssert = require('truffle-assertions')
const HSToken = artifacts.require('./HSToken.sol')
const HSTokenRegistry = artifacts.require('./HSTokenRegistry.sol')
const HSTServiceRegistry = artifacts.require('./components/HSTServiceRegistry.sol')
const HSTBuyerRegistry = artifacts.require('./components/HSTBuyerRegistry.sol')
const IdentityRegistry = artifacts.require('./components/IdentityRegistry.sol')

const common = require('./common.js')
const { sign, verifyIdentity, daysOn, daysToSeconds, createIdentity, timeTravel } = require('./utilities')

let instances
let user

contract('Testing HSToken', function (accounts) {
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
    },
        {
      hydroID: 'fiv',
      address: accounts[0],
      recoveryAddress: accounts[0],
      private: '0x2665671af93f210ddb5d5ffa16c77fcf961d52796f2b2d7afd32cc5d886350a8',
      id: 4
    }
  ]

  user = users[0]

  it('common contracts deployed', async () => {
    instances = await common.initialize(owner.public, users)
  })

  /* it('Identity can be created', async function () {
    const timestamp = Math.round(new Date() / 1000) - 1
    const permissionString = web3.utils.soliditySha3(
      '0x19', '0x00', instances.IdentityRegistry.address,
      'I authorize the creation of an Identity on my behalf.',
      user.recoveryAddress,
      user.address,
      { t: 'address[]', v: [instances.Snowflake.address] },
      { t: 'address[]', v: [] },
      timestamp
    )

    const permission = await sign(permissionString, user.address, user.private)

    await instances.Snowflake.createIdentityDelegated(
      user.recoveryAddress, user.address, [], user.hydroID, permission.v, permission.r, permission.s, timestamp
    )

    user.identity = web3.utils.toBN(1)

    await verifyIdentity(user.identity, instances.IdentityRegistry, {
      recoveryAddress:     user.recoveryAddress,
      associatedAddresses: [user.address],
      providers:           [instances.Snowflake.address],
      resolvers:           [instances.ClientRaindrop.address]
    })
  })*/

  it('Snowflake identities created for all accounts', async() => {
    for (let i = 0; i < users.length; i++) {
      await createIdentity(users[i], instances)
    }
  })


/*  it('Snowflake identities created for owner', async() => {
    for (let i = 0; i < users.length; i++) {
      await createIdentity(users[3], instances)
    }
  })*/


  describe('Checking HSToken functionality', async() =>{

    it('HSToken can be created', async () => {
      newToken = await HSToken.new(
          1,
          web3.utils.stringToHex("HydroSecurityToken"),
          "Hydro Security",
          web3.utils.fromAscii("HTST"),
          18,
          instances.HydroToken.address, 
          instances.IdentityRegistry.address,
          instances.BuyerRegistry.address,
          user.address,
          {from: user.address}
        )
        console.log("HSToken Address", newToken.address)
        console.log("User", user.address)
    })
    
    it('HSToken exists', async () => {
      userId = await newToken.isTokenAlive();
    })

/*    it('HSTokenRegistry set addresses', async () => {
      console.log('      Service Registry Address', instances.ServiceRegistry.address)
      await instances.TokenRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.ServiceRegistry.address,
        {from: users[0].address}
      )
    })

    it('HSTBuyerRegistry set registries addresses', async () => {
      await instances.BuyerRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.TokenRegistry.address,
        instances.ServiceRegistry.address,
        {from: users[0].address}
      )
    })

    it('HSTServiceRegistry set registries addresses', async () => {
      await instances.ServiceRegistry.setAddresses(
        instances.IdentityRegistry.address,
        instances.TokenRegistry.address,
        {from: users[0].address}
      )
    })*/

    it('Appoint token', async () => {
      await instances.TokenRegistry.appointToken(
        newToken.address,
        web3.utils.fromAscii('HTST'),
        web3.utils.fromAscii('Hydro Security'),
        'just-a-test',
        18,
        {from: users[1].address}
      )
    })

    // ------------------------------ BuyerRegistry settings

    it('Set default values to BuyerRegistry', async () => {
      instances.BuyerRegistry.assignTokenValues(
        newToken.address,
        "16",
        "10000",
        "5000",
        false,
        {from: user.address}
        )
    })

    it('HSTBuyerRegistry - add buyer 1', async () => {
      await instances.BuyerRegistry.addBuyer(
        '1', // EIN
        'Johnny',
        'Tester',
        web3.utils.fromAscii('GMB'),
        '1984', // year of birth
        '12', // month of birth
        '12', // day of birth
        '100000', // net worth
        '50000', // salary
        {from: user.address}
      )
    })


    it('HSTBuyerRegistry - add buyer 2', async () => {
      await instances.BuyerRegistry.addBuyer(
        '2', // EIN
        'Peter',
        'Tester',
        web3.utils.fromAscii('GMB'),
        '1980', // year of birth
        '10', // month of birth
        '20', // day of birth
        '100000', // net worth
        '50000', // salary
        {from: user.address}
      )
    })

    it('HSTServiceRegistry - add service', async () => {
      await instances.ServiceRegistry.addService(
        newToken.address,
        '3',
        web3.utils.fromAscii("KYC"),
        {from: users[1].address}
        )
    })

    it('HSTBuyerRegistry - add kyc for buyer 1', async () => {
      await instances.BuyerRegistry.addKycServiceToBuyer(
        '1',
        newToken.address,
        '3',
        {from: users[1].address}
      )
    })

    it('HSToken set MAIN_PARAMS', async () => {
      await newToken.set_MAIN_PARAMS(
        web3.utils.toWei("0.1"), // hydroPrice: 1 ether = same price
        web3.utils.toWei("0.001"), // ethPrice
        daysOn(15), // beginningDate
        daysOn(20), // lockEnds
        daysOn(24), // endDate
        web3.utils.toWei("20000000"), // _maxSupply
        daysOn(18), // _escrowLimitPeriod
        { from: user.address }
        )
    })


    it('HSToken set STO_FLAGS', async () => {
      await newToken.set_STO_FLAGS(
          true, // _LIMITED_OWNERSHIP, 
          false, // _PERIOD_LOCKED,
          true, // _PERC_OWNERSHIP_TYPE,
          true, // _HYDRO_AMOUNT_TYPE,
          true, // _ETH_AMOUNT_TYPE,
          true, // _HYDRO_ALLOWED,
          true, // _ETH_ALLOWED,
          true, // _KYC_WHITELIST_RESTRICTED, 
          true, // _AML_WHITELIST_RESTRICTED
          true, // WHITELIST_RESTRICTED
          true, // BLACKLIST_RESTRICTED
          false, // ETH_ORACLE
          false, // HYDRO_ORACLE
        { from: user.address }
        )
    })


    it('HSToken set STO_PARAMS', async () => {
      await newToken.set_STO_PARAMS(
          web3.utils.toWei("0.2"), // _percAllowedTokens: 1 ether = 100%, 0.2 ether = 20%
          web3.utils.toWei("1000"), // _hydroAllowed,
          web3.utils.toWei("1000"), // _ethAllowed,
          daysToSeconds(12).toString(), // _lockPeriod,
          "1", // _minInvestors,
          "4", // _maxInvestors
          user.address, // ethOracle
          user.address, // hydroOracle
        { from: user.address }
        )
    })

    it('HSToken activate Prelaunch', async () => {
      await newToken.stagePrelaunch({ from: user.address });
    })

/*    it('HSToken add KYC Resolver', async () => {
      await newToken.addKYCResolver(
        instances.KYCResolver.address,
        { from: user.address })
    })*/


    it('HSToken activate Presale', async () => {
      await newToken.stagePresale({ from: user.address });
    })

    it('HSToken activate Sale', async () => {
      await newToken.stageSale({ from: user.address });
    })

    it('HSToken activate Lock', async () => {
      await newToken.stageLock({ from: user.address });
    })

    it('HSToken activate Market', async () => {
      await newToken.stageMarket({ from: user.address });
    })


    it('HSToken adds EIN 1 to whitelist', async() => {
      await newToken.addWhitelist(["1"],
        { from: user.address })
    })

    it('HydroToken user 1 approves 1M HydroTokens for HSToken', async() => {
      await instances.HydroToken.approve(
        newToken.address,
        web3.utils.toWei("1000000"),
        { from: user.address })
    })

    it('HSTBuyerRegistry - get buyer data - kyc status: false', async () => {
      _buyerKycStatus = await instances.BuyerRegistry.getBuyerKycStatus(
        '1',
        {from: user.address}
      )
      console.log("      HSTBuyerRegistry kyc status", _buyerKycStatus)
    })

    it('HSToken Reverts buy for EIN user 1', async () => {
        await truffleAssert.reverts(
          newToken.buyTokens(
          "10",
          { from: user.address }),
          "Buyer must be approved for KYC"
        )
    })

    it('Set buyer status true for user 1', async () => {
      await instances.BuyerRegistry.setBuyerKycStatus(
        '1',
        true,
        {from: user.address}
      )
      console.log("      HSTBuyerRegistry kyc status", _buyerKycStatus)
    })


    it('HSTBuyerRegistry - get buyer data - kyc status: true', async () => {
      _buyerKycStatus = await instances.BuyerRegistry.getBuyerKycStatus(
        '1',
        {from: user.address}
      )
      console.log("      HSTBuyerRegistry kyc status", _buyerKycStatus)
    })

    it('HSToken buyTokens from EIN user 1', async () => {
      await newToken.buyTokens(
          web3.utils.toWei("12"),
          { from: user.address })
    })


    it('HSToken buyTokens again from EIN user 1', async () => {
      await newToken.buyTokens(
          web3.utils.toWei("24"),
          { from: user.address })
    })


    it('Store periods', async() => {

      // var now = parseInt(new Date().getTime() / 1000) + 20
      // Get now from blockchain (to avoid errors from previous timetravels)
      var nowReceived = await newToken.getNow()
      var now = parseInt(nowReceived.toNumber())
      console.log("NOW: ", now)
      var periods = []
      for (i=1; i < 25; i++) {
        // Stablish 24 periods of payment, separated 200 seconds from eachother
        periods.push(now + i * 200)
      }

      await timeTravel(200)

      var tx = await newToken.addPaymentPeriodBoundaries(
          periods,
          { from: user.address })
      console.log("Gas:",tx.receipt.gasUsed)
    })


    it('Read periods', async() => {
      var getPeriods = await newToken.getPaymentPeriodBoundaries(
            { from: user.address })
      console.log("Periods:",getPeriods.map(period=>period.toNumber()))
      var now = await newToken.getNow()
      console.log("Now:", now.toNumber())

      currentPeriod = await newToken._getPeriod(
        { from: user.address });
      console.log("Current period:",currentPeriod.toNumber())
    })


    it('HSToken reverts transfer 1.2 HSTokens to Account 2', async () => {
      await truffleAssert.reverts(
        newToken.transfer(
          users[1].address,
          web3.utils.toWei("1.2"),
          { from: user.address })
      )
      //after(async()=>{
          console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
          console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))
      //})
    })


    it('Set buyer status true for user 2', async () => {
      await instances.BuyerRegistry.setBuyerKycStatus(
        '2',
        true,
        {from: user.address}
      )
      console.log("      HSTBuyerRegistry kyc status", _buyerKycStatus)
    })



    it('HSToken transfer 1.2 HSTokens to Account 2', async () => {

      console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
      console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))

      await newToken.transfer(
        users[1].address,
        web3.utils.toWei("1.2"),
        { from: user.address })

      //after(async()=>{
          console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
          console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))
      //})
    })




    it('Setting oracle address', async() => {
      await newToken.addHydroOracle(
        users[2].address,
        { from: user.address })
    })

    it('Oracle notifies results of 5 Hydros for this period', async() => {
      await newToken.notifyPeriodResults(
        web3.utils.toWei("5"),
        { from: users[2].address })
    })

    it('User claims payment 1', async() => {
      console.log("HydroToken Balance user 1 BEFORE:", web3.utils.fromWei(await instances.HydroToken.balanceOf(user.address)))

      var payment = await newToken.claimPayment(
        { from: user.address })

      console.log("Period payed:", payment.receipt.logs[1].args.periodToPay.toNumber())
      console.log("Participation rate:", web3.utils.fromWei(payment.receipt.logs[1].args.investorParticipationRate))
      console.log("Period results:", web3.utils.fromWei(payment.receipt.logs[1].args.periodResults))
      console.log("Amount payed:", web3.utils.fromWei(payment.receipt.logs[1].args.paymentForInvestor))
      console.log("Amount from transfer log:", web3.utils.fromWei(payment.receipt.logs[0].args._amount))
      console.log("HydroToken Balance user 1 AFTER:", web3.utils.fromWei(await instances.HydroToken.balanceOf(user.address)))

    })

    it('Go to next period', async() => {
      await timeTravel(200)
      period = await newToken._getPeriod(
        { from: user.address });
      console.log("Current Period:", period.toNumber())
    })

    it('Oracle notifies results of 4 Hydros for this period', async() => {
      await newToken.notifyPeriodResults(
        web3.utils.toWei("4"),
        { from: users[2].address })
    })

    it('User claims payment 1', async() => {
      var payment = await newToken.claimPayment(
        { from: user.address })
      console.log("Period payed:", payment.receipt.logs[1].args.periodToPay.toNumber())
      console.log("Participation rate:", web3.utils.fromWei(payment.receipt.logs[1].args.investorParticipationRate))
      console.log("Period results:", web3.utils.fromWei(payment.receipt.logs[1].args.periodResults))
      console.log("Amount payed:", web3.utils.fromWei(payment.receipt.logs[1].args.paymentForInvestor))
      console.log("Amount from transfer log:", web3.utils.fromWei(payment.receipt.logs[0].args._amount))
      console.log("HydroToken Balance user 1 AFTER:", web3.utils.fromWei(await instances.HydroToken.balanceOf(user.address)))

    })

    it('Advancing periods', async () => {
      period = await newToken._getPeriod(
        { from: user.address });
      console.log("Current Period:", period.toNumber())

      await timeTravel(400)

      period = await newToken._getPeriod(
        { from: user.address });
      console.log("Current Period:", period.toNumber())

    })


    it('KYCResolver approve again EIN identity 2', async () => {
      await instances.KYCResolver.approveEin(
        "2",
        { from: user.address });
    })


    it('HSToken transfer 0.8 HSTokens to Account 2, to decrease his participationRate at period 4', async () => {

      await newToken.transfer(
        users[1].address,
        web3.utils.toWei("0.8"),
        { from: user.address })

      //after(async()=>{
          console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
          console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))
      //})
    })

    it('Advancing new period', async () => {
      await timeTravel(200)

      period = await newToken._getPeriod(
        { from: user.address });
      console.log("Current Period:", period.toNumber())

    })

    it('Oracle notifies results of 5 Hydros for this period', async() => {
      await newToken.notifyPeriodResults(
        web3.utils.toWei("5"),
        { from: users[2].address })
    })


    it('User claims payment 1 but there is nothing, once', async() => {
      var payment = await newToken.claimPayment(
        { from: user.address })
      console.log("Period payed:", payment.logs[0].args.periodToPay.toNumber())
      console.log("Participation rate:", web3.utils.fromWei(payment.logs[0].args.investorParticipationRate))
      console.log("Period results:", web3.utils.fromWei(payment.logs[0].args.periodResults))
      console.log("Amount payed:", web3.utils.fromWei(payment.logs[0].args.paymentForInvestor))
    })


    it('User claims payment 1 but there is nothing twice', async() => {
      var payment = await newToken.claimPayment(
        { from: user.address })
      console.log("Period payed:", payment.logs[0].args.periodToPay.toNumber())
      console.log("Participation rate:", web3.utils.fromWei(payment.logs[0].args.investorParticipationRate))
      console.log("Period results:", web3.utils.fromWei(payment.logs[0].args.periodResults))
      console.log("Amount payed:", web3.utils.fromWei(payment.receipt.logs[0].args.paymentForInvestor))
    })

    it('User claims payment 1 and now it works', async() => {
      var payment = await newToken.claimPayment(
        { from: user.address })
      console.log("Period payed:", payment.receipt.logs[1].args.periodToPay.toNumber())
      console.log("Participation rate:", web3.utils.fromWei(payment.receipt.logs[1].args.investorParticipationRate))
      console.log("Period results:", web3.utils.fromWei(payment.receipt.logs[1].args.periodResults))
      console.log("Amount payed:", web3.utils.fromWei(payment.receipt.logs[1].args.paymentForInvestor))
      console.log("Amount from transfer log:", web3.utils.fromWei(payment.receipt.logs[0].args._amount))
      console.log("HydroToken Balance user 1 AFTER:", web3.utils.fromWei(await instances.HydroToken.balanceOf(user.address)))

    })

  })
})
