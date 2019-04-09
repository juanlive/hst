const gas = 6.5 * 1e6
const gasPrice = 2000000000 // 2 gwei

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      websockets: true
    },
    coverage: {
      host: 'localhost',
      port: 8555,
      network_id: '*',
      gas: 0xfffffffffff,
      gasPrice: 0x01,
      websockets: true
    },
    rinkebyIPC: {
      host: 'localhost',
      port: 8545,
      network_id: 4,
      timeoutBlocks: 200,
      gas: gas,
      gasPrice: gasPrice,
      skipDryRun: true
    },
    mainIPC: {
      host: 'localhost',
      port: 8545,
      network_id: 1,
      timeoutBlocks: 200,
      gas: gas,
      gasPrice: gasPrice,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: '0.5.0',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  }
}

// const HDWalletProvider = require('truffle-hdwallet-provider');
// const infuraKey = "fj4jll3k.....";
//
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
      development: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      websockets: true
    },
    coverage: {
      host: 'localhost',
      port: 8555,
      network_id: '*',
      gas: 0xfffffffffff,
      gasPrice: 0x01,
      websockets: true
    },
    rinkebyIPC: {
      host: 'localhost',
      port: 8545,
      network_id: 4,
      timeoutBlocks: 200,
      gas: gas,
      gasPrice: gasPrice,
      skipDryRun: true
    },
    mainIPC: {
      host: 'localhost',
      port: 8545,
      network_id: 1,
      timeoutBlocks: 200,
      gas: gas,
      gasPrice: gasPrice,
      skipDryRun: true
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      // version: "0.5.1",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: false,
      //    runs: 200
      //  },
      //  evmVersion: "byzantium"
      // }
    }
  }
}
