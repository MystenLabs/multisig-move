// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
module multisig::multisig {
    use std::vector;
    use sui::tx_context::{Self, TxContext};
    use sui::address;
    use sui::bcs;
    use sui::hash::blake2b256;
    use sui::event;

    const ELengthsOfPksAndWeightsAreNotEqual: u64 = 0;
    const EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights: u64 = 1;

    struct MultisigAddressEvent has copy, drop {
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        multisig_address: address,
    }

    public fun create_multisig_address(
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
    ): address {
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
        vector::append(&mut hash_data, bcs::to_bytes(&threshold));

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

    public fun ed25519_key_to_address(
        pk: &vector<u8>,
    ): address {
        address_from_bytes(pk, 33, 0x00)
    }

    public fun secp256k1_key_to_address(
        pk: &vector<u8>,
    ): address {
        address_from_bytes(pk, 34, 0x01)
    }

    public fun secp256r1_key_to_address(
        pk: &vector<u8>,
    ): address {
        address_from_bytes(pk, 34, 0x02)
    }

    fun address_from_bytes(
        pk: &vector<u8>,
        length: u64,
        flag: u8,
    ): address {
        assert!(vector::length(pk) == length, 0);
        assert!(*vector::borrow(pk, 0) == flag, 1);
        address::from_bytes(sui::hash::blake2b256(pk))
    }

    public entry fun test_address(
        ctx: &mut TxContext
    )
    {
        // assert!(tx_context::sender(ctx) == @0x7377de949b910c4f204536c38883d3a1709d7758db2322b0438587a450df8a59, 0)
        assert!(tx_context::sender(ctx) == @0xa7536c86055012cb7753fdb08ecb6c8bf1eb735ad75a2e1980309070123d5ef6, 0)
    }
}

	// ED25519: 0x00,
	// Secp256k1: 0x01,
	// Secp256r1: 0x02,
	// MultiSig: 0x03,
	// ZkLogin: 0x05,