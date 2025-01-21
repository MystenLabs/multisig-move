/// Module: shared_space
module multisig::shared_space {
    use std::bcs;

    use sui::hash;
    use sui::ed25519;
    use sui::ecdsa_k1;
    use sui::ecdsa_r1;

    use multisig::multisig;

    const ED25519_FLAG: u8 = 0;
    const SECP256K1_FLAG: u8 = 1;
    const SECP256R1_FLAG: u8 = 2;

    const EInvalidMultisigDerivation: u64 = 0;
    const EInvalidSignature: u64 = 1;
    const ELengthMismatch: u64 = 2;
    const EPublicKeyFlagNotSupported: u64 = 3;

    public struct SharedSpace has key {
        id: UID,
        addr: address,
        counter: u64,
        pub_keys: vector<vector<u8>>,
        weights: vector<u8>,
        threshold: u16,
        n_members: u8
    }

    public struct MemberProof has drop {
        indexes: vector<u8>
    }

    public fun new_shared_space(
        pub_keys: vector<vector<u8>>, weights: vector<u8>, threshold: u16, ctx: &mut TxContext
    ) {
        let addr = ctx.sender();
        assert!(multisig::check_multisig_address_eq(pub_keys, weights, threshold, addr), EInvalidMultisigDerivation);
        let n_members = pub_keys.length() as u8;
        transfer::transfer(
            SharedSpace {
                id: object::new(ctx),
                addr,
                counter: 0,
                pub_keys,
                weights,
                threshold,
                n_members
            },
            addr
        );
    }

    /// Takes a SharedSpace object, along with the indexes and signatures of the public keys that have signed it.
    /// Verifies the signatures and returns a MemberProof verifying the participants that have signed the shared space.
    public fun proove_membership(shared_space: &mut SharedSpace, indexes: vector<u8>, signatures: vector<vector<u8>>): MemberProof {

        let (mut i, len) = (0, indexes.length());
        assert!(len == signatures.length(), ELengthMismatch);
        let serialized = bcs::to_bytes(shared_space);
        let msg = hash::blake2b256(&serialized);
        shared_space.counter = shared_space.counter + 1;

        while (i < len) {
            let index = indexes[i];
            // Explicitely copy the public key to not mess up the shared space
            let mut pub_key = copy shared_space.pub_keys[index as u64];
            let flag = pub_key.remove(0);
            if (flag == ED25519_FLAG) {
                assert!(ed25519::ed25519_verify(&signatures[i], &pub_key, &msg), EInvalidSignature);
            } else if (flag == SECP256K1_FLAG) {
                assert!(ecdsa_k1::secp256k1_verify(&signatures[i], &pub_key, &msg, 0), EInvalidSignature);
            } else if (flag == SECP256R1_FLAG) {
                assert!(ecdsa_r1::secp256r1_verify(&signatures[i], &pub_key, &msg, 0), EInvalidSignature);
            } else {
                assert!(false, EPublicKeyFlagNotSupported);
            };
            i = i + 1;
        };

        MemberProof {
            indexes
        }
    }

    public use fun member_proof_indexes as MemberProof.indexes;
    public fun member_proof_indexes(proof: &MemberProof): vector<u8> {
        proof.indexes
    }
}

