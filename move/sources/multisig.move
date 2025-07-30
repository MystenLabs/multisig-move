// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// # Multisig Address Generation and Verification Module
/// 
/// This module provides comprehensive functionality for working with multisig addresses on the Sui blockchain.
/// It enables the creation, verification, and validation of multi-signature addresses that require multiple
/// cryptographic signatures to authorize transactions.
/// 
/// ## Key Concepts:
/// - **Public Keys (pks)**: A vector of public keys from different signers
/// - **Weights**: Individual voting power assigned to each signer's public key
/// - **Threshold**: Minimum cumulative weight required to authorize a transaction
/// - **Multisig Address**: A deterministically derived address based on the above parameters
/// 
/// ## Supported Signature Schemes:
/// - Ed25519 (flag: 0x00)
/// - Secp256k1 (flag: 0x01) 
/// - Secp256r1 (flag: 0x02)
/// 
/// ## Address Derivation Algorithm:
/// The multisig address is derived using BLAKE2b-256 hash of:
/// 1. Multisig flag (0x03)
/// 2. BCS-serialized threshold (u16)
/// 3. For each signer: public_key || weight
module multisig::multisig;

use sui::address;
use sui::bcs;
use sui::event;
use sui::hash::blake2b256;
use sui::tx_context::TxContext;

// ===== Error Constants =====

/// Error: The number of public keys must equal the number of weights.
/// This ensures each signer has exactly one corresponding weight value.
const ELengthsOfPksAndWeightsAreNotEqual: u64 = 0;

/// Error: The threshold must be positive and not exceed the total sum of all weights.
/// A threshold of 0 would allow unauthorized transactions, while a threshold exceeding
/// the total weight would make the multisig unusable.
const EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights: u64 = 1;

/// Error: The public key length doesn't match the expected length for its type.
/// Ed25519: 33 bytes, Secp256k1/Secp256r1: 34 bytes (including scheme flag)
const EPublicKeyLength: u64 = 2;

/// Error: The public key's first byte doesn't match the expected signature scheme flag.
/// Expected flags: Ed25519 (0x00), Secp256k1 (0x01), Secp256r1 (0x02)
const EPublicKeyFlag: u64 = 3;

// ===== Events =====

/// Event emitted when a multisig address is derived using `derive_multisig_address()`.
/// This event provides transparency and allows off-chain services to track multisig creations.
/// 
/// # Fields
/// * `pks` - Vector of public keys used in the multisig
/// * `weights` - Corresponding weights for each public key
/// * `threshold` - Minimum weight required for authorization
/// * `multisig_address` - The computed multisig address
public struct MultisigAddressEvent has copy, drop {
    pks: vector<vector<u8>>,
    weights: vector<u8>,
    threshold: u16,
    multisig_address: address,
}

// ===== Public Functions =====

/// Validates whether the given parameters would generate the expected multisig address.
/// This is useful for verifying multisig configurations without emitting events.
/// 
/// # Parameters
/// * `pks` - Vector of public keys (each key includes the signature scheme flag)
/// * `weights` - Vector of weights corresponding to each public key
/// * `threshold` - Minimum cumulative weight required for transaction authorization
/// * `expected_address` - The address to compare against
/// 
/// # Returns
/// * `bool` - True if the derived multisig address matches the expected address
/// 
/// # Aborts
/// * `ELengthsOfPksAndWeightsAreNotEqual` - If pks and weights vectors have different lengths
/// * `EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights` - If threshold is 0 or exceeds total weight
/// 
/// # Example
/// ```move
/// let pks = vector[pk1, pk2, pk3];
/// let weights = vector[1, 2, 1]; // Total weight: 4
/// let threshold = 3; // Requires at least 3 weight units
/// let expected = @0x1234...;
/// let is_valid = check_multisig_address_eq(pks, weights, threshold, expected);
/// ```
public entry fun check_multisig_address_eq(
    pks: vector<vector<u8>>,
    weights: vector<u8>,
    threshold: u16,
    expected_address: address,
): bool {
    let ms_address = derive_multisig_address_quiet(pks, weights, threshold);
    return (ms_address == expected_address)
}

