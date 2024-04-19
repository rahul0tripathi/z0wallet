pragma solidity ^0.8.20;

import {RiscZeroCheats} from "risc0/RiscZeroCheats.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {Z0Wallet} from "../contracts/Z0Wallet.sol";
import {Elf} from "./Elf.sol"; // auto-generated contract after running `cargo build`.

contract EvenNumberTest is RiscZeroCheats, Test {
    Z0Wallet public wallet;

    function setUp() public {
        IRiscZeroVerifier verifier = deployRiscZeroVerifier();
        wallet = new Z0Wallet(verifier);
    }

    // function test_validate() public {
    //     bytes32 post_state_digest = hex"5557a9623235566158dda1fdf819317dce48a6e2dbf0d056c8c695142157f812";
    //     bytes memory seal = hex"0748fba1c739583b60cce781e02c5790d07f8bf3e93fdd3b31a7ce8e8fdc5e420f702e3d619eaa1b972d659eff752a002189d2c3af49797b13a0d8a55728f3052cf9b74e848cc8eb5c6a7eab363f0365be437ba755282c1e333fa243121b60520d6dcc03260baedb9d83f76b8ba21d254fa99205b156b732c72898b5ca9d30611a11d7908e0b964fe1de03d642d9ec79455729e71d184ffe4c63c69f2b57d1e120b24f498ae69ee701ee2e8f107bc2e719416fe454e5c7264c0adb66a7f9bb111e216cd8d65f24f3fd8fa0dcd737ea9b59e5ef599985d1bf006184831317146c1ece908bdaf7161e87348516a5a245596d6295101ab977135bcb018b821c7fdd";

    //     wallet.validate( post_state_digest, seal);
    // }
}
