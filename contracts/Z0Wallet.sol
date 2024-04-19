// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated contract after running `cargo build`.

/// @title A starter application using RISC Zero.
/// @notice This basic application holds a number, guaranteed to be even.
/// @dev This contract demonstrates one pattern for offloading the computation of an expensive
///      or difficult to implement function to a RISC Zero guest running on Bonsai.
contract Z0Wallet {
    /// @notice RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable verifier;
    /// @notice Image ID of the only zkVM binary to accept verification from.
    bytes32 public constant imageId = ImageID.Z0_GENERATOR_ID;

    /// @notice Initialize the contract, binding it to a specified RISC Zero verifier.
    constructor(IRiscZeroVerifier _verifier) {
        verifier = _verifier;
    }

    /// @notice Set the even number stored on the contract. Requires a RISC Zero proof that the number is even.
    function validate(bytes32 postStateDigest, bytes calldata seal) public {
        // Construct the expected journal data. Verify will fail if journal does not match.
        bytes memory journal = hex"f5b14de0b001cb316c7a7f16cd0f589214bd70230446bbe5bf5ff645a1163aa9";
        require(verifier.verify(seal, imageId, postStateDigest, sha256(journal)));
    }
}
