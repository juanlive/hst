const common = require('./common.js')
const { sign, verifyIdentity } = require('./utilities')

const HSTIssuer = artifacts.require('./resolvers/HSTIssuer.sol')

let instances
let user
contract('Testing HSTIssuer', function (accounts) {
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
    instances = await common.initialize(owner.public, [])
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

  describe('Checking Resolver Functionality', async () => {
    it('deploy HSTIssuer', async () => {
      instances.HSTIssuer = await HSTIssuer.new(instances.Snowflake.address)
    })

    let identityNode
    it('create and update identity node', async () => {
      const result = await instances.HSTIssuer.newIdentityNode('test', '0x00')
      identityNode = result.logs[0].args.identityNode

      await instances.HSTIssuer.updateIdentityNode('test', '0x01')
    })

    it('user can add identity node', async () => {
      await instances.Snowflake.addResolver(
        instances.HSTIssuer.address, true, web3.utils.toBN(0), identityNode, { from: user.address }
      )

      await instances.HSTIssuer.addIdentityNode(web3.utils.soliditySha3('test'), { from: user.address })
      await instances.HSTIssuer.revokeIdentityNode(web3.utils.soliditySha3('test'), { from: user.address })

      await instances.Snowflake.removeResolver(
        instances.HSTIssuer.address, true, '0x00', { from: user.address }
      )
    })
  })
})
