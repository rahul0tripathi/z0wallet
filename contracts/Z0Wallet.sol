// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.20;

import {IRiscZeroVerifier} from "risc0/IRiscZeroVerifier.sol";
import {ImageID} from "./ImageID.sol"; // auto-generated contract after running `cargo build`.

struct Call {
    address target;
    uint256 value;
    bytes data;
}

/// @title A starter application using RISC Zero.
/// @notice This basic application holds a number, guaranteed to be even.
/// @dev This contract demonstrates one pattern for offloading the computation of an expensive
///      or difficult to implement function to a RISC Zero guest running on Bonsai.
contract Z0Wallet {
    /// @notice RISC Zero verifier contract address.
    IRiscZeroVerifier public immutable verifier;
    /// @notice Image ID of the only zkVM binary to accept verification from.
    bytes32 public constant imageId = ImageID.Z0_GENERATOR_ID;
    bytes32 public multiSigState;
    uint256 public nonce;

    event Executed(bytes32 indexed message, uint256 indexed nonce, bytes data);

    /// @notice Initialize the contract, binding it to a specified RISC Zero verifier.
    constructor(IRiscZeroVerifier _verifier, bytes32 _multiSigState) {
        verifier = _verifier;
        multiSigState = _multiSigState;
    }

    /// @notice Set the even number stored on the contract. Requires a RISC Zero proof that the number is even.
    function execute(
        Call calldata input,
        bytes32 postStateDigest,
        bytes calldata seal
    ) public {
        bytes memory executeJournal = abi.encodePacked(journal(input));
        require(
            verifier.verify(
                seal,
                imageId,
                postStateDigest,
                sha256(executeJournal)
            ),
            "Z001"
        );
        // Construct the expected journal data. Verify will fail if journal does not match.
        (bool success, bytes memory data) = input.target.call{
            value: input.value
        }(input.data);
        require(success, "Z002");
        emit Executed(messageHash(input), nonce, data);
        nonce += 1;
    }

    function messageHash(Call calldata input) public pure returns (bytes32) {
        return keccak256(abi.encode(input.target, input.value, input.data));
    }

    function stateRoot() public view returns (bytes32) {
        return keccak256(abi.encode(multiSigState, nonce));
    }

    function journal(Call calldata input) public view returns (bytes32) {
        return keccak256(abi.encode(stateRoot(), messageHash(input)));
    }
}