/// Derives a multisig address without emitting events.
/// This is the core algorithm for generating deterministic multisig addresses on Sui.
/// 
/// # Parameters
/// * `pks` - Vector of public keys from all signers (must include signature scheme flag)
/// * `weights` - Vector of weights assigned to each signer (must match pks length)
/// * `threshold` - Minimum cumulative weight required for authorization (1 ≤ threshold ≤ sum of weights)
/// 
/// # Returns
/// * `address` - The derived multisig address
/// 
/// # Algorithm
/// The address is computed as BLAKE2b-256 hash of the concatenated data:
/// 1. Multisig flag (0x03)
/// 2. BCS-serialized threshold (u16)
/// 3. For each signer: public_key || weight
/// 
/// # Aborts
/// * `ELengthsOfPksAndWeightsAreNotEqual` - If pks and weights vectors have different lengths
/// * `EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights` - If threshold is invalid
/// 
/// # Example
/// ```move
/// let pks = vector[ed25519_pk, secp256k1_pk];
/// let weights = vector[2, 3]; // Total weight: 5
/// let threshold = 4; // Requires both keys (2+3=5 > 4)
/// let address = derive_multisig_address_quiet(pks, weights, threshold);
/// ```
public fun derive_multisig_address_quiet(
    pks: vector<vector<u8>>,
    weights: vector<u8>,
    threshold: u16,
): address {
    // Multisig scheme identifier - distinguishes from single-sig addresses
    let multiSigFlag: u8 = 0x03;
    let mut hash_data = vector<u8>[];

    let pks_len = pks.length();
    let weights_len = weights.length();

    // Validate input parameters
    assert!(pks_len == weights_len, ELengthsOfPksAndWeightsAreNotEqual);

    // Calculate total weight and validate threshold
    let mut sum: u16 = 0;
    let mut i = 0;
    while (i < weights_len) {
        let w = weights[i] as u16;
        sum = sum + w;
        i = i + 1;
    };
    assert!(
        threshold > 0 && threshold <= sum,
        EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights,
    );

    // Build hash input: flag + threshold + (public_key + weight) pairs
    
    // Step 1: Add multisig flag
    hash_data.push_back(multiSigFlag);

    // Step 2: Add BCS-serialized threshold
    let threshold_bytes = bcs::to_bytes(&threshold);
    hash_data.append(threshold_bytes);

    // Step 3: Add each (public_key, weight) pair
    let mut i = 0;
    while (i < pks_len) {
        hash_data.append(pks[i]);
        hash_data.push_back(weights[i]);
        i = i + 1;
    };

    // Step 4: Compute final address using BLAKE2b-256
    let ms_address = address::from_bytes(blake2b256(&hash_data));
    ms_address
}

/// Derives a multisig address and emits an event with all parameters.
/// This function is identical to `derive_multisig_address_quiet` but also emits
/// a `MultisigAddressEvent` for transparency and off-chain tracking.
/// 
/// # Parameters
/// * `pks` - Vector of public keys from all signers
/// * `weights` - Vector of weights assigned to each signer  
/// * `threshold` - Minimum cumulative weight required for authorization
/// 
/// # Returns
/// * `address` - The derived multisig address
/// 
/// # Events
/// * `MultisigAddressEvent` - Contains all input parameters and the resulting address
/// 
/// # Aborts
/// * Same as `derive_multisig_address_quiet`
/// 
/// # Usage
/// Use this function when you want to create a multisig address and have the creation
/// logged on-chain for auditing or off-chain indexing purposes.
public fun derive_multisig_address(
    pks: vector<vector<u8>>,
    weights: vector<u8>,
    threshold: u16,
): address {
    let ms_address = derive_multisig_address_quiet(pks, weights, threshold);
    event::emit(MultisigAddressEvent {
        pks,
        weights,
        threshold,
        multisig_address: ms_address,
    });
    ms_address
}

