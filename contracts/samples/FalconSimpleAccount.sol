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
    address public Apsi_rev;
    address public Apsi_inrev;
    uint256[] public publicKey;

    IEntryPoint private immutable _entryPoint;
    ZKNOX_falcon private immutable falcon;

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
        Apsi_rev = aApsi_rev;
        Apsi_inrev = aApsi_inrev;
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
        //uint[512] memory tmp_s1 = [uint(-71), 94,208,67,77,122,80,-464,198,494,-96,-120,-61,-53,182,59,108,-275,-166,195,-375,-91,90,-48,252,287,111,-182,-48,-126,195,36,-304,-121,-112,16,362,-81,280,197,65,287,-147,-57,-216,-116,79,115,-258,-381,-88,-222,3,114,213,1,201,-234,-115,192,-22,-167,-19,227,-142,213,-18,-241,118,-2,292,63,18,-36,47,-285,-104,158,10,81,-34,-104,-94,-69,14,-33,47,65,144,-1,-313,-152,-221,63,49,-6,-35,72,112,-159,-15,-542,-103,-92,48,99,11,-208,163,-63,313,-124,149,81,-35,-203,369,-223,68,130,74,9,184,-232,48,72,-161,52,59,139,27,68,93,-58,-31,-9,-269,5,205,-98,456,121,-74,-144,-241,260,-54,-38,76,-157,-67,-68,263,-101,-123,-216,26,-32,-172,48,-53,63,-103,150,-77,85,-281,-304,176,293,-184,167,-64,130,-4,-237,-77,-329,60,54,162,-110,-108,-137,-98,-25,-181,-74,59,2,-168,106,-40,-10,158,108,52,29,-32,10,-106,113,246,30,-48,78,-31,-45,351,-44,-57,240,-73,-121,75,-139,172,137,146,-332,-78,-41,202,-23,-165,-179,-114,52,-43,57,-129,-128,91,6,254,18,242,-51,-236,-107,135,-242,-70,-4,-17,297,173,108,-172,34,278,118,-118,98,139,-10,-57,148,67,48,-31,34,3,24,8,-77,-79,63,-185,90,-228,61,326,27,-55,-116,166,162,-116,161,-333,102,-22,22,-70,-56,168,-338,-95,131,-108,13,-328,-179,-211,-52,101,137,15,194,116,26,-115,2,126,-379,-62,-115,84,-87,30,-187,42,181,-286,-57,-212,-79,120,-100,-168,-29,59,-165,-144,-112,28,-78,234,59,93,108,26,-342,-5,-203,-11,-137,-419,62,21,-84,29,-107,12,-65,-5,-153,-181,-358,175,-17,165,68,-109,37,106,22,45,-6,-242,78,-130,-23,-193,52,-183,-164,94,36,-143,201,168,-138,174,-118,360,339,-56,-34,-49,-168,-434,98,-170,141,-115,98,10,-51,-215,-332,-144,12,-115,-346,-241,42,30,118,-55,-183,-105,-48,-42,-268,-46,-56,-136,364,-20,285,136,55,7,131,66,-203,-94,157,191,-41,-203,39,149,-115,61,-311,113,-354,36,0,-202,230,69,11,254,171,-72,131,-58,-242,-132,-11,-124,-238,-143,-227,-147,66,-29,-19,130,371,-35,-23,99,-94,94,194,210,87,-42,-107,-76,-15,-181,-160,-52,124,-122,-53,32,-119,47,127,231,-55,-75,-68,-32,-176,-1,81,205,22,224,586,-98,74,-266,-102,285,-197,-53,4,34,-261,294,-388,-28,189,170,177,-185,15,320,-188,-180,-116,-179,-249];
        ZKNOX_falcon.Signature memory sig;
        /*sig.s2 = new uint256[](512);
        for (uint i = 0; i < 512; i++) {
            sig.s2[i] = tmp_s1[i];
        }
        /* ================================================
        */
 
        sig.salt = userOp.callData;
        //falcon.verify(abi.encodePacked(userOpHash),sig, publicKey);
        //falcon.v(abi.decode(userOp.signature, (uint256[])));
        return SIG_VALIDATION_FAILED;

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

