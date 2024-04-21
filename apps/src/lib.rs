use std::str::FromStr;
use std::time::Duration;

use alloy_primitives::FixedBytes;
use anyhow::{Context, Result};
use bonsai_sdk::alpha as bonsai_sdk;
use ethers::prelude::*;
use ethers_core::abi::{parse_abi_str, Token};
use ethers_core::abi::Token::Tuple;
use hexutil::{read_hex, to_hex};
use risc0_ethereum_contracts::groth16::Seal;
use risc0_zkvm::{compute_image_id, Receipt};
use serde::{Deserialize, Serialize};
use alloy_json_abi::JsonAbi;

#[derive(Debug, Serialize, Deserialize)]
pub struct EOASignature {
    pub eoa: Address,
    pub signature: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Z0Req {
    pub signers: Vec<Address>,
    pub threshold: String,
    pub nonce: String,
    pub message_hash: String,
    pub signatures: Vec<EOASignature>,
}

/// An implementation of a Prover that runs on Bonsai.
pub struct BonsaiProver {}

impl BonsaiProver {
    /// Generates a snark proof as a triplet (`Vec<u8>`, `FixedBytes<32>`,
    /// `Vec<u8>) for the given elf and input.
    pub fn prove(elf: &[u8], input: Z0Req) -> Result<(Vec<u8>, FixedBytes<32>, Vec<u8>)> {
        let client = bonsai_sdk::Client::from_env(risc0_zkvm::VERSION)?;

        // Compute the image_id, then upload the ELF with the image_id as its key.
        let image_id = compute_image_id(elf)?;
        let image_id_hex = image_id.to_string();

        client.upload_img(&image_id_hex, elf.to_vec())?;
        println!("Image ID: 0x{}", image_id_hex);

        // Prepare input data and upload it.
        let input_ser = serde_json::to_string(&input).unwrap();
        println!("{}", input_ser.as_str());
        // Prepare input data and upload it.
        let input_data = bytemuck::cast_slice(input_ser.as_bytes()).to_vec();
        let input_id = client.upload_input(input_data)?;

        println!("input id{}", input_id);

        // Start a session running the prover.
        let session = client.create_session(image_id_hex, input_id, vec![])?;
        println!("Created session: {}", session.uuid);
        let _receipt = loop {
            let res = session.status(&client)?;
            if res.status == "RUNNING" {
                println!(
                    "Current status: {} - state: {} - continue polling...",
                    res.status,
                    res.state.unwrap_or_default()
                );
                std::thread::sleep(Duration::from_secs(15));
                continue;
            }
            if res.status == "SUCCEEDED" {
                // Download the receipt, containing the output.
                let receipt_url = res
                    .receipt_url
                    .context("API error, missing receipt on completed session")?;

                let receipt_buf = client.download(&receipt_url)?;
                let receipt: Receipt = bincode::deserialize(&receipt_buf)?;

                break receipt;
            }

            panic!(
                "Workflow exited: {} - | err: {}",
                res.status,
                res.error_msg.unwrap_or_default()
            );
        };

        // Fetch the snark.
        let snark_session = client.create_snark(session.uuid)?;
        println!("Created snark session: {}", snark_session.uuid);
        let snark_receipt = loop {
            let res = snark_session.status(&client)?;
            match res.status.as_str() {
                "RUNNING" => {
                    println!("Current status: {} - continue polling...", res.status, );
                    std::thread::sleep(Duration::from_secs(15));
                    continue;
                }
                "SUCCEEDED" => {
                    break res.output.context("No snark generated :(")?;
                }
                _ => {
                    panic!(
                        "Workflow exited: {} err: {}",
                        res.status,
                        res.error_msg.unwrap_or_default()
                    );
                }
            }
        };

        let snark = snark_receipt.snark;
        log::debug!("Snark proof!: {snark:?}");

        let seal = Seal::abi_encode(snark).context("Read seal")?;
        let post_state_digest: FixedBytes<32> = snark_receipt
            .post_state_digest
            .as_slice()
            .try_into()
            .context("Read post_state_digest")?;
        let journal = snark_receipt.journal;

        Ok((journal, post_state_digest, seal))
    }
    pub fn mock(elf: &[u8], input: Z0Req) -> Result<(Vec<u8>, FixedBytes<32>, Vec<u8>)> {
        let journal = read_hex("0xa936476556cdfc24162c19ad75524b310d53a59a23aeb47c4861415b838cb050").unwrap();
        let digest: FixedBytes<32> = FixedBytes::from_slice(read_hex("0x8fd5407c4fabbafc25f8f00ac090c2c049cd6a0d235afa91a6f5a0f247d9bd68").unwrap().as_slice());
        let seal  = read_hex("0x1f36daef1ec1f40e13c858db23a24f2af31c87c79d32b528b9aaa0b16c249f6c2226d84cd47d0ccbb21afa26d5f746ce7618763e5f862488091cb91a494bf4372858dc3ac1f16506a4e495d91c47d18b2ec7df859f1be57217985da9a0c5633f1beed6a63c7e2ed8a8c3fd734d30b9e4eb1450a4f6faddd517b28973682c4b4d26718093d5b3c707f1dc180ef05c4864ae5a739e0aca7285ed40c674de8f4c2807546431a8237375486c79ed97b17a458af5d60bc83558c2b346c54a5e9dcc11053a7d0588147638cfd38814ed335ef8bde4e5474decd2e8b77da581a30f5fce11f4c6213ad0252bf72d8be26049e1eb4058716141185683e48be39c4ce476fc").unwrap();
        Ok((journal, digest, seal))
    }
}

#[derive(Deserialize)]
pub struct ExecuteCall {
    to: Address,
    data: String,
    value: String,
}