# 🔐 Sui Multi-Signature Address Generator & Validator

A comprehensive Move module for creating, verifying, and working with multi-signature addresses on the Sui blockchain. This module enables secure collaborative asset management through deterministic address generation and sophisticated threshold-based authorization schemes.

## 🌟 Overview

Multi-signature (multisig) addresses are cryptographic constructs that require multiple cryptographic signatures to authorize transactions, enabling:

- **Enhanced Security**: Distributed key management reduces single points of failure
- **Collaborative Control**: Multiple parties can jointly manage shared assets
- **Flexible Governance**: Customizable voting weights and thresholds
- **Transparent Operations**: On-chain verification of multisig configurations

### Key Benefits

- **🛡️ Security**: Protection against unauthorized access and key compromise
- **🤝 Collaboration**: Enable DAO treasuries, joint ventures, and shared accounts
- **⚖️ Flexibility**: Support for various M-of-N configurations with weighted voting
- **🔍 Transparency**: On-chain verification and event emission for auditability

## 🏗️ Architecture

The module implements a deterministic address derivation algorithm using:

1. **BLAKE2b-256 Hashing**: Cryptographically secure address generation
2. **BCS Serialization**: Canonical encoding of threshold parameters
3. **Multi-Scheme Support**: Ed25519, secp256k1, and secp256r1 compatibility
4. **Weight-Based Voting**: Sophisticated authorization beyond simple M-of-N

### Address Derivation Formula

```
multisig_address = BLAKE2b-256(
    0x03 ||                    // Multisig flag
    BCS(threshold) ||          // Serialized threshold (u16)
    pk₁ || weight₁ ||          // First signer's key and weight
    pk₂ || weight₂ ||          // Second signer's key and weight
    ...                        // Additional signers
    pkₙ || weightₙ
)
```

## 🔧 Installation & Setup

### Prerequisites

