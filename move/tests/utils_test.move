// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

#[test_only]
module multisig::utils_unit_tests {
    use std::vector;
    use multisig::utils;

    #[test]
    fun test_permutations() {
        let ed25519_key: vector<u8> = vector[0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67, 101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117];
        let secp256k1_key: vector<u8> = vector[1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145, 11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235, 43];
        let secp256r1_key: vector<u8> = vector[2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42, 76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180, 48];

        let pks: vector<vector<u8>> = vector[ed25519_key, secp256k1_key, secp256r1_key];
        let permutations: vector<vector<vector<u8>>> = utils::permutations(&mut pks);

        assert!(vector::length(&permutations) == 6, 0);
        assert!(*vector::borrow(&permutations, 0) == vector[ed25519_key, secp256k1_key, secp256r1_key], 0);
        assert!(*vector::borrow(&permutations, 1) == vector[secp256k1_key, ed25519_key, secp256r1_key], 0);
        assert!(*vector::borrow(&permutations, 2) == vector[secp256r1_key, ed25519_key, secp256k1_key], 0);
        assert!(*vector::borrow(&permutations, 3) == vector[ed25519_key, secp256r1_key, secp256k1_key], 0);
        assert!(*vector::borrow(&permutations, 4) == vector[secp256k1_key, secp256r1_key, ed25519_key], 0);
        assert!(*vector::borrow(&permutations, 5) == vector[secp256r1_key, secp256k1_key, ed25519_key], 0);
    }
}