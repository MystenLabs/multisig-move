import { Keypair, PublicKey } from "@mysten/sui.js/cryptography";
import { MultiSigPublicKey } from "@mysten/sui.js/multisig";
import _ from 'lodash';

export async function createMultisigPubKey(args: {
    pubKeys: PublicKey[];
    weights: number[];
    threshold: number;
}) {
    const { pubKeys, weights, threshold } = args;
    if (pubKeys.length !== weights.length || threshold === 0) {
        throw new Error("pubKeys and weights must have the same length");
    }

    const publicKeys: {
        publicKey: PublicKey;
        weight: number;
    }[] = _.zip(pubKeys, weights).map(([pubKey, weight]) => {
        return {
            publicKey: pubKey!,
            weight: weight!
        };
    });

    const multisigSigner = MultiSigPublicKey.fromPublicKeys({
        threshold,
        publicKeys,
    });
    return multisigSigner;
}

export function checkThreshold(args: {
    multisigPubKey: MultiSigPublicKey,
    signers: Keypair[]
}): boolean {
    const { multisigPubKey, signers } = args;
    let publicKeys = multisigPubKey.getPublicKeys();
    const sum = signers.reduce((acc, signer) => {
        const pubKey = publicKeys.find((pubKeyWithWeight) => pubKeyWithWeight.publicKey.equals(signer.getPublicKey()));
        if (!pubKey) {
            throw new Error("Signer not included in pubKeys");
        }
        return acc + pubKey.weight;
    }, 0);
    return sum >= multisigPubKey.getThreshold();
}
