
# Multi-Sig Sui Address Creator / Checker Module

Multi-signature (multi-sig) wallets and accounts allow for enhanced key management by enabling either multiple parties to access shared assets under predefined conditions, or a single user to implement additional security measures. For example, a multi-sig wallet could be used to manage a decentralized autonomous organization’s (DAO) treasury, requiring consent from a certain percentage of members before executing transactions, or it could serve an individual seeking extra protection by distributing access across multiple devices or locations.

Sui native multi-sig wallets offer a plethora of applications. They can be used to create interactive game elements or commerce platforms that necessitate collective user actions for access. Establishing a user quorum or other conditions for access ensures that digital assets remain protected against unauthorized use by any individual key/member.

The Sui Move multi-sig smart contract detailed in this article confirms whether a Sui address is multi-sig and accommodates various key combinations, such as 2-of-3 or any M-of-N. Integrating multisig functionality directly into smart contracts, rather than through SDKs, provides distinct benefits. This method grants developers precise control over access and authorization within the contract’s logic, allowing them to stipulate specific conditions—like signatures from a designated subset of addresses—before permitting function execution. Such detailed control bolsters security by guarding against unsanctioned changes to the contract or asset transfers.

Incorporating multisig directly into smart contracts is pivotal for creating secure and resilient applications with adaptable governance models. This fosters a foundation of trust and cooperation within decentralized networks.

On-chain multisig is crucial because it offers transparency and verifiability in decentralized operations. It ensures that actions, such as executing smart contract functions, are only performed when they meet the agreed-upon criteria among stakeholders. For example, knowing if the caller of a smart contract function is a multi-sig address allows for the implementation of nuanced constraints. If a transaction is signed by 3 out of 5 members, up to 1,000 coins could be moved. Conversely, if only 1 out of 5 members signs, the transaction limit could be set to 100 coins. This flexibility in setting transaction thresholds based on the level of consensus provides a balance between security and functionality, making on-chain multisig an indispensable feature for collective asset management and decision-making in the blockchain space.

## Module Description
This Move language module, `multisig::multisig` provides a set of functions to generate and verify that a Sui blockchain account is a multi-signature address. The main function, `derive_multisig_address`, takes a set of public keys (pks), corresponding weights, and a threshold to generate a Sui blockchain address. This module is useful for scenarios where identifying the type of sender in Sui transactions is critical, such as verifying multi-signature schemes and their thresholds.

## Features
- **`derive_multisig_address`:** Generates a Sui blockchain address from multi-signature public keys.
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
   let multisig_address = multisig::multisig::derive_multisig_address(public_keys, weights, threshold);
   ```

## Example
```move
#[test_only]
module multisig::multisig_unit_tests {
    use multisig::multisig::{Self as ms};

    #[test]
    fun test_derive_multisig_address() {
        // ED25519
        let address_ED25519: address = @0x73a6b3c33e2d63383de5c6786cbaca231ff789f4c853af6d54cb883d8780adc0;
        let key_ED25519: vector<u8> = vector[0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67, 101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117];
        assert!(ms::ed25519_key_to_address(&key_ED25519) == address_ED25519, 0);

        // Secp256k1
        let address_Secp256k1: address = @0xd9607cd03428c904949572b51471e7a9f60019aeb9a3d7ee5e72921cab8e8be7;
        let key_Secp256k1: vector<u8> = vector[1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145, 11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235, 43];
        assert!(ms::secp256k1_key_to_address(&key_Secp256k1) == address_Secp256k1, 0);

        // Secp256r1
        let address_Secp256r1: address = @0x600b1081644fe46f76da3bdc19f8743b9f04458516364374c7d82959e790c19e;
        let key_Secp256r1: vector<u8> = vector[2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42, 76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180, 48];
        assert!(ms::secp256r1_key_to_address(&key_Secp256r1) == address_Secp256r1, 0);

        let pks: vector<vector<u8>> = vector[key_ED25519, key_Secp256k1, key_Secp256r1];
        let weights: vector<u8> = vector[1, 1, 1];
        let threshold: u16 = 2;

        let expected_multisig_address: address = @0x1c4dac7fb4c01a0c608db993711c451ad655a38b7f0a9571ff099f70090263a8;
        let derived_multisig_address: address = ms::derive_multisig_address(pks, weights, threshold);
        assert!(derived_multisig_address == expected_multisig_address, 0);
    }
}
```

## License
Copyright (c) Mysten Labs, Inc.  
SPDX-License-Identifier: Apache-2.0
