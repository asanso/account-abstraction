import { Wallet, BigNumber } from 'ethers'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import { bufferToHex } from 'ethereumjs-util'


import {
  ERC1967Proxy__factory,
  EntryPoint,
  FalconSimpleAccount,
  FalconSimpleAccount__factory,
  TestUtil,
  TestUtil__factory
} from '../typechain'
import {
  createAccountOwner,
  deployEntryPoint,
  getBalance,
 
} from './testutils'
import { fillUserOpDefaults, getUserOpHash, encodeUserOp, signUserOp, packUserOp } from './UserOp'
import { parseEther } from 'ethers/lib/utils'
import { UserOperation } from './UserOperation'
const { getKernel,util } = require('falcon-sign');

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
    let account: FalconSimpleAccount
    let userOp: UserOperation
    let userOpHash: string
    let preBalance: number
    let expectedPay: number

    const actualGasPrice = 1e9
    // for testing directly validateUserOp, we initialize the account with EOA as entryPoint.
    let entryPointEoa: string

    before(async () => {
      // Wait for the Falcon512 kernel
      let Falcon512 = await getKernel('falcon512_n3_v1'); // Get falcon512_n3_v1 Kernel
      let keypair = Falcon512.genkey(); // { sk, pk, genKeySeed }

      /* 
      * ================================================
      * TEMPORARY WORKAROUND: 
      * 
      * This implementation is used until the encoding of the signature
      * in https://github.com/asanso/falcon-sign-js/ is compatible with
      * the Solidity implementation.
      * ================================================
      */
      //let publicKey = keypair.pk
      //const salt = new Uint8Array(20);
      //crypto.getRandomValues(salt);
      const salt = util.hexStringToUint8Array('f41f1009826c203576ce1e1ed3f27622c0e1cd1a')
      // Define the array as a list of BigInt (Uint256 equivalent)
      const publicKey: BigInt[] = [
        BigInt(8494), BigInt(9875), BigInt(5391), BigInt(1879), BigInt(708), BigInt(7214), BigInt(6161), BigInt(7426),
        BigInt(130), BigInt(4397), BigInt(5498), BigInt(8631), BigInt(2407), BigInt(9977), BigInt(1931), BigInt(7029),
        BigInt(2352), BigInt(991), BigInt(9225), BigInt(9158), BigInt(8285), BigInt(955), BigInt(12093), BigInt(4942),
        BigInt(2664), BigInt(778), BigInt(3383), BigInt(11334), BigInt(11105), BigInt(10565), BigInt(3474), BigInt(7022),
        BigInt(2706), BigInt(1183), BigInt(6455), BigInt(1113), BigInt(1385), BigInt(4181), BigInt(5984), BigInt(1364),
        BigInt(6193), BigInt(7574), BigInt(2703), BigInt(11943), BigInt(2783), BigInt(9363), BigInt(10213), BigInt(6442),
        BigInt(10177), BigInt(6408), BigInt(8584), BigInt(2766), BigInt(1171), BigInt(7190), BigInt(253), BigInt(3679),
        BigInt(2625), BigInt(7796), BigInt(8043), BigInt(5703), BigInt(2065), BigInt(459), BigInt(1063), BigInt(5107),
        BigInt(475), BigInt(7421), BigInt(2950), BigInt(1363), BigInt(9991), BigInt(2222), BigInt(1222), BigInt(2148),
        BigInt(12181), BigInt(10486), BigInt(7239), BigInt(2220), BigInt(8612), BigInt(10147), BigInt(11233), BigInt(10557),
        BigInt(3816), BigInt(7607), BigInt(2043), BigInt(9737), BigInt(1487), BigInt(6402), BigInt(7156), BigInt(4425),
        BigInt(11155), BigInt(8706), BigInt(2669), BigInt(9984), BigInt(4688), BigInt(8809), BigInt(3126), BigInt(5346),
        BigInt(8576), BigInt(11683), BigInt(12012), BigInt(2541), BigInt(7468), BigInt(3700), BigInt(12043), BigInt(6636),
        BigInt(274), BigInt(7905), BigInt(1637), BigInt(11874), BigInt(8091), BigInt(6388), BigInt(2132), BigInt(3454),
        BigInt(5363), BigInt(11278), BigInt(8138), BigInt(4104), BigInt(3664), BigInt(6955), BigInt(7423), BigInt(9252),
        BigInt(5243), BigInt(717), BigInt(9654), BigInt(11089), BigInt(2662), BigInt(5813), BigInt(2725), BigInt(3997),
        BigInt(7882), BigInt(8147), BigInt(1972), BigInt(5360), BigInt(9958), BigInt(6537), BigInt(9866), BigInt(1837),
        BigInt(9724), BigInt(2515), BigInt(6909), BigInt(11077), BigInt(7382), BigInt(8940), BigInt(10578), BigInt(66),
        BigInt(991), BigInt(11249), BigInt(12078), BigInt(5661), BigInt(297), BigInt(4236), BigInt(5240), BigInt(10615),
        BigInt(8894), BigInt(6752), BigInt(1599), BigInt(8903), BigInt(4789), BigInt(8794), BigInt(721), BigInt(143),
        BigInt(708), BigInt(3893), BigInt(9853), BigInt(10975), BigInt(12240), BigInt(4519), BigInt(3983), BigInt(9215),
        BigInt(420), BigInt(8767), BigInt(11835), BigInt(10220), BigInt(3914), BigInt(10930), BigInt(3539), BigInt(11989),
        BigInt(4395), BigInt(2901), BigInt(1427), BigInt(7668), BigInt(5489), BigInt(4941), BigInt(6674), BigInt(12249),
        BigInt(5831), BigInt(3530), BigInt(12171), BigInt(10261), BigInt(775), BigInt(894), BigInt(11564), BigInt(5706),
        BigInt(3810), BigInt(11670), BigInt(9294), BigInt(9899), BigInt(5872), BigInt(9997), BigInt(9218), BigInt(8757),
        BigInt(7970), BigInt(11087), BigInt(3323), BigInt(4779), BigInt(9473), BigInt(12172), BigInt(9576), BigInt(2989),
        BigInt(1404), BigInt(11193), BigInt(376), BigInt(7670), BigInt(9520), BigInt(11007), BigInt(10252), BigInt(55),
        BigInt(8952), BigInt(3523), BigInt(8081), BigInt(2097), BigInt(6848), BigInt(11377), BigInt(6165), BigInt(5777),
        BigInt(12044), BigInt(12000), BigInt(8941), BigInt(1892), BigInt(8951), BigInt(4426), BigInt(8954), BigInt(9118),
        BigInt(4116), BigInt(7340), BigInt(10060), BigInt(9311), BigInt(7351), BigInt(11995), BigInt(9476), BigInt(6246),
        BigInt(2151), BigInt(1574), BigInt(4104), BigInt(12141), BigInt(880), BigInt(3709), BigInt(2410), BigInt(8871),
        BigInt(1771), BigInt(8281), BigInt(11433), BigInt(8802), BigInt(5517), BigInt(7260), BigInt(8932), BigInt(2340),
        BigInt(11134), BigInt(8858), BigInt(1110), BigInt(2811), BigInt(6777), BigInt(10364), BigInt(9649), BigInt(7387),
        BigInt(1996), BigInt(6561), BigInt(7065), BigInt(2190), BigInt(12094), BigInt(11677), BigInt(10503), BigInt(2145),
        BigInt(11418), BigInt(10041), BigInt(9467), BigInt(109), BigInt(5395), BigInt(5299), BigInt(7200), BigInt(11203),
        BigInt(3966), BigInt(6117), BigInt(1065), BigInt(3458), BigInt(5521), BigInt(12182), BigInt(6969), BigInt(1134),
        BigInt(7108), BigInt(648), BigInt(285), BigInt(8703), BigInt(100), BigInt(12113), BigInt(6653), BigInt(7377),
        BigInt(6804), BigInt(1717), BigInt(9467), BigInt(10055), BigInt(4009), BigInt(3545), BigInt(7482), BigInt(28),
        BigInt(4253), BigInt(47), BigInt(12043), BigInt(7057), BigInt(1286), BigInt(10754), BigInt(3347), BigInt(3280),
        BigInt(3738), BigInt(3323), BigInt(7715), BigInt(6500), BigInt(350), BigInt(12245), BigInt(11148), BigInt(1705),
        BigInt(6450), BigInt(336), BigInt(2873), BigInt(176), BigInt(9059), BigInt(2491), BigInt(7546), BigInt(2877),
        BigInt(7417), BigInt(9768), BigInt(2526), BigInt(2893), BigInt(551), BigInt(9462), BigInt(1754), BigInt(3452),
        BigInt(7819), BigInt(10010), BigInt(844), BigInt(4087), BigInt(8473), BigInt(5019), BigInt(9155), BigInt(12253),
        BigInt(8338), BigInt(10746), BigInt(6837), BigInt(9485), BigInt(7469), BigInt(4277), BigInt(8497), BigInt(10631),
        BigInt(2810), BigInt(5104), BigInt(5895), BigInt(7050), BigInt(298), BigInt(1144), BigInt(3489), BigInt(7210),
        BigInt(11509), BigInt(4913), BigInt(7844), BigInt(1396), BigInt(9705), BigInt(11371), BigInt(1646), BigInt(3089),
        BigInt(7918), BigInt(12187), BigInt(6710), BigInt(106), BigInt(6810), BigInt(3783), BigInt(9423), BigInt(180),
        BigInt(3100), BigInt(228), BigInt(6112), BigInt(9775), BigInt(3407), BigInt(10474), BigInt(3340), BigInt(232),
        BigInt(11654), BigInt(454), BigInt(2551), BigInt(6891), BigInt(10879), BigInt(2473), BigInt(6594), BigInt(9791),
        BigInt(6870), BigInt(5661), BigInt(5877), BigInt(8893), BigInt(3075), BigInt(4752), BigInt(1135), BigInt(3859),
        BigInt(2495), BigInt(5101), BigInt(1384), BigInt(5825), BigInt(5539), BigInt(1734), BigInt(4694), BigInt(7444),
        BigInt(8731), BigInt(4653), BigInt(7432), BigInt(7238), BigInt(9267), BigInt(1719), BigInt(9790), BigInt(6698),
        BigInt(6049), BigInt(2948), BigInt(4962), BigInt(8614), BigInt(2381), BigInt(2866), BigInt(6384), BigInt(11786),
        BigInt(775), BigInt(4155), BigInt(7072), BigInt(9670), BigInt(2011), BigInt(4684), BigInt(6722), BigInt(1077),
        BigInt(7784), BigInt(7614), BigInt(217), BigInt(90), BigInt(9505), BigInt(4379), BigInt(1799), BigInt(1159),
        BigInt(6056), BigInt(11386), BigInt(5041), BigInt(3383), BigInt(102), BigInt(12112), BigInt(9520), BigInt(8228),
        BigInt(9636), BigInt(668), BigInt(210), BigInt(4688), BigInt(3381), BigInt(2281), BigInt(2261), BigInt(11425),
        BigInt(7820), BigInt(2252), BigInt(9565), BigInt(7195), BigInt(8650), BigInt(7037), BigInt(11164), BigInt(9071),
        BigInt(1220), BigInt(1974), BigInt(6262), BigInt(8288), BigInt(4926), BigInt(1069), BigInt(206), BigInt(7288),
        BigInt(4139), BigInt(4020), BigInt(728), BigInt(10582), BigInt(10621), BigInt(4568), BigInt(5054), BigInt(9984),
        BigInt(6837), BigInt(236), BigInt(7164), BigInt(9106), BigInt(9007), BigInt(3765), BigInt(700), BigInt(4173),
        BigInt(1524), BigInt(11782), BigInt(6690), BigInt(9860), BigInt(2926), BigInt(538), BigInt(11340), BigInt(6889),
        BigInt(10459), BigInt(7255), BigInt(7705), BigInt(6244), BigInt(10579), BigInt(7541), BigInt(10909), BigInt(11397),
        BigInt(9092), BigInt(115), BigInt(2610), BigInt(5294), BigInt(10509), BigInt(3454), BigInt(4985), BigInt(2496),
      ];
      /* 
      * END OF WORKAROUND
      * ================================================
      */
      entryPointEoa = accounts[2]
      const epAsSigner = await ethers.getSigner(entryPointEoa)

      // cant use "SimpleAccountFactory", since it attempts to increment nonce first
      const implementation = await new FalconSimpleAccount__factory(ethersSigner).deploy(entryPointEoa)
      const proxy = await new ERC1967Proxy__factory(ethersSigner).deploy(implementation.address, '0x')
      account = FalconSimpleAccount__factory.connect(proxy.address, epAsSigner)
      const FalconConstantsFactory = await ethers.getContractFactory("FalconConstants");
      const falconConstants = await FalconConstantsFactory.deploy();
      account.initialize(accountOwner.address,Array.from(publicKey), falconConstants.address, falconConstants.address)

      await ethersSigner.sendTransaction({ from: accounts[0], to: account.address, value: parseEther('0.2') })
      const callGasLimit = 200000
      const verificationGasLimit = 100000
      const maxFeePerGas = 3e9
      const chainId = await ethers.provider.getNetwork().then(net => net.chainId)
   
      let op = fillUserOpDefaults({
        sender: account.address,
        callGasLimit,
        verificationGasLimit,
        maxFeePerGas
      })
      userOp = signUserOp(op, accountOwner, entryPointEoa, chainId)
      userOpHash = await getUserOpHash(userOp, entryPointEoa, chainId)
      let sign = Array.from(Falcon512.sign(userOpHash , keypair.sk, salt));
      const encodedSignature = ethers.utils.defaultAbiCoder.encode(["uint256[]"], [sign]);
      let op2 =  {
        ...op,
        signature: encodedSignature,
        callData: salt
      }
      expectedPay = actualGasPrice * (callGasLimit + verificationGasLimit)
      preBalance = await getBalance(account.address)
      const packedOp = packUserOp(op2)
      const ret = await account.validateUserOp(packedOp, userOpHash, expectedPay, { gasPrice: actualGasPrice, gasLimit:  BigNumber.from(30000000) })
      await ret.wait()
    })

    it('should pay', async () => {
      const postBalance = await getBalance(account.address)
      expect(preBalance - postBalance).to.eql(expectedPay)
    })

    /*it('should return NO_SIG_VALIDATION on wrong signature', async () => {
      const userOpHash = HashZero
      const packedOp = packUserOp(userOp)
      const deadline = await account.callStatic.validateUserOp({ ...packedOp, nonce: 1 }, userOpHash, 0)
      expect(deadline).to.eq(1)
    })*/

  })
})
