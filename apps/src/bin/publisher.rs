extern crate core;

use std::str::FromStr;

use anyhow::Result;
use ethers_core::{types::{H160, U256}, utils::keccak256};
use ethers_core::abi::AbiEncode;
use ethers_core::types::Address;
use ethers_signers::{LocalWallet, Signer};
use futures;
use futures::executor::block_on;
use hexutil::to_hex;

use apps::{BonsaiProver, EOASignature, Z0Req};
use methods::Z0_GENERATOR_ELF;

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
    let (journal, post_state_digest, seal) = BonsaiProver::prove(Z0_GENERATOR_ELF, &input)?;
    let digest = post_state_digest.as_slice();


    println!("journal {} post state digest {} seal {}", to_hex(&*journal), to_hex(digest), to_hex(&*seal));
    Ok(())
}
