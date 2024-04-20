// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibSort} from "solady/utils/LibSort.sol";

struct Call {
    address target;
    uint256 value;
    bytes data;
}

library LibZ0 {
    function messageHash(Call calldata input) public pure returns (bytes32) {
        return keccak256(abi.encode(input.target, input.value, input.data));
    }

    function computeStateRoot(
        address[] memory owners,
        uint256 threshold
    ) public pure returns (bytes32) {
        LibSort.sort(owners);
        return keccak256(abi.encodePacked(abi.encodePacked(owners), threshold));
    }
}
