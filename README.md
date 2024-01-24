
# Multi-Sig Sui Address Creator / Checker Module

## Description
This Move language module, `multisig::multisig` provides a set of functions to generate a Sui blockchain address from multi-signature public keys. The main function, `create_multisig_address`, takes a set of public keys (pks), corresponding weights, and a threshold to generate a Sui blockchain address. This module is useful for scenarios where identifying the type of sender in Sui transactions is critical, such as verifying multi-signature schemes and their thresholds.

## Features
- **`create_multisig_address`:** Generates a Sui blockchain address from multi-signature public keys.
- **`ed25519_key_to_address`, `secp256k1_key_to_address`, `secp256r1_key_to_address`:** Functions to create addresses from different types of public keys.
- **`test_address`:** A test function to validate the module in a transaction context.

## Usage
### Creating a Multi-Sig Address
1. **Prepare Public Keys and Weights:**
   Format your public keys and weights as vectors. Ensure they are of equal length.

   Example: 
   ```move
   let public_keys: vector<vector<u8>> = ...;
   let weights: vector<u8> = ...;
   ```
2. **Set the Threshold:**
   Define the threshold value necessary for the multi-signature.

3. **Call the Function:**
   ```move
   let multisig_address = multisig::multisig::create_multisig_address(public_keys, weights, threshold);
   ```

## Example
```move
#[test_only]
module multisig::multisig_unit_tests {
    use multisig::multisig::{Self as ms};

    #[test]
    fun test_create_multisig_address() {
        // ED25519
        let _address1: address = @0x73a6b3c33e2d63383de5c6786cbaca231ff789f4c853af6d54cb883d8780adc0;
        let key1: vector<u8> = vector[0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67, 101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117];

        // Secp256k1
        let _address2: address = @0xd9607cd03428c904949572b51471e7a9f60019aeb9a3d7ee5e72921cab8e8be7;
        let key2: vector<u8> = vector[1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145, 11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235, 43];

        // Secp256r1
        let _address3: address = @0x600b1081644fe46f76da3bdc19f8743b9f04458516364374c7d82959e790c19e;
        let key3: vector<u8> = vector[2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42, 76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180, 48];

        let pks: vector<vector<u8>> = vector[key1, key2, key3];
        let weights: vector<u8> = vector[1, 1, 1];
        let threshold: u16 = 2;

        let multisig_address: address = @0x1c4dac7fb4c01a0c608db993711c451ad655a38b7f0a9571ff099f70090263a8;
        let create_multisig_address: address = ms::create_multisig_address(pks, weights, threshold);
        assert!(create_multisig_address == multisig_address, 0);
    }
}
```

## License
Copyright (c) Mysten Labs, Inc.  
SPDX-License-Identifier: Apache-2.0
