## Instructions

1. Run ../move/only_admin_transferable_mintcap/publish.sh to publish the package with its dependencies (multisig). publish.sh will also create an admin and a minter keypairs in your sui keystore.
2. Run ./scripts/new-shared-space.ts to create a `SharedSpace` object under the admin-minter multisig address.
3. Run ./scripts/new-mintcap.ts to create a `MintCap` object under the admin-minter multisig address.
4. Run ./scripts/mint.ts to mint an `EnEfTee` signing as minter under the multisig address.
