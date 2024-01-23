
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
let public_keys = vec![vec![1u8, 2u8, 3u8], vec![4u8, 5u8, 6u8]];
let weights = vec![1u8, 2u8];
let threshold = 2u16;

let address = multisig::multisig::create_multisig_address(public_keys, weights, threshold);
```

## License
Copyright (c) Mysten Labs, Inc.  
SPDX-License-Identifier: Apache-2.0
