// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "../interfaces/ISenderCreator.sol";
import "./FalconSimpleAccount.sol";

/**
 * A sample factory contract for SimpleAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract FalconSimpleAccountFactory {
    FalconSimpleAccount public immutable accountImplementation;
    ISenderCreator public immutable senderCreator;

    constructor(IEntryPoint _entryPoint) {
        accountImplementation = new FalconSimpleAccount(_entryPoint);
        senderCreator = _entryPoint.senderCreator();
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(address owner,uint256 salt, uint256[] memory publicKey) public returns (FalconSimpleAccount ret) {
        require(msg.sender == address(senderCreator), "only callable from SenderCreator");
        /*address addr = getAddress(owner, salt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return FalconSimpleAccount(payable(addr));
        }*/
        console.log("create account");
        ret = FalconSimpleAccount(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(FalconSimpleAccount.initialize, (owner, (publicKey)))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    /*function getAddress(address owner,uint256 salt) public view returns (address) {
        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(FalconSimpleAccount.initialize, (owner))
                )
            )));
    }*/
}
