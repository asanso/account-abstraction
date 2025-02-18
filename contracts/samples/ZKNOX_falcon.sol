/**
 *
 */
/*ZZZZZZZZZZZZZZZZZZZKKKKKKKKK    KKKKKKKNNNNNNNN        NNNNNNNN     OOOOOOOOO     XXXXXXX       XXXXXXX                         ..../&@&#.       .###%@@@#, ..                         
/*Z:::::::::::::::::ZK:::::::K    K:::::KN:::::::N       N::::::N   OO:::::::::OO   X:::::X       X:::::X                      ...(@@* .... .           &#//%@@&,.                       
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::::N      N::::::N OO:::::::::::::OO X:::::X       X:::::X                    ..*@@.........              .@#%%(%&@&..                    
/*Z:::ZZZZZZZZ:::::Z K:::::::K   K::::::KN:::::::::N     N::::::NO:::::::OOO:::::::OX::::::X     X::::::X                   .*@( ........ .  .&@@@@.      .@%%%%%#&@@.                  
/*ZZZZZ     Z:::::Z  KK::::::K  K:::::KKKN::::::::::N    N::::::NO::::::O   O::::::OXXX:::::X   X::::::XX                ...&@ ......... .  &.     .@      /@%%%%%%&@@#                  
/*        Z:::::Z      K:::::K K:::::K   N:::::::::::N   N::::::NO:::::O     O:::::O   X:::::X X:::::X                   ..@( .......... .  &.     ,&      /@%%%%&&&&@@@.              
/*       Z:::::Z       K::::::K:::::K    N:::::::N::::N  N::::::NO:::::O     O:::::O    X:::::X:::::X                   ..&% ...........     .@%(#@#      ,@%%%%&&&&&@@@%.               
/*      Z:::::Z        K:::::::::::K     N::::::N N::::N N::::::NO:::::O     O:::::O     X:::::::::X                   ..,@ ............                 *@%%%&%&&&&&&@@@.               
/*     Z:::::Z         K:::::::::::K     N::::::N  N::::N:::::::NO:::::O     O:::::O     X:::::::::X                  ..(@ .............             ,#@&&&&&&&&&&&&@@@@*               
/*    Z:::::Z          K::::::K:::::K    N::::::N   N:::::::::::NO:::::O     O:::::O    X:::::X:::::X                   .*@..............  . ..,(%&@@&&&&&&&&&&&&&&&&@@@@,               
/*   Z:::::Z           K:::::K K:::::K   N::::::N    N::::::::::NO:::::O     O:::::O   X:::::X X:::::X                 ...&#............. *@@&&&&&&&&&&&&&&&&&&&&@@&@@@@&                
/*ZZZ:::::Z     ZZZZZKK::::::K  K:::::KKKN::::::N     N:::::::::NO::::::O   O::::::OXXX:::::X   X::::::XX               ...@/.......... *@@@@. ,@@.  &@&&&&&&@@@@@@@@@@@.               
/*Z::::::ZZZZZZZZ:::ZK:::::::K   K::::::KN::::::N      N::::::::NO:::::::OOO:::::::OX::::::X     X::::::X               ....&#..........@@@, *@@&&&@% .@@@@@@@@@@@@@@@&                  
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::N       N:::::::N OO:::::::::::::OO X:::::X       X:::::X                ....*@.,......,@@@...@@@@@@&..%@@@@@@@@@@@@@/                   
/*Z:::::::::::::::::ZK:::::::K    K:::::KN::::::N        N::::::N   OO:::::::::OO   X:::::X       X:::::X                   ...*@,,.....%@@@,.........%@@@@@@@@@@@@(                     
/*ZZZZZZZZZZZZZZZZZZZKKKKKKKKK    KKKKKKKNNNNNNNN         NNNNNNN     OOOOOOOOO     XXXXXXX       XXXXXXX                      ...&@,....*@@@@@ ..,@@@@@@@@@@@@@&.                     
/*                                                                                                                                   ....,(&@@&..,,,/@&#*. .                             
/*                                                                                                                                    ......(&.,.,,/&@,.                                
/*                                                                                                                                      .....,%*.,*@%                               
/*                                                                                                                                    .#@@@&(&@*,,*@@%,..                               
/*                                                                                                                                    .##,,,**$.,,*@@@@@%.                               
/*                                                                                                                                     *(%%&&@(,,**@@@@@&                              
/*                                                                                                                                      . .  .#@((@@(*,**                                
/*                                                                                                                                             . (*. .                                   
/*                                                                                                                                              .*/
///* Copyright (C) 2025 - Renaud Dubois, Simon Masson - This file is part of ZKNOX project
///* License: This software is licensed under MIT License
///* This Code may be reused including this header, license and copyright notice.
///* See LICENSE file at the root folder of the project.
///* FILE: ZKNOX_falcon.sol
///* Description: Compute ethereum friendly version of falcon verification
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "hardhat/console.sol";
import {ZKNOX_NTT} from "./ZKNOX_NTT.sol";

