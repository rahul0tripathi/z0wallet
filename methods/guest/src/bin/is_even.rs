use std::str::FromStr;
use ethers_core::{types::{Signature, U256}, utils::{keccak256}};
use ethers_core::abi::{AbiEncode, encode, Token};
use ethers_core::types::Address;
use risc0_zkvm::guest::env;
use std::fmt;
use std::str;
use std::fmt::{Display, Formatter};
use ethers_core::utils::hex::ToHexExt;
use serde::{Serialize, Deserialize};
use alloy_primitives::{FixedBytes};
use alloy_sol_types::SolValue;
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
    threshold: u8,
    message_hash: [u8; 32],
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

    total.push(req.threshold);

    let state_root = keccak256(&total);

    if req.signatures.len() < req.threshold as usize {
        return Err(Z0ValidationError::MissingSigners)
    }

    for (_, sig) in req.signatures.iter().enumerate() {
        let pos = signers.iter().position(|x| *x == sig.eoa).unwrap();
        let signature = Signature::from_str(&*sig.signature).unwrap();
        signature.verify(req.message_hash.encode_hex(), sig.eoa).unwrap();
        signers.remove(pos);

    }

    let  mut result: Vec<u8> = Vec::new();
    result.extend_from_slice(&req.message_hash[..]);
    result.extend_from_slice(&state_root[..]);

    return Ok(keccak256(result));
}


fn main() {
    // let raw: &mut [u8] = &mut [];
    // env::read_slice(raw);
    // println!("{}",str::from_utf8(raw).unwrap());
    let input = json!({
        "signers"
    :["0x63f9725f107358c9115bc9d86c72dd5823e9b1e6","0x687f4304df62449dbc6c95fe9a8cb1153d40d42e","0x0f8361ef429b43fa48ac66a7cd8f619c517274f1"],"threshold":1,"message_hash":[28,138,255,149,6,133,194,237,75,195,23,79,52,114,40,123,86,217,81,123,156,148,129,39,49,154,9,167,163,109,234,200],"signatures":[{"eoa":"0x63f9725f107358c9115bc9d86c72dd5823e9b1e6","signature":"e10fd571394b8f0b166cbf0c50b2f37bb1d00d6e81b679d8b68794c3d64c2c1c39a7969109e71b33e506aa26b50bdd26166e52c7f46f20c08979162ab3d1ad9e1c"}]
    });
    let req: Z0Req = serde_json::from_slice(input.to_string().as_bytes()).unwrap();
    let result = generate_output(req).unwrap();
    env::commit_slice(&<FixedBytes<32>>::from_slice(result.as_slice()).abi_encode());
}