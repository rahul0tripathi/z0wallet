pragma solidity ^0.8.20;

import {console2} from "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";

import {LibZ0, Call} from "../contracts/LibZ0.sol";

contract LibZ0Test is Test {
    function testStateRoot() public {
        address[] memory owners = new address[](3);

        owners[0] = 0x63F9725f107358c9115BC9d86c72dD5823E9B1E6;
        owners[1] = 0x687f4304Df62449dBc6C95FE9A8cb1153d40D42e;
        owners[2] = 0x0F8361Ef429B43fa48ac66a7Cd8F619c517274f1;

        uint256 threshold = 1;
        bytes32 root = LibZ0.computeStateRoot(owners, threshold);
        console2.logBytes32(root);
        assert(
            root ==
                hex"4e0bfd72190af3f7246eb3abbb4d5906748b8202940843a1cb9c94e2b87154b9"
        );
    }

    function testMessageHash() public {
        Call memory input = Call({
            target: 0x63F9725f107358c9115BC9d86c72dD5823E9B1E6,
            value: 100,
            data: ""
        });

        console2.logBytes32(LibZ0.messageHash(input));
    }
}
