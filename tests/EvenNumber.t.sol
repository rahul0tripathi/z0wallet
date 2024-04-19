// Copyright 2024 RISC Zero, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.20;

import {RiscZeroCheats} from "risc0/RiscZeroCheats.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {EvenNumber} from "../contracts/EvenNumber.sol";
import {Elf} from "./Elf.sol"; // auto-generated contract after running `cargo build`.

contract EvenNumberTest is RiscZeroCheats, Test {
    EvenNumber public evenNumber;

    function setUp() public {
        IRiscZeroVerifier verifier = deployRiscZeroVerifier();
        evenNumber = new EvenNumber(verifier);
        assertEq(evenNumber.get(), 0);
    }

    function test_SetEven() public {
//        uint256 number = 12345678;
//        (bytes memory journal, bytes32 post_state_digest, bytes memory seal) =
//            prove(Elf.IS_EVEN_PATH, abi.encode(number));
        bytes32 post_state_digest = hex"48278393c24c206d6c25dc0286aa99cef88d2a6fc86b73bbb85b16c3b40360bf";
        bytes memory seal = hex"086f2f61d09b838b92c01f4d7e07dbfaed894aadcf2c39e6f3b9a1844018787b00988ca92f914d6da0e0bbf2668c421627e964ac2706321f023d74361d6589d5060bffa6acc5e2d367f2a14c4da3d7f8d632e655b47a75174fc787f8d90df42f0eb75a1ab41451cea8bd1ec9755a837301bbac1c41b6b3ed81656b8dfce620d70ea42830f494e1ac5010d8a580f1a594a7f65b424ffe5e713a8c8ae23edcdbf8228f560355e05f3b7596823743b557cd002af7bf73ad29fa53735685c92a54c110264182588c142581a45da7464f086b4cefc6b50c6417a4f5af3b0b794f41da0a13d4b7dcea0385183152690c0a7b425aef668c0f1fe783851f05fb52d2ad52";

        evenNumber.validate( post_state_digest, seal);
        //assertEq(evenNumber.get(), number);
    }

//    function test_SetZero() public {
//        uint256 number = 0;
//        (bytes memory journal, bytes32 post_state_digest, bytes memory seal) =
//            prove(Elf.IS_EVEN_PATH, abi.encode(number));
//
//        evenNumber.set(abi.decode(journal, (uint256)), post_state_digest, seal);
//        assertEq(evenNumber.get(), number);
//    }
}
