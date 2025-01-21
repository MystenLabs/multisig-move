import { SuiClient, SuiObjectChange, SuiObjectRef, SuiTransactionBlockResponse, TransactionEffects } from '@mysten/sui.js/client';
import { Keypair, PublicKey } from '@mysten/sui.js/cryptography';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { bcs } from '@mysten/bcs';
import { PACKAGE_ID } from './config';
import { checkThreshold, createMultisigPubKey } from './multisig';

// Sponsor will be the first signer
export async function createSharedSpace(args: {
    client: SuiClient;
    signers: Keypair[];
    adminCap: string | SuiObjectRef;
    pubKeys: PublicKey[];
    weights: number[];
    threshold: number;
}) {
    const { client, signers, pubKeys, weights, threshold } = args;

    const multisigPubKey = await createMultisigPubKey({
        pubKeys,
        weights,
        threshold,
    });
    if (!checkThreshold({multisigPubKey, signers})) {
        throw new Error('Threshold not met');
    }

    const txb = new TransactionBlock();

    const pubKeysRaw = bcs.vector(bcs.vector(bcs.u8())).serialize(pubKeys.map((pubKey) => Array.from(pubKey.toSuiBytes()))).toBytes();
    txb.moveCall({
        target: `${PACKAGE_ID}::shared_space::new_shared_space`,
        arguments: [
            txb.pure(pubKeysRaw, 'vector<vector<u8>>'),
            txb.pure(weights, 'vector<u8>'),
            txb.pure(threshold, 'u16'),
        ]
    });

    txb.setSender(multisigPubKey.toSuiAddress());
    txb.setGasOwner(signers[0].toSuiAddress());

    const txBytes = await txb.build({
        client,
        // onlyTransactionKind /
    });

    const signatures = await Promise.all(signers.map(async (signer) => (await signer.signTransactionBlock(txBytes)).signature));
    const mutlisigSignature = multisigPubKey.combinePartialSignatures(signatures);

    const resp = await client.executeTransactionBlock({
        transactionBlock: txBytes,
        signature: [mutlisigSignature, (await signers[0].signTransactionBlock(txBytes)).signature],
        options: {
            showEffects: true,
            showObjectChanges: true,
        },
        requestType: 'WaitForLocalExecution',
    }) as SuiTransactionBlockResponse & {
        effects: TransactionEffects,
        objectChanges: SuiObjectChange[]
    };

    return resp;
}



