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
    journal 0xa936476556cdfc24162c19ad75524b310d53a59a23aeb47c4861415b838cb050 
    post state digest 0xfc2950356b8ff007824093401eb702862e5d90c33b3e272fec8d0c55657102f5 
    seal 0x2abbf0eb15f1bc7c8eb3c72fc5368cf5e5f57ecb45d2d5cbc9ad95a1da49e17522c67a66bb56e13276aef6c083b1fec925d61ca3926c4a5bad90cfc2f5ba606d122b7fd4ffe02185a11a86a283ab7263876caeb818ecc4c41f22fcd3bb9ba7c72fce00f868ace8f537704eb01c7f53658c0a48d9b67b5fa345dba0ea59e4f3ba19e69f3353e65ff92e08dc647131576bbd43e152f6594fad69d780805c4ce91c13dcfbf7db6d7ddfee27bc1342d3013f571973c5c7008ab671c1712365af4a4427bb9dbe0e70905033652af2d42a587482254435d09f1ae4f7a1723244d2ff2804f6e8349991cde970ee7432c1c7d821d9a882acb123e1b9ffd61ab21eb5c849
    */
    Z0Wallet public wallet;
    bytes32 constant postStateDigest =
        hex"fc2950356b8ff007824093401eb702862e5d90c33b3e272fec8d0c55657102f5";
    bytes constant seal =
        hex"2abbf0eb15f1bc7c8eb3c72fc5368cf5e5f57ecb45d2d5cbc9ad95a1da49e17522c67a66bb56e13276aef6c083b1fec925d61ca3926c4a5bad90cfc2f5ba606d122b7fd4ffe02185a11a86a283ab7263876caeb818ecc4c41f22fcd3bb9ba7c72fce00f868ace8f537704eb01c7f53658c0a48d9b67b5fa345dba0ea59e4f3ba19e69f3353e65ff92e08dc647131576bbd43e152f6594fad69d780805c4ce91c13dcfbf7db6d7ddfee27bc1342d3013f571973c5c7008ab671c1712365af4a4427bb9dbe0e70905033652af2d42a587482254435d09f1ae4f7a1723244d2ff2804f6e8349991cde970ee7432c1c7d821d9a882acb123e1b9ffd61ab21eb5c849";

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
