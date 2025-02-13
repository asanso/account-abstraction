import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import { HardhatUserConfig, subtask,task } from 'hardhat/config'
import 'hardhat-deploy'
import '@nomiclabs/hardhat-etherscan'

import 'solidity-coverage'

import * as fs from 'fs'

const {
  TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD,
} = require("hardhat/builtin-tasks/task-names");
const path = require("path");

const SALT = '0x90d8084deab30c2a37c45e8d47f49f2f7965183cb6990a98943ef94940681de3'
process.env.SALT = process.env.SALT ?? SALT

task('deploy', 'Deploy contracts')
  .addFlag('simpleAccountFactory', 'deploy sample factory (by default, enabled only on localhost)')

const mnemonicFileName = process.env.MNEMONIC_FILE!
let mnemonic = 'test '.repeat(11) + 'junk'
if (fs.existsSync(mnemonicFileName)) { mnemonic = fs.readFileSync(mnemonicFileName, 'ascii') }

function getNetwork1 (url: string): { url: string, accounts: { mnemonic: string } } {
  return {
    url,
    accounts: { mnemonic }
  }
}

function getNetwork (name: string): { url: string, accounts: { mnemonic: string } } {
  return getNetwork1(`https://${name}.infura.io/v3/${process.env.INFURA_ID}`)
  // return getNetwork1(`wss://${name}.infura.io/ws/v3/${process.env.INFURA_ID}`)
}

const optimizedCompilerSettings = {
  version: '0.8.28',
  settings: {
    evmVersion: 'cancun',
    optimizer: { enabled: true, runs: 1000000 },
    viaIR: true
  }
}

const optimizedCompilerSettingsFalcon = {
  version: '0.8.28',
  settings: {
    evmVersion: 'cancun',
    optimizer: { enabled: false},
    viaIR: false
  }
}


subtask(
  TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD,
  async (
    args: {
      solcVersion: string;
    },
    hre,
    runSuper
  ) => {
    console.log("subtask TASK_COMPILE_SOLIDITY_GET_SOLC_BUILD");
    if (process.env.SOLC !== undefined) {
      console.log(
          "Using Solidity compiler set in SOLC:",
          process.env.SOLC
      );
      return {
        compilerPath: process.env.SOLC,
        isSolcJs: false, // false for native compiler
        version: args.solcVersion,
      };
    }
    console.log("snooooo");
    // since we only want to override the compiler for version 0.8.24,
    // the runSuper function allows us to call the default subtask.
    return runSuper();
  }
);


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  solidity: {
    compilers: [{
      version: '0.8.28',
      settings: {
        evmVersion: 'cancun',
        viaIR: true,
        optimizer: { enabled: true, runs: 1000000 }
      }
    }],
    overrides: {
      'contracts/core/EntryPoint.sol': optimizedCompilerSettingsFalcon,
      'contracts/core/EntryPointSimulations.sol': optimizedCompilerSettings,
      'contracts/samples/SimpleAccount.sol': optimizedCompilerSettingsFalcon,
      'contracts/samples/SimpleAccountFactory.sol': optimizedCompilerSettingsFalcon,
      'contracts/samples/NTT.sol': optimizedCompilerSettingsFalcon, 
      'contracts/samples/Falcon.sol': optimizedCompilerSettingsFalcon, 
    }
  },
  networks: {
    hardhat: {
      blockGasLimit: 100000000429720 // whatever you want here
    },
    dev: { url: 'http://localhost:8545' },
    // github action starts localgeth service, for gas calculations
    localgeth: { url: 'http://localgeth:8545' },
    goerli: getNetwork('goerli'),
    sepolia: getNetwork('sepolia'),
    proxy: getNetwork1('http://localhost:8545')
  },
  mocha: {
    timeout: 10000
  },
  // @ts-ignore
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }

}

// coverage chokes on the "compilers" settings
if (process.env.COVERAGE != null) {
  // @ts-ignore
  config.solidity = config.solidity.compilers[0]
}

export default config
