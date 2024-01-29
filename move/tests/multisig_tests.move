// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module multisig::multisig_unit_tests {
    use multisig::multisig::{Self as ms};

    #[test]
    fun test_derive_multisig_address() {
        // ED25519
        let ed25519_address_: address = @0x73a6b3c33e2d63383de5c6786cbaca231ff789f4c853af6d54cb883d8780adc0;
        let ed25519_key: vector<u8> = vector[0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67, 101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117];
        assert!(ms::ed25519_key_to_address(&ed25519_key) == ed25519_address_, 0);

        // Secp256k1
        let secp256k1_address_: address = @0xd9607cd03428c904949572b51471e7a9f60019aeb9a3d7ee5e72921cab8e8be7;
        let secp256k1_key: vector<u8> = vector[1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145, 11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235, 43];
        assert!(ms::secp256k1_key_to_address(&secp256k1_key) == secp256k1_address_, 0);

        // Secp256r1
        let secp256r1_address: address = @0x600b1081644fe46f76da3bdc19f8743b9f04458516364374c7d82959e790c19e;
        let secp256r1_key: vector<u8> = vector[2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42, 76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180, 48];
        assert!(ms::secp256r1_key_to_address(&secp256r1_key) == secp256r1_address, 0);

        let pks: vector<vector<u8>> = vector[ed25519_key, secp256k1_key, secp256r1_key];
        let weights: vector<u8> = vector[1, 1, 1];
        let threshold: u16 = 2;

        let expected_multisig_address: address = @0x1c4dac7fb4c01a0c608db993711c451ad655a38b7f0a9571ff099f70090263a8;
        let derived_multisig_address: address = ms::derive_multisig_address(pks, weights, threshold);
        assert!(derived_multisig_address == expected_multisig_address, 0);
    }

    #[test]
    fun test_order_pks() {
        let ed25519_key: vector<u8> = vector[0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67, 101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117];
        let secp256k1_key: vector<u8> = vector[1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145, 11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235, 43];
        let secp256r1_key: vector<u8> = vector[2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42, 76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180, 48];

        let pks0: vector<vector<u8>> = vector[ed25519_key, secp256k1_key, secp256r1_key];
        let pks1: vector<vector<u8>> = vector[secp256k1_key, ed25519_key, secp256r1_key];
        let pks2: vector<vector<u8>> = vector[secp256r1_key, ed25519_key, secp256k1_key];
        let pks3: vector<vector<u8>> = vector[ed25519_key, secp256r1_key, secp256k1_key];
        let pks4: vector<vector<u8>> = vector[secp256k1_key, secp256r1_key, ed25519_key];
        let pks5: vector<vector<u8>> = vector[secp256r1_key, secp256k1_key, ed25519_key];

        let ordered_pks: vector<vector<u8>> = vector[ed25519_key, secp256k1_key, secp256r1_key];
        let weights: vector<u8> = vector[1, 1, 1];
        let threshold: u16 = 2;
        let multisig_address: address = @0x1c4dac7fb4c01a0c608db993711c451ad655a38b7f0a9571ff099f70090263a8;

        assert!(ms::order_pks(multisig_address, pks0, weights, threshold) == ordered_pks, 0);
        assert!(ms::order_pks(multisig_address, pks1, weights, threshold) == ordered_pks, 0);
        assert!(ms::order_pks(multisig_address, pks2, weights, threshold) == ordered_pks, 0);
        assert!(ms::order_pks(multisig_address, pks3, weights, threshold) == ordered_pks, 0);
        assert!(ms::order_pks(multisig_address, pks4, weights, threshold) == ordered_pks, 0);
        assert!(ms::order_pks(multisig_address, pks5, weights, threshold) == ordered_pks, 0);
    }

    #[test]
    #[expected_failure(abort_code = ms::ENoPermutationMatchesTheExpectedAddress)]
    fun test_failure_order_pks() {
        let ed25519_key: vector<u8> = vector[0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67, 101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117];
        let secp256k1_key: vector<u8> = vector[1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145, 11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235, 43];
        let secp256r1_key: vector<u8> = vector[2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42, 76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180, 48];

        let pks0: vector<vector<u8>> = vector[ed25519_key, secp256k1_key, secp256r1_key];
        let pks1: vector<vector<u8>> = vector[secp256k1_key, ed25519_key, secp256r1_key];
        let pks2: vector<vector<u8>> = vector[secp256r1_key, ed25519_key, secp256k1_key];
        let pks3: vector<vector<u8>> = vector[ed25519_key, secp256r1_key, secp256k1_key];
        let pks4: vector<vector<u8>> = vector[secp256k1_key, secp256r1_key, ed25519_key];
        let pks5: vector<vector<u8>> = vector[secp256r1_key, secp256k1_key, ed25519_key];

        let weights: vector<u8> = vector[1, 1, 1];
        let threshold: u16 = 2;
        let multisig_address: address = @0xCAFE;

        ms::order_pks(multisig_address, pks0, weights, threshold);
        ms::order_pks(multisig_address, pks1, weights, threshold);
        ms::order_pks(multisig_address, pks2, weights, threshold);
        ms::order_pks(multisig_address, pks3, weights, threshold);
        ms::order_pks(multisig_address, pks4, weights, threshold);
        ms::order_pks(multisig_address, pks5, weights, threshold);
    }
}
