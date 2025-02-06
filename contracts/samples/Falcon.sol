// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;
import {NTT} from "./NTT.sol";
import {Test, console} from "forge-std/Test.sol";

// TODO: make it a library (aka unfuck constants/data)
contract Falcon {
    uint256 constant n = 512;
    uint256 constant sigBound = 34034726;
    uint256 constant sigBytesLen = 666;
    uint256 constant q = 12289;
    NTT ntt;

    struct Signature {
        bytes salt;
        int256[] s1;
    }

    constructor() {
        ntt = new NTT();
    }

    function splitToHex(bytes32 x) public pure returns (uint16[16] memory) {
        uint16[16] memory res;
        for (uint i = 0; i < 16; i++) {
            res[i] = uint16(uint256(x) >> ((15 - i) * 16));
        }
        return res;
    }

    function hashToPoint(
        bytes memory salt,
        bytes memory msgHash
    ) public view returns (uint256[] memory) {
        uint[] memory hashed = new uint[](512);
        uint i = 0;
        uint j = 0;
        bytes32 tmp = keccak256(abi.encodePacked(salt, msgHash));
        uint16[16] memory sample = splitToHex(tmp);
        uint k = (1 << 16) / q;
        uint kq = k * q;
        while (i < n) {
            if (j == 16) {
                tmp = keccak256(abi.encodePacked(tmp));
                sample = splitToHex(tmp);
                j = 0;
            }
            if (sample[j] < kq) {
                // console.logUint(sample[j]);
                hashed[i] = sample[j] % q;
                i++;
            }
            j++;
        }
        return hashed;
    }

    function verify(
        bytes memory msgs,
        Signature memory signature,
        uint[] memory h // public key
    ) public view returns (address) {
        require(h.length == 512, "Invalid public key length");
        require(signature.s1.length == 512, "Invalid signature length");
        uint256[] memory s1 = new uint256[](512);
        for (uint i = 0; i < 512; i++) {
            if (signature.s1[i] < 0) {
                s1[i] = uint256(int256(q) + signature.s1[i]);
            } else {
                s1[i] = uint256(signature.s1[i]);
            }
        }
        uint256[] memory hashed = hashToPoint(msgs, signature.salt);
        uint256[] memory s0 = ntt.subZQ(hashed, ntt.mulZQ(s1, h));
        uint qs1 = 6144; // q >> 1;
        // normalize s0 // to positive cuz you'll **2 anyway?
        for (uint i = 0; i < n; i++) {
            if (s0[i] > qs1) {
                s0[i] = q - s0[i];
            } else {
                s0[i] = s0[i];
            }
        }
        // normalize s1
        for (uint i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }
        uint norm = 0;
        for (uint i = 0; i < n; i++) {
            norm += s0[i] * s0[i];
            norm += s1[i] * s1[i];
        }
        require(norm < sigBound, "Signature is invalid");
    }
}
