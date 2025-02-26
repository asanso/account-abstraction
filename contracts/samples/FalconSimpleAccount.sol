// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../core/BaseAccount.sol";
import "../core/Helpers.sol";
import "./callback/TokenCallbackHandler.sol";
import "./ZKNOX_NTT.sol";
import "./ZKNOX_falcon.sol";
/**
  * minimal account.
  *  this is sample minimal account.
  *  has execute, eth handling methods
  *  has a single signer that can send requests through the entryPoint.
  */
contract FalconSimpleAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    address public owner;
    address public psi_rev;
    address public psi_inv_rev;
    uint256[] public publicKey;

    IEntryPoint private immutable _entryPoint;
    ZKNOX_falcon private falcon;
    ZKNOX_NTT private ntt;
    ZKNOX_HashToPoint private h2p = new ZKNOX_HashToPoint();

    event FalconSimpleAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        //falcon = new Falcon();
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     * @param dest destination address to call
     * @param value the value to pass in this call
     * @param func the calldata to pass in this call
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     * @param dest an array of destination addresses
     * @param value an array of values to pass to each call. can be zero-length for no-value calls
     * @param func an array of calldata to pass to each call
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length && (value.length == 0 || value.length == func.length), "wrong array lengths");
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
      * the implementation by calling `upgradeTo()`
      * @param anOwner the owner (signer) of this account
     */
    function initialize(address anOwner, uint256[] memory aPublicKey, address aApsi_rev, address aApsi_inrev) public virtual initializer {
        _initialize(anOwner,aPublicKey,aApsi_rev, aApsi_inrev);
    }

    function _initialize(address anOwner,uint256[] memory aPublicKey, address aApsi_rev, address aApsi_inrev) internal virtual {
        owner = anOwner;
        publicKey = aPublicKey;
        psi_rev = aApsi_rev;
        psi_inv_rev = aApsi_inrev;
        ntt = new ZKNOX_NTT(psi_rev, psi_inv_rev, 12289, 12265);
        falcon = new ZKNOX_falcon(ntt, h2p);
        emit FalconSimpleAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(entryPoint()) || msg.sender == owner, "account: not Owner or EntryPoint");
    }

    /// implement template method of BaseAccount
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        console.log("validating signature...");

        /* 
        * ================================================
        * TEMPORARY WORKAROUND: 
        * 
        * This implementation is used until the encoding of the signature
        * in https://github.com/asanso/falcon-sign-js/ is compatible with
        * the Solidity implementation.
        * ================================================
        */
        // forgefmt: disable-next-line
        uint[512] memory tmp_s2 = [uint(12283), 12027,24,37,12231,12278,12178,254,12158,12196,12133,12161,12236,12100,12277,164,109,12181,12230,149,12042,11905,12126,12019,515,129,296,12254,12225,119,12080,13,12236,53,12140,293,12253,12283,114,236,12097,119,12193,11905,12112,161,397,281,22,12115,52,12043,39,27,11960,12118,28,12039,87,12177,51,12173,205,4,37,136,12238,67,12239,11846,12177,167,198,12109,12173,167,12147,12233,10,12062,12154,90,10,275,44,12273,27,23,12164,12184,12273,12277,12170,12128,24,63,12119,11907,12028,12146,75,12275,247,12148,141,12254,12134,187,3,12125,12162,50,12225,202,12059,115,48,202,12254,12169,63,160,12162,48,12222,12175,12274,186,323,12273,11963,333,234,102,70,422,40,12143,56,12184,146,54,11959,12170,12132,12215,12201,237,12249,234,48,168,12279,11931,12010,12079,12046,12205,12143,3,36,52,294,4,12049,12255,86,12084,67,60,101,12168,217,12069,101,12130,177,12191,40,164,158,12193,12081,12022,12198,108,77,78,12201,33,237,12176,12016,12275,12178,37,12205,12255,12141,42,12238,35,12091,12275,139,197,12153,89,60,12173,20,12182,12254,156,12054,117,12164,12179,12136,207,13,12189,12255,47,133,12066,327,12104,40,33,12136,12182,12208,154,160,12120,269,28,281,200,12132,12224,136,12265,12068,171,12245,12177,12177,25,12280,101,149,332,74,12255,43,85,58,194,106,12026,49,34,374,231,12276,13,192,91,12004,46,186,12279,369,92,238,12004,12288,12187,12114,245,291,228,89,12255,12050,12174,78,12148,205,87,344,140,12153,134,175,12270,120,12268,12099,12088,12224,12173,12164,11868,76,12002,12084,12102,406,110,70,104,69,315,148,110,274,12116,222,11876,12246,273,47,54,12267,180,12064,139,12134,12170,206,12135,12270,85,12160,58,12265,12013,280,12226,12207,12264,12266,15,12149,158,386,97,11940,12259,294,168,146,11963,242,91,11996,168,11970,12120,12099,12263,184,11983,56,12161,36,12166,12246,12014,12225,12048,20,12239,202,12198,117,351,12115,12090,12191,12280,12203,175,105,12168,12115,173,41,12084,193,258,12205,452,108,12224,12287,12250,167,64,235,185,88,12259,155,11988,40,12177,12170,12186,149,45,12109,229,189,235,177,12140,12118,21,12230,12186,1,234,38,189,12277,12274,12240,42,12207,12076,12051,157,124,12253,12257,130,11804,12246,12263,136,12184,94,104,22,124,12267,12234,29,204,12120,12144,12234,12273,221,12273,181,71,12161,72,98,12187,12183,286,12011,12181,34,12244,12112,206,62,12246,46,12075,69,12028,12267,12247,11957,12061,12157,12069,12032,12041,12258,12013,39,244,12261,57,91,117,12270,12210,12164,12283,218,12271,12228,214,12237,12248,12280,395,12127,12,140,37,40];
        ZKNOX_falcon.Signature memory sig;
        for (uint256 i = 0; i < 512; i++) {
            sig.s2[i] = tmp_s2[i];
        }
        /* ================================================
        */
 
        sig.salt = userOp.callData;
        if (!falcon.verify(abi.encodePacked(userOpHash),sig, publicKey)) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyOwner();
    }
}

