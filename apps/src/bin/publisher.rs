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

// This application demonstrates how to send an off-chain proof request
// to the Bonsai proving service and publish the received proofs directly
// to your deployed app contract.

extern crate core;

use alloy_sol_types::{sol, SolInterface, SolValue};
use anyhow::{Context, Result};
use apps::{BonsaiProver, EOASignature, Z0Req};
use methods::IS_EVEN_ELF;

use std::str::FromStr;
use futures ;
use ethers_core::{types::{Signature, H160, U256}, utils::{keccak256}};
use ethers_core::abi::{AbiEncode, encode, FixedBytes, Token};
use ethers_core::types::Address;

use ethers_signers::{LocalWallet, Signer, WalletError};
use futures::executor::block_on;
use hexutil::to_hex;
use serde::{Deserialize, Serialize};

// `IEvenNumber` interface automatically generated via the alloy `sol!` macro.
sol! {
    interface IEvenNumber {
        function set(uint256 x, bytes32 post_state_digest, bytes calldata seal);
    }
}


async fn gen_test_input()  -> Z0Req {
    let message_hash = keccak256("hello".as_bytes());
    let wallet: LocalWallet = "dcf2cbdd171a21c480aa7f53d77f31bb102282b3ff099c78e3118b37348c72f7"
        .parse::<LocalWallet>()
        .unwrap();
    let signature = wallet.sign_message(to_hex(message_hash.as_slice()).as_str()).await.unwrap();
    let threshold = U256::from_str("1").unwrap().encode();
    let nonce  = U256::from_str("0").unwrap().encode();
    return Z0Req{
        signers: vec![H160::from_str("0x63f9725f107358c9115bc9d86c72dd5823e9b1e6").unwrap() as Address, H160::from_str("0x687f4304Df62449dBc6C95FE9A8cb1153d40D42e").unwrap() as Address, H160::from_str("0x0f8361eF429B43fA48aC66A7cD8F619C517274f1").unwrap() as Address],
        threshold: to_hex(threshold.as_slice()),
        nonce: to_hex(nonce.as_slice()),
        message_hash:to_hex(message_hash.as_slice()),
        signatures: vec![EOASignature{
            eoa: wallet.address(),
            signature: to_hex(signature.to_vec().as_slice()),
        }],
    }
}

fn main() -> Result<()> {
    env_logger::init();

    let input  = block_on(gen_test_input());
    // Send an off-chain proof request to the Bonsai proving service.
    let (journal, post_state_digest, seal) = BonsaiProver::prove(IS_EVEN_ELF, &input)?;
    let digest = post_state_digest.as_slice();


    println!("journal {} post state digest {} seal {}", to_hex(&*journal), to_hex(digest), to_hex(&*seal));
    // Decode the journal. Must match what was written in the guest with
    // `env::commit_slice`.

    Ok(())
}
