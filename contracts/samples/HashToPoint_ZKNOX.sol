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
///* FILE: ZKNOX_NTT.sol
///* Description: Compute Negative Wrap Convolution NTT as specified in EIP-NTT
/**
 *
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./ZKNOX_keccak_prng.sol";

contract ZKNOX_HashToPoint {
    constructor() {}

    function splitToHex(bytes32 x) public pure returns (uint16[16] memory) {
        uint16[16] memory res;
        for (uint256 i = 0; i < 16; i++) {
            res[i] = uint16(uint256(x) >> ((15 - i) * 16));
        }
        return res;
    }

    function hashToPoint(bytes memory salt, bytes memory msgHash, uint256 q, uint256 n)
        public
        returns (uint256[] memory)
    {
        // // HashToPoint from Tetration CopyPasta
        // // TODO MODIFY WITH THE COMMENTED VERSION BELOW
        // uint256[] memory hashed = new uint256[](512);
        // uint256 i = 0;
        // uint256 j = 0;
        // bytes32 tmp = keccak256(abi.encodePacked(msgHash, salt));
        // uint16[16] memory sample = splitToHex(tmp);
        // uint256 k = (1 << 16) / q;
        // uint256 kq = k * q;
        // while (i < n) {
        //     if (j == 16) {
        //         tmp = keccak256(abi.encodePacked(tmp));
        //         sample = splitToHex(tmp);
        //         j = 0;
        //     }
        //     if (sample[j] < kq) {
        //         hashed[i] = sample[j] % q;
        //         i++;
        //     }
        //     j++;
        // }
        // ZKNOX_keccak_prng keccak_prng = new ZKNOX_keccak_prng();
        // return hashed;
        uint256 k = (1 << 16) / q;
        ZKNOX_keccak_prng keccak_prng = new ZKNOX_keccak_prng();
        keccak_prng.inject(abi.encodePacked(msgHash, salt));
        keccak_prng.flip();

        uint256 kq = k * q;
        bytes memory t_bytes;
        uint256 t;
        uint256[] memory c = new uint256[](512);
        uint256 i = 0;
        while (i < n) {
            assembly {
                mstore(add(t_bytes, 32), 0)
            }
            t_bytes = keccak_prng.extract(2); // 2 bytes, i.e. 16 bits
            assembly {
                t := mload(add(t_bytes, 32))
            }
            // console.log(t);
            t = t >> (256 - 16);
            // console.log(t);
            // console.log(kq);
            if (t < kq) {
                c[i] = t % q;
                i++;
            }
        }
        return c;
    }
}
