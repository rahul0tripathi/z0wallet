pragma solidity ^0.8.20;

import {RiscZeroCheats} from "risc0/RiscZeroCheats.sol";
import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {Z0Wallet} from "../contracts/Z0Wallet.sol";
import {LibZ0, Call} from "../contracts/LibZ0.sol";
import {Elf} from "./Elf.sol"; // auto-generated contract after running `cargo build`.

contract Z0WalletTest is RiscZeroCheats, Test {
    event Executed(bytes32 indexed message, uint256 indexed nonce, bytes data);

    /*
    {"signers":["0x63f9725f107358c9115bc9d86c72dd5823e9b1e6","0x687f4304df62449dbc6c95fe9a8cb1153d40d42e","0x0f8361ef429b43fa48ac66a7cd8f619c517274f1"],"threshold":"0x0000000000000000000000000000000000000000000000000000000000000001","nonce":"0x0000000000000000000000000000000000000000000000000000000000000000","message_hash":"0x8649d736c2af537facc35382d7e0d8503ed5f036fa5201a9186da1d4db189640","signatures":[{"eoa":"0x63f9725f107358c9115bc9d86c72dd5823e9b1e6","signature":"0xa3cff1be8ac5c3be80aac53829bfb949687b1e55d9abd4f9a7bf72dcfb242e20174f2240557f78bbc4c5d9b9f85648cfdd7e3687af0a61d09a8eb5d8d9772ab21b"}]}
    journal 0xa936476556cdfc24162c19ad75524b310d53a59a23aeb47c4861415b838cb050 post state digest 0x8fd5407c4fabbafc25f8f00ac090c2c049cd6a0d235afa91a6f5a0f247d9bd68 seal 0x1f36daef1ec1f40e13c858db23a24f2af31c87c79d32b528b9aaa0b16c249f6c2226d84cd47d0ccbb21afa26d5f746ce7618763e5f862488091cb91a494bf4372858dc3ac1f16506a4e495d91c47d18b2ec7df859f1be57217985da9a0c5633f1beed6a63c7e2ed8a8c3fd734d30b9e4eb1450a4f6faddd517b28973682c4b4d26718093d5b3c707f1dc180ef05c4864ae5a739e0aca7285ed40c674de8f4c2807546431a8237375486c79ed97b17a458af5d60bc83558c2b346c54a5e9dcc11053a7d0588147638cfd38814ed335ef8bde4e5474decd2e8b77da581a30f5fce11f4c6213ad0252bf72d8be26049e1eb4058716141185683e48be39c4ce476fc */
    Z0Wallet public wallet;
    bytes32 constant postStateDigest =
        hex"8fd5407c4fabbafc25f8f00ac090c2c049cd6a0d235afa91a6f5a0f247d9bd68";
    bytes constant seal =
        hex"1f36daef1ec1f40e13c858db23a24f2af31c87c79d32b528b9aaa0b16c249f6c2226d84cd47d0ccbb21afa26d5f746ce7618763e5f862488091cb91a494bf4372858dc3ac1f16506a4e495d91c47d18b2ec7df859f1be57217985da9a0c5633f1beed6a63c7e2ed8a8c3fd734d30b9e4eb1450a4f6faddd517b28973682c4b4d26718093d5b3c707f1dc180ef05c4864ae5a739e0aca7285ed40c674de8f4c2807546431a8237375486c79ed97b17a458af5d60bc83558c2b346c54a5e9dcc11053a7d0588147638cfd38814ed335ef8bde4e5474decd2e8b77da581a30f5fce11f4c6213ad0252bf72d8be26049e1eb4058716141185683e48be39c4ce476fc";

    function setUp() public {
        IRiscZeroVerifier verifier = deployRiscZeroVerifier();
        address[] memory owners = new address[](3);

        owners[0] = 0x63F9725f107358c9115BC9d86c72dD5823E9B1E6;
        owners[1] = 0x687f4304Df62449dBc6C95FE9A8cb1153d40D42e;
        owners[2] = 0x0F8361Ef429B43fa48ac66a7Cd8F619c517274f1;

        uint256 threshold = 1;
        bytes32 root = LibZ0.computeStateRoot(owners, threshold);
        wallet = new Z0Wallet(verifier, root);
    }

    function testExecute() public {
        console2.logUint(wallet.nonce());
        hoax(address(wallet));

        uint bal = address(wallet).balance;

        Call memory input = Call({
            target: 0x63F9725f107358c9115BC9d86c72dD5823E9B1E6,
            value: 100,
            data: ""
        });

        wallet.execute(input, postStateDigest, seal);

        assertEq(wallet.nonce(), 1);
        assertEq(bal - address(wallet).balance, 100);

        vm.expectRevert(bytes("Z001"));
        wallet.execute(input, postStateDigest, seal);
    }
    function testInvlidCallData() public {
        Call memory input = Call({
            target: 0x63F9725f107358c9115BC9d86c72dD5823E9B1E6,
            value: 101,
            data: "0x"
        });

        vm.expectRevert(bytes("Z001"));
        wallet.execute(input, postStateDigest, seal);
    }

    function testCallRevert() public {
        Call memory input = Call({
            target: 0x63F9725f107358c9115BC9d86c72dD5823E9B1E6,
            value: 100,
            data: ""
        });

        vm.expectRevert(bytes("Z002"));
        wallet.execute(input, postStateDigest, seal);
    }
}
