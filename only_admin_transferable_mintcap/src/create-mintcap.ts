import { SuiClient, SuiObjectChange, SuiObjectRef, SuiTransactionBlockResponse, TransactionEffects } from '@mysten/sui.js/client';
import { Keypair, PublicKey } from '@mysten/sui.js/cryptography';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { PACKAGE_ID } from './config';

    // public fun new_mint_cap(_: &AdminCap, n_mints: u64, admin_pk: vector<u8>, minter_pk: vector<u8>, ctx: &mut TxContext) {
export async function createMintCap(args: {
    client: SuiClient;
    adminSigner: Keypair;
    adminCap: string | SuiObjectRef;
    minterPubKey: PublicKey;
}) {
    const { client, adminSigner, adminCap, minterPubKey } = args;

    const txb = new TransactionBlock();
    const adminCapArg =
        typeof adminCap === 'string' ?
            txb.object(adminCap) :
            txb.objectRef(adminCap);

    txb.moveCall({
        target: `${PACKAGE_ID}::mintcap::new_mint_cap`,
        arguments: [
            adminCapArg,
            txb.pure.u64(10),
            txb.pure(Array.from(adminSigner.getPublicKey().toSuiBytes()), 'vector<u8>'),
            txb.pure(Array.from(minterPubKey.toSuiBytes()), 'vector<u8>'),
        ]
    });

    const resp = await client.signAndExecuteTransactionBlock({
        transactionBlock: txb,
        signer: adminSigner,
        options: {
            showEffects: true,
            showObjectChanges: true,
        },
        requestType: 'WaitForLocalExecution'
    }) as SuiTransactionBlockResponse & {
        effects: TransactionEffects,
        objectChanges: SuiObjectChange[]
    };

    return resp;
}
