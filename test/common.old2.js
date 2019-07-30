const ClientRaindrop = artifacts.require('./resolvers/ClientRaindrop/ClientRaindrop.sol');
const DateTime = artifacts.require('./components/DateTime.sol');
const HydroToken = artifacts.require('./_testing/HydroToken.sol');
const HSTBuyerRegistry = artifacts.require('./components/HSTBuyerRegistry.sol');
const HSTokenRegistry = artifacts.require('./HSTokenRegistry.sol');
const HSTServiceRegistry = artifacts.require('./components/HSTServiceRegistry.sol');
//const IdentityRegistry = artifacts.require('./_testing/IdentityRegistry.sol');
const IdentityRegistry = artifacts.require('./components/IdentityRegistry.sol')
const KYCResolver = artifacts.require('./samples/KYCResolver.sol');
const OldClientRaindrop = artifacts.require('./_testing/OldClientRaindrop.sol');
const Snowflake = artifacts.require('./Snowflake.sol');


// general initialization
async function initialize (owner, users) {
  const instances = {};

  // existing utilities
  instances.IdentityRegistry = await IdentityRegistry.new({ from: owner });
  console.log("xxx Identity Registry", instances.IdentityRegistry.address);
  instances.DateTime = await DateTime.new({ from: owner });

  // hydro token
  instances.HydroToken = await HydroToken.new({ from: owner });

  for (let i = 0; i < users.length; i++) {
    await instances.HydroToken.transfer(
      users[i].address,
      web3.utils.toBN(1000).mul(web3.utils.toBN(1e18)),
      { from: owner }
    );
  }

  // snowflake
  instances.Snowflake = await Snowflake.new(
    instances.IdentityRegistry.address,
    instances.HydroToken.address,
    { from: owner }
  );

  // raindrop
  instances.OldClientRaindrop = await OldClientRaindrop.new({ from: owner })
  instances.ClientRaindrop = await ClientRaindrop.new(
    instances.Snowflake.address,
    instances.OldClientRaindrop.address,
    0, 0, { from: owner }
  );
  await instances.Snowflake.setClientRaindropAddress(instances.ClientRaindrop.address, { from: owner });

  // example kyc resolver
  instances.KYCResolver = await KYCResolver.new( {from: owner });
  
  // registries
  instances.TokenRegistry = await HSTokenRegistry.new(
    instances.IdentityRegistry.address,
    { from: owner }
  );
  instances.ServiceRegistry = await HSTServiceRegistry.new(
    instances.IdentityRegistry.address,
    newTokenRegistry.address,
    { from: owner }
  );
  instances.BuyerRegistry = await HSTBuyerRegistry.new(
    instances.DateTime.address,
    { from: owner }
  );

  // print adresses to be seen while running tests
  console.log("    Date Time        ", instances.DateTime.address);
  console.log("    KYC Resolver", instances.KYCResolver.address);
  console.log("    Identity Registry", instances.IdentityRegistry.address);
  console.log("    Hydro Token      ", instances.HydroToken.address);
  console.log("    Token    Registry", instances.TokenRegistry.address);
  console.log("    Service  Registry", instances.ServiceRegistry.address);
  console.log("    Buyer    Registry", instances.BuyerRegistry.address);
  
  // bye-bye
  return instances;
}

module.exports = {
  initialize: initialize
}
