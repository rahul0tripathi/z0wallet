extern crate core;

use std::io::Read;
use std::net::TcpStream;
use std::str::FromStr;

use anyhow::Result;
use axum::{
    http::StatusCode,
    Json,
    Router, routing::{get, post},
};
use ethers_core::abi::AbiEncode;
use ethers_core::types::{H160, U256};
use ethers_core::types::Address;
use ethers_signers::{LocalWallet, Signer};
use futures;
use futures::executor::block_on;
use hexutil::{read_hex, to_hex};
use serde::{Deserialize, Serialize};

use apps::{BonsaiProver, EOASignature, ExecuteCall, Z0Req};
use methods::Z0_GENERATOR_ELF;

async fn gen_test_input() -> Z0Req {
    let message_hash = read_hex("0x8649d736c2af537facc35382d7e0d8503ed5f036fa5201a9186da1d4db189640").unwrap();
    let wallet: LocalWallet = "dcf2cbdd171a21c480aa7f53d77f31bb102282b3ff099c78e3118b37348c72f7"
        .parse::<LocalWallet>()
        .unwrap();
    let signature = wallet.sign_message(to_hex(message_hash.as_slice()).as_str()).await.unwrap();
    let threshold = U256::from_str("1").unwrap().encode();
    let nonce = U256::from_str("0").unwrap().encode();
    return Z0Req {
        signers: vec![H160::from_str("0x63f9725f107358c9115bc9d86c72dd5823e9b1e6").unwrap() as Address, H160::from_str("0x687f4304Df62449dBc6C95FE9A8cb1153d40D42e").unwrap() as Address, H160::from_str("0x0f8361eF429B43fA48aC66A7cD8F619C517274f1").unwrap() as Address],
        threshold: to_hex(threshold.as_slice()),
        nonce: to_hex(nonce.as_slice()),
        message_hash: to_hex(message_hash.as_slice()),
        signatures: vec![EOASignature {
            eoa: wallet.address(),
            signature: to_hex(signature.to_vec().as_slice()),
        }],
    };
}

fn read_body(mut stream: &TcpStream) {
    let mut buf = [0u8; 4096];
    match stream.read(&mut buf) {
        Ok(_) => {
            let req_str = String::from_utf8_lossy(&buf);
            println!("{}", req_str);
        }
        Err(e) => println!("Unable to read stream: {}", e),
    }
}

#[derive(Deserialize)]
struct GenerateProofRequest {
    wallet: Address,
    data: Z0Req,
    execute_call: ExecuteCall,
}

#[derive(Serialize)]
struct GenerateProofResponse {
    to: Address,
    post_state_digest: String,
    seal: String,
    error: String,
}

// basic handler that responds with a static string
async fn root() -> &'static str {
    "OK"
}


async fn generate_proof(
    Json(payload): Json<GenerateProofRequest>,
) -> (StatusCode, Json<GenerateProofResponse>) {
    let (journal, post_state_digest, seal) = BonsaiProver::mock(Z0_GENERATOR_ELF, payload.data).unwrap();
    let digest = post_state_digest.as_slice();
    println!("journal {} post state digest {} seal {}", to_hex(&*journal), to_hex(digest), to_hex(&*seal));

    let response = GenerateProofResponse {
        to: payload.wallet,
        post_state_digest: to_hex(digest),
        seal: to_hex(&*seal),
        error: "".to_string(),
    };

    (StatusCode::OK, Json(response))
}

async fn generate_test_input() -> (StatusCode, Json<Z0Req>) {
    let output = block_on(gen_test_input());

    return (StatusCode::OK, Json(output));
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();

    let app = Router::new()
        .route("/", get(root))
        .route("/generate", post(generate_proof))
        .route("/mock", get(generate_test_input));

    // run our app with hyper, listening globally on port 3000
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
    Ok(())
}
