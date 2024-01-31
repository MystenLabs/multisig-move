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
    use multisig::utils;

    /// Error code indicating that the lengths of public keys and weights are not equal.
    const ELengthsOfPksAndWeightsAreNotEqual: u64 = 0;

    /// Error code indicating that the threshold is positive and not greater than the sum of weights.
    const EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights: u64 = 1;

    /// Error code indicating that no permutation matches the expected multisig address.
    const ENoPermutationMatchesTheExpectedAddress: u64 = 2;

    /// Event emitted when a multisig address is created.
    struct MultisigAddressEvent has copy, drop {
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        multisig_address: address,
    }

    /// Creates a multisig address based on the provided public keys, weights, and threshold.
    /// Returns true if the created multisig address matches the expected address.
    public entry fun check_multisig_address_eq(
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        expected_address: address,
    ): bool {
        let ms_address = derive_multisig_address_quiet(pks, weights, threshold);
        return (ms_address == expected_address)
    }

    /// Derives a multisig address. No events are emitted.
    /// pks - The public keys of the signers.
    /// weights - The weights assigned to each signer.
    /// threshold - The minimum amount of weight required for a valid approval.
    /// Returns The multisig address.
    public fun derive_multisig_address_quiet(
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
        assert!(pks_len == weights_len, ELengthsOfPksAndWeightsAreNotEqual);

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
        ms_address
    }

    /// Derives a multisig address, and emit an event with all the parameters.
    /// pks - The public keys of the signers.
    /// weights - The weights assigned to each signer.
    /// threshold - The minimum amount of weight required for a valid approval.
    /// Returns The multisig address.
    public fun derive_multisig_address(
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
    ): address {
        let ms_address = derive_multisig_address_quiet(pks, weights, threshold);
        event::emit(
            MultisigAddressEvent{
                pks,
                weights,
                threshold,
                multisig_address: ms_address,
            });
            let ms_address = derive_multisig_address_quiet(pks, weights, threshold);
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
        check_multisig_address_eq(pks, weights, threshold, tx_context::sender(ctx))        
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

    /// This function orders the public keys (pks) in all possible permutations and checks if the derived multisig address matches the expected multisig address.
    /// It takes the expected multisig address, a vector of public keys (pks), a vector of weights corresponding to the public keys, and a threshold value as input.
    /// The function returns the ordered public keys (pks) if a permutation matches the expected multisig address.
    /// If no permutation matches the expected multisig address, it aborts with an error.
    ///
    /// Parameters:
    /// - expected_ms_address: The expected multisig address to match.
    /// - pks: A vector of vectors containing the public keys.
    /// - weights: A vector of weights corresponding to the public keys.
    /// - threshold: The threshold value for multisig.
    ///
    /// Returns:
    /// - A vector of vectors containing the ordered public keys (pks) if a permutation matches the expected multisig address.
    ///
    /// Abort:
    /// - ENoPermutationMatchesTheExpectedAddress: If no permutation matches the expected multisig address.
    public fun order_pks(
        expected_ms_address: address,
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
    ): vector<vector<u8>> {
        // loop through all the permutations of the pks vector
        let perms = utils::permutations(&mut pks);
        let n = vector::length(&perms);
        let i = 0;
        while (i < n) {
            let perm: vector<vector<u8>> = *vector::borrow(&perms, i);
            let ms_address = derive_multisig_address_quiet(perm, weights, threshold);
            // check if the ms_address matches the expected one
            if (ms_address == expected_ms_address) {
                return perm
            };
            i = i + 1;
        };

        abort ENoPermutationMatchesTheExpectedAddress
    }

}
