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


/*  it('Identity can be created', async function () {
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
    await createIdentity(users[i])
  }
})


describe('Checking HSToken functionality', async() =>{

it('HSToken can be created', async () => {
  newToken = await HSToken.new(
      1,
      web3.utils.stringToHex("HydroSecurityToken"),
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

  it('HSToken add KYC Resolver', async () => {
    await newToken.addKYCResolver(
      instances.KYCResolver.address,
      { from: user.address })
  })


  it('HSToken activate Launch', async () => {
    await newToken.stageActivate({ from: user.address });
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

  it('HSToken buyTokens from EIN user 1', async () => {
    await newToken.buyTokens(
        "HYDRO",
        web3.utils.toWei("12"),
        { from: user.address })
  })

// Reject Identity 1 and try to buy

  it('KYCResolver reject EIN identity 1', async () => {
    await instances.KYCResolver.rejectEin(
      "1",
      { from: user.address });
  })

  it('HSToken Reverts buy for EIN user 1', async () => {
      await truffleAssert.reverts(
        newToken.buyTokens(
        "HYDRO",
        "10",
        { from: user.address }),
        "KYC not approved"
      )
  })

  it('KYCResolver approve again EIN identity 1', async () => {
    await instances.KYCResolver.approveEin(
      "1",
      { from: user.address });
  })

  it('HSToken buyTokens again from EIN user 1', async () => {
    await newToken.buyTokens(
        "HYDRO",
        web3.utils.toWei("24"),
        { from: user.address })
  })



  it('HSToken transfer 1.2 HSTokens to Account 2', async () => {

    console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
    console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))

    await newToken.transfer(
      users[1].address,
      web3.utils.toWei("1.2"),
      { from: user.address })

    after(async()=>{
      console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
      console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))
    })
  })


  it('KYCResolver reject EIN identity 2', async () => {
    await instances.KYCResolver.rejectEin(
      "2",
      { from: user.address });
  })


  it('HSToken reverts transfer 1.2 HSTokens to Account 2', async () => {
    await truffleAssert.reverts(
      newToken.transfer(
        users[1].address,
        web3.utils.toWei("1.2"),
        { from: user.address })
    )
    after(async()=>{
      console.log("Balance user 1:", web3.utils.fromWei(await newToken.balanceOf(user.address)))
      console.log("Balance user 3:", web3.utils.fromWei(await newToken.balanceOf(users[1].address)))
    })
  })


})


})


function daysOn(_days) {
  return parseInt(new Date() / 1000 + daysToSeconds(_days)).toString();
}

function daysToSeconds(_days) {
  return _days * 24 * 60 * 60;
}


const createIdentity = async(_user) => {

    const timestamp = Math.round(new Date() / 1000) - 1
    const permissionString = web3.utils.soliditySha3(
      '0x19', '0x00', instances.IdentityRegistry.address,
      'I authorize the creation of an Identity on my behalf.',
      _user.recoveryAddress,
      _user.address,
      { t: 'address[]', v: [instances.Snowflake.address] },
      { t: 'address[]', v: [] },
      timestamp
    )

    const permission = await sign(permissionString, _user.address, _user.private)

    await instances.Snowflake.createIdentityDelegated(
      _user.recoveryAddress, _user.address, [], _user.hydroID, permission.v, permission.r, permission.s, timestamp
      , {from: _user.address})

    _user.identity = web3.utils.toBN(_user.id)

    await verifyIdentity(_user.identity, instances.IdentityRegistry, {
      recoveryAddress:     _user.recoveryAddress,
      associatedAddresses: [_user.address],
      providers:           [instances.Snowflake.address],
      resolvers:           [instances.ClientRaindrop.address]
    })

}