/// Verifies if the current transaction sender is a multisig address with given parameters.
/// This function is useful in smart contracts that need to verify the sender's multisig status
/// and configuration before allowing certain operations.
/// 
/// # Parameters
/// * `pks` - Vector of public keys that should compose the sender's multisig
/// * `weights` - Vector of weights for each public key
/// * `threshold` - Expected threshold for the multisig
/// * `ctx` - Transaction context to get the sender address
/// 
/// # Returns
/// * `bool` - True if the sender matches the expected multisig configuration
/// 
/// # Example Use Cases
/// - Restricting function access to specific multisig configurations
/// - Implementing different authorization levels based on multisig parameters
/// - Validating that a caller meets minimum security requirements
/// 
/// # Example
/// ```move
/// public fun sensitive_operation(pks: vector<vector<u8>>, weights: vector<u8>, ctx: &mut TxContext) {
///     // Require 3-of-5 multisig with equal weights
///     assert!(check_if_sender_is_multisig_address(pks, vector[1,1,1,1,1], 3, ctx), EUNAUTHORIZED);
///     // ... perform sensitive operation
/// }
/// ```
public fun check_if_sender_is_multisig_address(
    pks: vector<vector<u8>>,
    weights: vector<u8>,
    threshold: u16,
    ctx: &mut TxContext,
): bool {
    check_multisig_address_eq(pks, weights, threshold, ctx.sender())
}

// ===== Public Key to Address Conversion Functions =====

/// Converts an Ed25519 public key to a Sui address.
/// Ed25519 is a modern elliptic curve signature scheme offering strong security guarantees.
/// 
/// # Parameters
/// * `pk` - Ed25519 public key (33 bytes: flag 0x00 + 32-byte key)
/// 
/// # Returns
/// * `address` - The corresponding Sui address
/// 
/// # Aborts
/// * `EPublicKeyLength` - If the key is not exactly 33 bytes
/// * `EPublicKeyFlag` - If the first byte is not 0x00 (Ed25519 flag)
/// 
/// # Format
/// The public key must be: [0x00][32-byte Ed25519 public key]
public fun ed25519_key_to_address(pk: &vector<u8>): address {
    address_from_bytes(pk, 33, 0x00)
}

/// Converts a secp256k1 public key to a Sui address.
/// Secp256k1 is the same elliptic curve used by Bitcoin and Ethereum.
/// 
/// # Parameters
/// * `pk` - Secp256k1 public key (34 bytes: flag 0x01 + 33-byte compressed key)
/// 
/// # Returns
/// * `address` - The corresponding Sui address
/// 
/// # Aborts
/// * `EPublicKeyLength` - If the key is not exactly 34 bytes
/// * `EPublicKeyFlag` - If the first byte is not 0x01 (secp256k1 flag)
/// 
/// # Format
/// The public key must be: [0x01][33-byte compressed secp256k1 public key]
public fun secp256k1_key_to_address(pk: &vector<u8>): address {
    address_from_bytes(pk, 34, 0x01)
}

/// Converts a secp256r1 (P-256) public key to a Sui address.
/// Secp256r1 is a NIST standard curve widely used in enterprise environments.
/// 
/// # Parameters
/// * `pk` - Secp256r1 public key (34 bytes: flag 0x02 + 33-byte compressed key)
/// 
/// # Returns
/// * `address` - The corresponding Sui address
/// 
/// # Aborts
/// * `EPublicKeyLength` - If the key is not exactly 34 bytes
/// * `EPublicKeyFlag` - If the first byte is not 0x02 (secp256r1 flag)
/// 
/// # Format
/// The public key must be: [0x02][33-byte compressed secp256r1 public key]
public fun secp256r1_key_to_address(pk: &vector<u8>): address {
    address_from_bytes(pk, 34, 0x02)
}

// ===== Private Helper Functions =====

/// Internal helper function to convert a public key to a Sui address.
/// This function validates the public key format and computes the address using BLAKE2b-256.
/// 
/// # Parameters
/// * `pk` - The public key including its signature scheme flag
/// * `length` - Expected total length of the public key (including flag)
/// * `flag` - Expected signature scheme flag (first byte of the key)
/// 
/// # Returns
/// * `address` - The computed Sui address
/// 
/// # Aborts
/// * `EPublicKeyLength` - If the public key length doesn't match expected length
/// * `EPublicKeyFlag` - If the signature scheme flag doesn't match expected flag
/// 
/// # Algorithm
/// 1. Validate key length matches the expected length for the signature scheme
/// 2. Validate the first byte matches the signature scheme flag
/// 3. Compute BLAKE2b-256 hash of the entire public key (flag + key data)
/// 4. Convert the hash to a Sui address
fun address_from_bytes(pk: &vector<u8>, length: u64, flag: u8): address {
    assert!(pk.length() == length, EPublicKeyLength);
    assert!(pk[0] == flag, EPublicKeyFlag);
    address::from_bytes(blake2b256(pk))
}