//choose the XOF to use here
import {ZKNOX_HashToPoint} from "./HashToPoint_ZKNOX.sol";

contract ZKNOX_falcon {
    //FALCON CONSTANTS
    uint256 constant n = 512;
    uint256 constant sigBound = 34034726;
    uint256 constant sigBytesLen = 666;
    uint256 constant q = 12289;
    uint256 qs1 = 6144; // q >> 1;

    ZKNOX_NTT ntt;
    ZKNOX_HashToPoint H2P;

    uint256 constant _ERR_INPUT_SIZE = 0xffffffff01;

    constructor(ZKNOX_NTT i_ntt, ZKNOX_HashToPoint h2p) {
        ntt = i_ntt;
        H2P = h2p;
    }

    struct Signature {
        bytes salt;
        uint256[512] s2; // CVETH-2025-080202: remove potential malleability by forcing positive coefficients with uint
    }

    function verify(
        bytes memory msgs,
        Signature memory signature,
        uint256[] memory h // public key
    ) public returns (bool result) {
        if (h.length != 512) return false; //"Invalid public key length"
        if (signature.salt.length != 40) return false; //CVETH-2025-080201: control salt length to avoid potential forge
        if (signature.s2.length != 512) return false; //"Invalid salt length"

        result = false;

        uint256[] memory s2 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            s2[i] = uint256(signature.s2[i]);
        }
        uint256[] memory hashed = H2P.hashToPoint(signature.salt, msgs, q, n);

        uint256[] memory s1 = ntt.ZKNOX_VECSUBMOD(hashed, ntt.ZKNOX_NTT_MUL(s2, h), q);

        // normalize s1 // to positive cuz you'll **2 anyway?
        for (uint256 i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }

        // normalize s2
        for (uint256 i = 0; i < n; i++) {
            if (s2[i] > qs1) {
                s2[i] = q - s2[i];
            } else {
                s2[i] = s2[i];
            }
        }

        uint256 norm = 0;
        for (uint256 i = 0; i < n; i++) {
            norm += s1[i] * s1[i];
            norm += s2[i] * s2[i];
        }
        if (norm > sigBound) {
            result = false;
        } else {
            result = true;
        }
        return result;
    }

    //same as above but takes the precomputed ntt(publickey) as input value
    function verify_opt(
        bytes memory msgs,
        Signature memory signature,
        uint256[] memory ntth // public key
    ) public returns (bool result) {
        if (ntth.length != 512) return false; //"Invalid public key length"
        if (signature.salt.length != 40) return false; //CVETH-2025-080201: control salt length to avoid potential forge
        if (signature.s2.length != 512) return false; //"Invalid salt length"

        result = false;

        uint256[] memory s2 = new uint256[](512);
        for (uint256 i = 0; i < 512; i++) {
            s2[i] = uint256(signature.s2[i]);
        }

        uint256[] memory hashed = H2P.hashToPoint(signature.salt, msgs, q, n);
        console.log("hashed");
        for (uint256 i = 0; i < 10; i++) {
            console.log(hashed[i]);
        }
        uint256[] memory s1 = ntt.ZKNOX_VECSUBMOD(hashed, ntt.ZKNOX_NTT_HALFMUL(s2, ntth), q);

        // normalize s1 // to positive cuz you'll **2 anyway?
        for (uint256 i = 0; i < n; i++) {
            if (s1[i] > qs1) {
                s1[i] = q - s1[i];
            } else {
                s1[i] = s1[i];
            }
        }

        // normalize s2
        for (uint256 i = 0; i < n; i++) {
            if (s2[i] > qs1) {
                s2[i] = q - s2[i];
            } else {
                s2[i] = s2[i];
            }
        }

        uint256 norm = 0;
        for (uint256 i = 0; i < n; i++) {
            norm += s1[i] * s1[i];
            norm += s2[i] * s2[i];
        }

        if (norm > sigBound) {
            result = false;
        } else {
            result = true;
        }
        return result;
    }
} //end of contract
/**
 *
 */
/*                                                                  END OF CONTRACT                                                                                     */
/**
 *
 */
/* the contract shall be initialized with a valid precomputation of psi_rev and psi_invrev contracts provided to the input ntt contract*/
