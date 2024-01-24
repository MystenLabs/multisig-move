// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This module contains functions for working with multisig addresses.
module multisig::multisig {
    use sui::address;
    use sui::bcs;
    use sui::event;
    use sui::hash::blake2b256;
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    /// Error code indicating that the lengths of public keys and weights are not equal.
    const ELengthsOfPksAndWeightsAreNotEqual: u64 = 0;

    /// Error code indicating that the threshold is positive and not greater than the sum of weights.
    const EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights: u64 = 1;

    /// Event emitted when a multisig address is created.
    struct MultisigAddressEvent has copy, drop {
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        multisig_address: address,
    }

    /// Creates a multisig address based on the provided public keys, weights, and threshold.
    /// Returns true if the created multisig address matches the expected address.
    public entry fun create_multisig_address_entry(
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        expected_address: address,
    ): bool {
        let ms_address = create_multisig_address(pks, weights, threshold);
        return (ms_address == expected_address)
    }

    /// Creates a multisig address.
    /// pks - The public keys of the signers.
    /// weights - The weights assigned to each signer.
    /// threshold - The minimum number of signers required to approve a transaction.
    /// Returns The multisig address.
    public fun create_multisig_address(
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
    ): address {
        // Define a u8 variable `multiSigFlag` and initialize it with the value 0x03.
        let multiSigFlag :u8 = 0x03;    // MultiSig: 0x03,
        let hash_data = vector::empty<u8>();

        let pks_len = vector::length(&pks);
        let weights_len = vector::length(&weights);

        // Check that the lengths of pks and weights are equal
        assert!(vector::length(&pks) == vector::length(&weights), ELengthsOfPksAndWeightsAreNotEqual);

        // Check that the threshold is positive and not greater than the sum of weights
        let sum: u16 = 0;
        let i = 0;
        while (i < weights_len) {
            let w = (*vector::borrow(&weights, i) as u16);
            sum = sum + w;
            i = i + 1;
        };
        assert!(threshold > 0 && threshold <= sum, EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights);

        // Update the hasher with the MultiSig flag, threshold, and public keys
        vector::push_back(&mut hash_data, multiSigFlag);
        // Serialized threshold and append to the hash_data vector.
        let threshold_bytes: vector<u8> = bcs::to_bytes(&threshold);
        vector::append(&mut hash_data, threshold_bytes);

        // Iterate over the `pks` and `weights` vectors and appends the elements to `hash_data`/
        let i = 0;
        while (i < pks_len) {
            let pk = vector::borrow(&pks, i);
            let w = vector::borrow(&weights, i);
            vector::append(&mut hash_data, *pk);
            vector::push_back(&mut hash_data, *w);
            i = i + 1;
        };

        let ms_address = address::from_bytes(blake2b256(&hash_data));
        event::emit(
            MultisigAddressEvent{
                pks,
                weights,
                threshold,
                multisig_address: ms_address,
            });
        ms_address
    }

    /// Checks if the sender of the transaction is a multisig address based on the provided public keys, weights, and threshold.
    /// Returns true if the sender is a multisig address.
    public fun check_if_sender_is_multisig_address(
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        ctx: &mut TxContext
    ): bool {
        let ms_address = create_multisig_address(pks, weights, threshold);
        return (ms_address == tx_context::sender(ctx))
    }

    /// Converts an Ed25519 public key to an address.
    /// pk - The Ed25519 public key.
    /// Returns The address.
    public fun ed25519_key_to_address(
        pk: &vector<u8>,
    ): address {
        address_from_bytes(pk, 33, 0x00)
    }

    /// Converts a secp256k1 public key to an address.
    /// pk - The secp256k1 public key.
    /// Returns The address.
    public fun secp256k1_key_to_address(
        pk: &vector<u8>,
    ): address {
        address_from_bytes(pk, 34, 0x01)
    }

    /// Converts a secp256r1 public key to an address.
    /// pk - The secp256r1 public key.
    /// Returns The address.
    public fun secp256r1_key_to_address(
        pk: &vector<u8>,
    ): address {
        address_from_bytes(pk, 34, 0x02)
    }

    /// Converts a public key to an address.
    /// pk - The public key.
    /// length - The expected length of the public key.
    /// flag - The flag indicating the type of public key.
    /// Returns The address.
    fun address_from_bytes(
        pk: &vector<u8>,
        length: u64,
        flag: u8,
    ): address {
        assert!(vector::length(pk) == length, 0);
        assert!(*vector::borrow(pk, 0) == flag, 1);
        address::from_bytes(sui::hash::blake2b256(pk))
    }

}
