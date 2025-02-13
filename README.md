Proof of concept of contracts for [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) `SimpleWallet` with Falcon Signature Verification with account abstraction via alternative mempool.

**The solc-js shipped with hardhat is too slow for compiling the Falcon contract, In order to run this example it is needed to install the native solc compiler**

``export SOLC=/opt/homebrew/bin/solc``

# Usage

```
yarn install
yarn test test/falcon-simple-wallet.test.ts
```

# Resources

* https://ethresear.ch/t/so-you-wanna-post-quantum-ethereum-transaction-signature/21291
* https://ethresear.ch/t/falcon-as-an-ethereum-transaction-signature-the-good-the-bad-and-the-gnarly/21512
