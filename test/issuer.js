const truffleAssert = require('truffle-assertions');
const HSToken = artifacts.require('./HSToken.sol')

const common = require('./common.js')
const { sign, verifyIdentity } = require('./utilities')

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
      private: '0x6bf410ff825d07346c110c5836b33ec76e7d1ee051283937392180b732aa3aff'
    }
  ]

  it('common contracts deployed', async () => {
    instances = await common.initialize(owner.public, users)
  })


  it('Identity can be created', async function () {
    user = users[0]
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
  })


describe('Checking HSToken functionality', async() =>{

it('HSToken can be created', async () => {
  newToken = await HSToken.new(
      1,
      "0xa7f15e4e66334e8214dfd97d5214f1f8f11c90f25bbe44b344944ed9efed7e29",
      "Hydro Security",
      "HTST",
      18,
      instances.HydroToken.address, // HydroToken Rinkeby
      instances.IdentityRegistry.address, // IdentityRegistry Rinkeby
      {from: user.address}
    )
    console.log("HSToken Address", newToken.address)
    console.log("User", user.address)

})


  it('HSToken exists', async () => {
    userId = await newToken.Owner();
  })


  it('HSToken set MAIN_PARAMS', async () => {
    await newToken.set_MAIN_PARAMS(
      web3.utils.toWei("10"), // hydroPrice
      web3.utils.toWei("0.2"), // ethPrice
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
        false, // _IS_LOCKED,
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
      { from: user.address }
      )
  })


  it('HSToken set STO_PARAMS', async () => {
    await newToken.set_STO_PARAMS(
        web3.utils.toWei("0.2"), // _percAllowedTokens, expressed as 1 ether = 100%, 0.2 ether = 20%
        web3.utils.toWei("1000"), // _hydroAllowed,
        web3.utils.toWei("1000"), // _ethAllowed,
        daysToSeconds(12).toString(), // _lockPeriod,
        "1", // _minInvestors,
        "4", // _maxInvestors
      { from: user.address }
      )
  })

  it('HSToken activate Prelaunch', async () => {
    await newToken.stagePrelaunch({ from: user.address });
  })

  it('HSToken add KYC Resolver', async () => {
    await newToken.addKYCResolver(
      instances.KYCResolver.address,
      { from: user.address })
  })


  it('HSToken activate Launch', async () => {
    await newToken.stageActivate({ from: user.address });
  })


  it('Adds User 1 to the Whitelist', async() => {
    await newToken.addWhitelist(["1"],
      { from: user.address })
  })


 // it('buyTokens from EIN user 1', async () => {
 //   await newToken.buyTokens(
 //       "HYDRO",
 //       "10",
 //       { from: user.address })
 // })


  it('Reject EIN identity 1', async () => {
    await instances.KYCResolver.rejectEin(
      "1",
      { from: user.address });
  })

  it('Reverts buy for EIN user 1', async () => {
      await truffleAssert.reverts(
        newToken.buyTokens(
        "HYDRO",
        "10",
        { from: user.address }),
        "KYC not approved"
      )
  })


})


})


function daysOn(_days) {
  return parseInt(new Date() / 1000 + daysToSeconds(_days)).toString();
}

function daysToSeconds(_days) {
  return _days * 24 * 60 * 60;
}



