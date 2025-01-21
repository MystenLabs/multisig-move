import { SuiClient, SuiObjectChange, SuiObjectRef, SuiTransactionBlockResponse, TransactionEffects } from '@mysten/sui.js/client';
import { Keypair, PublicKey } from '@mysten/sui.js/cryptography';
import { TransactionBlock } from '@mysten/sui.js/transactions';
import { PACKAGE_ID } from './config';
import { getSharedSpaceBCS } from './get-shared-space';
import { bcs, fromB64 } from '@mysten/bcs';
import { createMultisigPubKey } from './multisig';
import blake2 from 'blake2';

export async function mint(args: {
    client: SuiClient;
    minterSigner: Keypair;
    mintCap: SuiObjectRef;
    adminPubKey: PublicKey;

}) {
    const { client, minterSigner, mintCap, adminPubKey } = args;

    const multisigPubKey = await createMultisigPubKey({
        pubKeys: [adminPubKey, minterSigner.getPublicKey()],
        weights: [1, 1],
        threshold: 1,
    });
    
    const sharedSpace = await getSharedSpaceBCS({
        client,
        owner: multisigPubKey.toSuiAddress(),
    });

    let h = blake2.createHash('blake2b', { digestLength: 32 });
    h.update(Buffer.from(fromB64(sharedSpace.rawData.bcsBytes)));
    const signature = minterSigner.signData(h.digest());
    const signatures = bcs.vector(bcs.vector(bcs.u8())).serialize([Array.from(signature)]).toBytes();
    const txb = new TransactionBlock();

    const memberProof = txb.moveCall({
        target: `${PACKAGE_ID}::shared_space::proove_membership`,
        arguments: [
            txb.objectRef(sharedSpace.objectRef),
            txb.pure([1], 'vector<u8>'),
            txb.pure(signatures, 'vector<vector<u8>>'),
        ]
    });
    const mintAuth = txb.moveCall({
        target: `${PACKAGE_ID}::mintcap::authorize_minter`,
        arguments: [
            memberProof
        ]
    });

    const enEfTee = txb.moveCall({
        target: `${PACKAGE_ID}::mintcap::mint`,
        arguments: [
            mintAuth,
            txb.objectRef(mintCap),
        ]
    });

    txb.transferObjects([enEfTee], minterSigner.toSuiAddress());

    txb.setSender(multisigPubKey.toSuiAddress());
    txb.setGasOwner(minterSigner.toSuiAddress());

    const txBytes = await txb.build({
        client,
        // onlyTransactionKind /
    });

    const txSignature = (await minterSigner.signTransactionBlock(txBytes)).signature;
    const mutlisigSignature = multisigPubKey.combinePartialSignatures([txSignature]);

    const resp = await client.executeTransactionBlock({
        transactionBlock: txBytes,
        signature: [mutlisigSignature, txSignature],
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
