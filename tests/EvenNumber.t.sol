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
        bytes32 post_state_digest = hex"4ae562fbfb2a05e7277fdd4dc89c596af59667b3cc9b8a13869564521f2e73be";
        bytes memory seal = hex"1d200dd66d0db5494b4a670d18e45ca8ba6e128a1147290e8512b4e6de2b1678171e8dc31518e7a98a54b406bb4036a0305be7e4833797b21cfb6b1ebad059430b2fd8325ed5f6a83aaa9093fe593033d130ce7f7eb715debf10be6ca657a6780a9dd432a7fcdb3abaeb779aa08caabd2c807115f2ade89ea30b4495e816d7131360b4b8152699d157f11ab11e784d07255252a7b58a413bcd88a6a07c1140e71d2febbb1614233c7d81c40cd9c5a6e7740686dee6557f9a8b14fea439a9d95502b87a7ac54756875db41f44d31f1bf4bda466c3fb1bc7499dea394167bdb9480f9e81b8e26b3a6d9732c0ab0d4df1d7c1076d947934adae38f1a3f7520e177f";

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
