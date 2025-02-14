import { Wallet } from 'ethers'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import { toHex } from 'hardhat/internal/util/bigint'
import { bufferToHex } from 'ethereumjs-util'


import {
  ERC1967Proxy__factory,
  EntryPoint,
  SimpleAccount,
  SimpleAccount__factory,
  TestUtil,
  TestUtil__factory
} from '../typechain'
import {
  HashZero,
  ONE_ETH,
  createAccount,
  createAccountOwner,
  createAddress,
  deployEntryPoint,
  getBalance,
  isDeployed
} from './testutils'
import { fillUserOpDefaults, getUserOpHash, encodeUserOp, signUserOp, packUserOp } from './UserOp'
import { parseEther } from 'ethers/lib/utils'
import { UserOperation } from './UserOperation'
import { JsonRpcProvider } from '@ethersproject/providers'


const { getKernel } = require('falcon-sign');

describe('FalconSimpleAccount', function () {
  let entryPoint: EntryPoint
  let accounts: string[]
  let testUtil: TestUtil
  let accountOwner: Wallet
  const ethersSigner = ethers.provider.getSigner()

  before(async function () {
    entryPoint = await deployEntryPoint()
    accounts = await ethers.provider.listAccounts()
    // ignore in geth.. this is just a sanity test. should be refactored to use a single-account mode..
    if (accounts.length < 2) this.skip()
    testUtil = await new TestUtil__factory(ethersSigner).deploy()
    accountOwner = createAccountOwner()
  })

  describe('#validateUserOp', () => {
    let account: SimpleAccount
    let userOp: UserOperation
    let userOpHash: string
    let preBalance: number
    let expectedPay: number

    const actualGasPrice = 1e9
    // for testing directly validateUserOp, we initialize the account with EOA as entryPoint.
    let entryPointEoa: string

    before(async () => {
      entryPointEoa = accounts[2]
      const epAsSigner = await ethers.getSigner(entryPointEoa)

      // cant use "SimpleAccountFactory", since it attempts to increment nonce first
      const implementation = await new SimpleAccount__factory(ethersSigner).deploy(entryPointEoa)
      const proxy = await new ERC1967Proxy__factory(ethersSigner).deploy(implementation.address, '0x')
      account = SimpleAccount__factory.connect(proxy.address, epAsSigner)

      await ethersSigner.sendTransaction({ from: accounts[0], to: account.address, value: parseEther('0.2') })
      const callGasLimit = 200000
      const verificationGasLimit = 100000
      const maxFeePerGas = 3e9
      const chainId = await ethers.provider.getNetwork().then(net => net.chainId)

      // Wait for the Falcon512 kernel
      let Falcon512 = await getKernel('falcon512_n3_v1'); // Get falcon512_n3_v1 Kernel
      let keypair = Falcon512.genkey(); // { sk, pk, genKeySeed }
   
      let op = fillUserOpDefaults({
        sender: account.address,
        callGasLimit,
        verificationGasLimit,
        maxFeePerGas
      })


      userOp = signUserOp(op, accountOwner, entryPointEoa, chainId)

      userOpHash = await getUserOpHash(userOp, entryPointEoa, chainId)
      
      let sign = Falcon512.sign(userOpHash , keypair.sk);
      const buffer: Buffer = Buffer.from(sign);

      let op2 =  {
        ...op,
        signature: bufferToHex(buffer)
      }

      expectedPay = actualGasPrice * (callGasLimit + verificationGasLimit)

      preBalance = await getBalance(account.address)
      const packedOp = packUserOp(userOp)
      const ret = await account.validateUserOp(packedOp, userOpHash, expectedPay, { gasPrice: actualGasPrice })
      await ret.wait()
    })

    it('should pay', async () => {
      const postBalance = await getBalance(account.address)
      expect(preBalance - postBalance).to.eql(expectedPay)
    })

    it('should return NO_SIG_VALIDATION on wrong signature', async () => {
      const userOpHash = HashZero
      const packedOp = packUserOp(userOp)
      const deadline = await account.callStatic.validateUserOp({ ...packedOp, nonce: 1 }, userOpHash, 0)
      expect(deadline).to.eq(1)
    })
  })
})
