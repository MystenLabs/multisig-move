/// Module: example_mintcap
/// This is an example on how to have an owned capability object
/// that the one who uses it is different than the one who can transfer it.
module only_admin_transferable_mintcap::mintcap {

    use multisig::multisig;
    use multisig::shared_space::MemberProof;

    const ENotAuthorized: u64 = 0;

    public struct MintCap has key {
        id: UID,
        n_mints: u64
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    public struct AdminAuth has drop {}
    public struct MinterAuth has drop {}

    public struct EnEfTee has key, store {
        id: UID
    }

    fun init(ctx: &mut TxContext) {
        transfer::public_transfer(AdminCap { id: object::new(ctx) }, ctx.sender());
    }

    public fun new_mint_cap(_: &AdminCap, n_mints: u64, admin_pk: vector<u8>, minter_pk: vector<u8>, ctx: &mut TxContext) {
        let mut pks = vector::empty();
        // The order of the public keys pushed is important as we check below the index of the signature
        pks.push_back(admin_pk);
        pks.push_back(minter_pk);
        let mut weights = vector::empty();
        weights.push_back(1);
        weights.push_back(1);
        let addr = multisig::derive_multisig_address_quiet(pks, weights, 1);
        transfer::transfer(MintCap { id: object::new(ctx), n_mints }, addr);
    }

    // Called from multisig address
    // Uses MemberProof to create AdminAuth
    public fun authorize_admin(member_proof: MemberProof): AdminAuth {
        assert!(member_proof.indexes().contains(&0), ENotAuthorized);
        AdminAuth {}
    }

    public fun authorize_minter(member_proof: MemberProof): MinterAuth {
        assert!(member_proof.indexes().contains(&1), ENotAuthorized);
        MinterAuth {}
    }

    /// Even if MintCap is owned by 1-out-of-2 Multisig address, only Admin can update n_mints
    public fun update_n_mints(_: &AdminAuth, mint_cap: &mut MintCap, new_n_mints: u64) {
        mint_cap.n_mints = new_n_mints;
    }

    /// MintCap is owned by 1-out-of-2 Multisig address, but only Admin (1st pk) can transfer
    /// Note that `new_admin_pk` or `new_minter_pk` can be the same as the old ones
    public fun transfer(_: &AdminAuth, mint_cap: MintCap, new_admin_pk: vector<u8>, new_minter_pk: vector<u8>) {
        let mut pks = vector::empty();
        // The order of the public keys pushed is important as we check below the index of the signature
        pks.push_back(new_admin_pk);
        pks.push_back(new_minter_pk);
        let mut weights = vector::empty();
        weights.push_back(1);
        weights.push_back(1);
        let addr = multisig::derive_multisig_address_quiet(pks, weights, 1);
        transfer::transfer(mint_cap, addr);
    }

    /// MintCap is owned by 1-out-of-2 Multisig address, but only Minter (2nd pk) can mint
    public fun mint(_: &MinterAuth, mint_cap: &mut MintCap, ctx: &mut TxContext): EnEfTee {
        assert!(mint_cap.n_mints > 0, ENotAuthorized);
        mint_cap.n_mints = mint_cap.n_mints - 1;
        EnEfTee { id: object::new(ctx) }
    }
}