- [Sui CLI](https://docs.sui.io/build/install) installed and configured
- Basic understanding of Move programming language

### Building the Module

1. **Clone and navigate to the project:**

   ```bash
   git clone <repository-url>
   cd multisig-move/move
   ```

2. **Build the module:**

   ```bash
   sui move build
   ```

3. **Run tests:**

   ```bash
   sui move test
   ```

4. **Publish to network:**
   ```bash
   sui client publish --gas-budget 20000000
   ```

## 📚 API Reference

### Core Functions

#### `derive_multisig_address(pks, weights, threshold) -> address`

Creates a multisig address and emits an event for transparency.

**Parameters:**

- `pks: vector<vector<u8>>` - Public keys (including signature scheme flags)
- `weights: vector<u8>` - Weight for each corresponding public key
- `threshold: u16` - Minimum weight required for authorization

**Returns:** The derived multisig address

**Events:** Emits `MultisigAddressEvent`

#### `derive_multisig_address_quiet(pks, weights, threshold) -> address`

Creates a multisig address without emitting events (gas-efficient).

#### `check_multisig_address_eq(pks, weights, threshold, expected) -> bool`

Validates whether given parameters produce the expected multisig address.

#### `check_if_sender_is_multisig_address(pks, weights, threshold, ctx) -> bool`

Verifies if the transaction sender matches the specified multisig configuration.

### Key Conversion Functions

#### `ed25519_key_to_address(pk) -> address`

Converts Ed25519 public key to Sui address.

- **Format:** `[0x00][32-byte Ed25519 key]` (33 bytes total)

#### `secp256k1_key_to_address(pk) -> address`

Converts secp256k1 public key to Sui address.

- **Format:** `[0x01][33-byte compressed secp256k1 key]` (34 bytes total)

#### `secp256r1_key_to_address(pk) -> address`

Converts secp256r1 public key to Sui address.

- **Format:** `[0x02][33-byte compressed secp256r1 key]` (34 bytes total)

## 🎯 Usage Examples

### Basic 2-of-3 Multisig

```move
module example::basic_multisig {
    use multisig::multisig;

    public fun create_2_of_3_multisig(): address {
        // Three public keys with equal weights
        let pks = vector[
            vector[0x00, /* 32 bytes Ed25519 key */],
            vector[0x01, /* 33 bytes secp256k1 key */],
            vector[0x02, /* 33 bytes secp256r1 key */]
        ];
        let weights = vector[1, 1, 1];  // Equal voting power
        let threshold = 2;              // Require any 2 signatures

        multisig::derive_multisig_address(pks, weights, threshold)
    }
}
```

### Weighted Multisig (Corporate Treasury)

```move
module example::corporate_treasury {
    use multisig::multisig;

    public fun create_corporate_multisig(): address {
        let pks = vector[
            ceo_key,        // CEO
            cfo_key,        // CFO
            board1_key,     // Board member 1
            board2_key,     // Board member 2
            board3_key      // Board member 3
        ];
        let weights = vector[3, 3, 1, 1, 1];  // Executives have more weight
        let threshold = 5;                     // Require 5 weight units

        // Possible authorization combinations:
        // - CEO + CFO (3 + 3 = 6 > 5) ✓
        // - CEO + any 2 board members (3 + 1 + 1 = 5) ✓
        // - CFO + any 2 board members (3 + 1 + 1 = 5) ✓
        // - All 3 board members alone (1 + 1 + 1 = 3 < 5) ✗

        multisig::derive_multisig_address(pks, weights, threshold)
    }
}
```

### Smart Contract Access Control

```move
module example::secure_vault {
    use sui::tx_context::TxContext;
    use multisig::multisig;

    // Error codes
    const EUNAUTHORIZED: u64 = 0;

    public fun withdraw_funds(
        amount: u64,
        admin_pks: vector<vector<u8>>,
        admin_weights: vector<u8>,
        ctx: &mut TxContext
    ) {
        // Require 3-of-5 admin multisig for withdrawals
        assert!(
            multisig::check_if_sender_is_multisig_address(
                admin_pks,
                admin_weights,
                3,
                ctx
            ),
            EUNAUTHORIZED
        );

        // Perform withdrawal logic...
    }
}
```

### Dynamic Authorization Levels

```move
module example::tiered_access {
    use sui::tx_context::TxContext;
    use multisig::multisig;

    const EINSUFFICIENT_AUTHORIZATION: u64 = 0;

    public fun execute_transaction(
        amount: u64,
        pks: vector<vector<u8>>,
        weights: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = ctx.sender();

        if (amount <= 1000) {
            // Small amounts: require 1-of-3
            assert!(
                multisig::check_multisig_address_eq(pks, weights, 1, sender),
                EINSUFFICIENT_AUTHORIZATION
            );
        } else if (amount <= 10000) {
            // Medium amounts: require 2-of-3
            assert!(
                multisig::check_multisig_address_eq(pks, weights, 2, sender),
                EINSUFFICIENT_AUTHORIZATION
            );
        } else {
            // Large amounts: require 3-of-3
            assert!(
                multisig::check_multisig_address_eq(pks, weights, 3, sender),
                EINSUFFICIENT_AUTHORIZATION
            );
        };

        // Execute transaction...
    }
}
```

## 🧪 Testing

The module includes comprehensive tests demonstrating all functionality:

```bash
# Run all tests
sui move test

# Run specific test
sui move test --filter test_derive_multisig_address
```

### Test Coverage

- ✅ Ed25519, secp256k1, secp256r1 key conversion
- ✅ Multisig address derivation with mixed key types
- ✅ Weight and threshold validation
- ✅ Event emission verification
- ✅ Error condition handling

## ⚠️ Error Handling

The module provides comprehensive error checking:

| Error Code | Constant                                               | Description                                            |
| ---------- | ------------------------------------------------------ | ------------------------------------------------------ |
| `0`        | `ELengthsOfPksAndWeightsAreNotEqual`                   | Public keys and weights vectors have different lengths |
| `1`        | `EThresholdIsPositiveAndNotGreaterThanTheSumOfWeights` | Threshold is 0 or exceeds total weight                 |
| `2`        | `EPublicKeyLength`                                     | Public key length doesn't match expected format        |
| `3`        | `EPublicKeyFlag`                                       | Public key signature scheme flag is invalid            |

### Common Pitfalls

1. **Mismatched Vector Lengths**: Ensure `pks` and `weights` have the same length
2. **Invalid Threshold**: Must be `1 ≤ threshold ≤ sum(weights)`
3. **Incorrect Key Format**: Include proper signature scheme flags
4. **Weight Overflow**: Ensure sum of weights fits in `u16`

## 🎮 Real-World Use Cases

### 1. DAO Treasury Management

```move
// 7-of-12 council multisig with equal voting power
let council_pks = vector[/* 12 council member keys */];
let council_weights = vector[1,1,1,1,1,1,1,1,1,1,1,1];
let threshold = 7;  // Require majority consensus
```

### 2. Escrow Services

```move
// 2-of-3 escrow: buyer, seller, arbitrator
let escrow_pks = vector[buyer_key, seller_key, arbitrator_key];
let escrow_weights = vector[1, 1, 1];
let threshold = 2;  // Any two parties can release funds
```

### 3. Family Trust Fund

```move
// Weighted family trust with guardian override
let family_pks = vector[parent1_key, parent2_key, guardian_key, child_key];
let family_weights = vector[2, 2, 5, 1];  // Guardian has veto power
let threshold = 4;  // Requires significant consensus
```

### 4. Multi-Department Corporate Approval

```move
// Department heads + CEO approval system
let dept_pks = vector[ceo_key, legal_key, finance_key, tech_key, hr_key];
let dept_weights = vector[4, 2, 2, 1, 1];  // CEO has significant weight
let threshold = 6;  // Requires CEO + others or broad consensus
```

## 🔗 Integration Guide

### Frontend Integration

```typescript
import { TransactionBlock } from "@mysten/sui.js";

// Create multisig address
const tx = new TransactionBlock();
tx.moveCall({
  target: `${PACKAGE_ID}::multisig::derive_multisig_address`,
  arguments: [
    tx.pure(publicKeys), // vector<vector<u8>>
    tx.pure(weights), // vector<u8>
    tx.pure(threshold), // u16
  ],
});
```

### Backend Validation

```typescript
// Verify multisig configuration
async function validateMultisigSender(
  provider: SuiClient,
  sender: string,
  publicKeys: number[][],
  weights: number[],
  threshold: number
): Promise<boolean> {
  const tx = new TransactionBlock();
  tx.moveCall({
    target: `${PACKAGE_ID}::multisig::check_multisig_address_eq`,
    arguments: [
      tx.pure(publicKeys),
      tx.pure(weights),
      tx.pure(threshold),
      tx.pure(sender),
    ],
  });

  const result = await provider.dryRunTransactionBlock({
    transactionBlock: tx,
  });
  return result.results?.[0]?.returnValues?.[0] === true;
}
```

## 🛡️ Security Considerations

- **Key Management**: Secure storage and distribution of private keys
- **Threshold Selection**: Balance security with operational efficiency
- **Weight Distribution**: Prevent single points of control
- **Regular Audits**: Periodically review multisig configurations
- **Upgrade Paths**: Plan for changing multisig requirements

## 📄 License

Copyright (c) Mysten Labs, Inc.  
SPDX-License-Identifier: Apache-2.0

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📞 Support

For questions or issues:

- Create an issue in the repository
- Join the [Sui Discord](https://discord.gg/sui)
- Check the [Sui Documentation](https://docs.sui.io)
