// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This module contains functions for working with multisig addresses.
module multisig::multisig {
    use sui::address;
    use sui::bcs;
    use sui::event;
    use sui::hash::blake2b256;

    /// Error code indicating that the lengths of public keys and weights are not equal.
    const ELengthsOfPksAndWeightsAreNotEqual: u64 = 0;

    /// Error code indicating that the threshold is positive and not greater than the sum of weights.
    const EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights: u64 = 1;

    const EPublicKeyLength: u64 = 2;
    const EPublicKeyFlag: u64 = 3;

    /// Event emitted when a multisig address is created.
    public struct MultisigAddressEvent has copy, drop {
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
        let mut hash_data = vector<u8>[];

        let pks_len = pks.length();
        let weights_len = weights.length();

        // Check that the lengths of pks and weights are equal
        assert!(pks_len == weights_len, ELengthsOfPksAndWeightsAreNotEqual);

        // Check that the threshold is positive and not greater than the sum of weights
        let mut sum: u16 = 0;
        let mut i = 0;
        while (i < weights_len) {
            let w = weights[i] as u16;
            sum = sum + w;
            i = i + 1;
        };
        assert!(threshold > 0 && threshold <= sum, EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights);

        // Update the hasher with the MultiSig flag, threshold, and public keys
        hash_data.push_back(multiSigFlag);

        // Serialized threshold and append to the hash_data vector.
        let threshold_bytes = bcs::to_bytes(&threshold);
        hash_data.append(threshold_bytes);

        // Iterate over the `pks` and `weights` vectors and appends the elements to `hash_data`/
        let mut i = 0;
        while (i < pks_len) {
            hash_data.append(pks[i]);
            hash_data.push_back(weights[i]);
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
        check_multisig_address_eq(pks, weights, threshold, ctx.sender())        
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
        assert!(pk.length() == length, EPublicKeyLength);
        assert!(pk[0] == flag, EPublicKeyFlag);
        address::from_bytes(blake2b256(pk))
    }

}
