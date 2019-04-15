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
    console.log("HSTokenAddress", newToken.address)

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

    console.log("User",user.address)
  })

})




function daysOn(days) {
  return parseInt(new Date() / 1000 + days * 24 * 60 * 60).toString();
}



})
