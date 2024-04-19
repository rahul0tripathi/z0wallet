use std::cmp::Ordering;
use std::fmt;
use std::fmt::{Display, Formatter};
use std::str;
use std::str::FromStr;

use alloy_primitives::FixedBytes;
use alloy_sol_types::SolValue;
use ethers_core::{types::{Signature, U256}, utils::keccak256};
use ethers_core::abi::{AbiEncode, encode, Token};
use ethers_core::types::Address;
use ethers_core::utils::hex::ToHexExt;
use hexutil::read_hex;
use risc0_zkvm::guest::env;
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug)]
pub enum Z0ValidationError {
    MissingSigners,
}

impl Display for Z0ValidationError {
    fn fmt(&self, f: &mut Formatter<'_>) -> fmt::Result {
        match self {
            Z0ValidationError::MissingSigners => write!(f, "MISSING SIGNERS"),
        }
    }
}
impl std::error::Error for Z0ValidationError {}

#[derive(Debug, Serialize, Deserialize)]
struct EOASignature {
    eoa: Address,
    signature: String
}

#[derive(Debug, Serialize, Deserialize)]
struct Z0Req {
    signers: Vec<Address>,
    threshold: String,
    nonce: String,
    message_hash: String,
    signatures: Vec<EOASignature>
}

fn generate_output(req:Z0Req) -> Result<[u8; 32],Z0ValidationError>{
    let signers = &mut req.signers.clone();

    signers.sort_by(|x, x1| {
        return U256::from_str(x.encode_hex().as_str()).unwrap().cmp(&U256::from_str(x1.encode_hex().as_str()).unwrap());
    });

    let mut total: Vec<u8> =Vec::new();

    for (_, val) in signers.iter().enumerate() {
        total.extend_from_slice(val.as_bytes());
    }

    let mut total: Vec<u8> =Vec::new();

    for (_, val) in signers.iter().enumerate() {
        total.extend_from_slice(val.as_bytes());
    }

    let threshold = U256::from_str(req.threshold.as_str()).unwrap();
    total.extend_from_slice(&*threshold.encode());

    let signers_checksum = keccak256(&total);

    let mut state_root: Vec<u8> =Vec::new();

    state_root.extend_from_slice(signers_checksum.as_slice());

    let nonce = U256::from_str(req.nonce.as_str()).unwrap();
    state_root.extend_from_slice(&*nonce.encode());

    let state_root_hash = keccak256(&state_root);

    if  threshold.cmp(&U256::from(req.signatures.len())) == Ordering::Greater {
        return Err(Z0ValidationError::MissingSigners)
    }

    let message_hash = read_hex(req.message_hash.as_str()).unwrap();

    for (_, sig) in req.signatures.iter().enumerate() {
        let pos = signers.iter().position(|x| *x == sig.eoa).unwrap();
        let signature = Signature::from_str(&*sig.signature).unwrap();
        signature.verify(req.message_hash.as_str(), sig.eoa).unwrap();
        signers.remove(pos);

    }

    let  mut result: Vec<u8> = Vec::new();
    result.extend_from_slice(message_hash.as_slice());
    result.extend_from_slice(&state_root_hash[..]);

    return Ok(keccak256(result));
}


fn main() {
    // let raw: &mut [u8] = &mut [];
    // env::read_slice(raw);
    // println!("{}",str::from_utf8(raw).unwrap());
    let input = json!({"signers":["0x63f9725f107358c9115bc9d86c72dd5823e9b1e6","0x687f4304df62449dbc6c95fe9a8cb1153d40d42e","0x0f8361ef429b43fa48ac66a7cd8f619c517274f1"],"threshold":"0x0000000000000000000000000000000000000000000000000000000000000001","nonce":"0x0000000000000000000000000000000000000000000000000000000000000000","message_hash":"0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8","signatures":[{"eoa":"0x63f9725f107358c9115bc9d86c72dd5823e9b1e6","signature":"0xe10fd571394b8f0b166cbf0c50b2f37bb1d00d6e81b679d8b68794c3d64c2c1c39a7969109e71b33e506aa26b50bdd26166e52c7f46f20c08979162ab3d1ad9e1c"}]});
    let req: Z0Req = serde_json::from_slice(input.to_string().as_bytes()).unwrap();
    let result = generate_output(req).unwrap();
    env::commit_slice(&<FixedBytes<32>>::from_slice(result.as_slice()).abi_encode());
}