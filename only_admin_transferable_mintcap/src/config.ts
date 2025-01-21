import 'dotenv/config';
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519';
import { Secp256r1Keypair } from '@mysten/sui.js/keypairs/secp256r1';
import { Secp256k1Keypair } from '@mysten/sui.js/keypairs/secp256k1';
import { Keypair } from '@mysten/sui.js/cryptography';
import { fromB64 } from '@mysten/bcs';
import { execSync } from 'child_process';
import { readFileSync } from 'fs';

// From .env
export const SUI_FULLNODE_URL = process.env.SUI_FULLNODE_URL!;
export const PACKAGE_ID = process.env.PACKAGE_ID!;
export const ADMIN_CAP = process.env.ADMIN_CAP!;

// Parse admin, minter secret keys and create keypairs
function toKeypair(secretKey: Uint8Array): Keypair {
    let signer: Keypair;
    if (secretKey[0] === 0) {
        signer = Ed25519Keypair.fromSecretKey(
            secretKey
                .slice(1)
        );
    } else if (secretKey[0] === 1) {
        signer = Secp256k1Keypair.fromSecretKey(
            secretKey
                .slice(1)
        );
    } else if (secretKey[0] === 2) {
        signer = Secp256r1Keypair.fromSecretKey(
            secretKey
                .slice(1)
        );
    } else {
        throw new Error(`Unknown key scheme: ${secretKey[0]}`);
    }
    return signer;
}

const addresses = JSON.parse(execSync('sui client addresses --json').toString()) as {
    activeAddress: string;
    // list of 2 strings
    addresses: string[][];
};

//
const adminIndex = addresses.addresses.findIndex(([name, _]) => name === 'admin');
const minterIndex = addresses.addresses.findIndex(([name, _]) => name === 'minter');

console.log("DANGER! Reading ~/.sui/sui_config/sui.keystore. Do not use this in production.");
const secretKeys = JSON.parse(readFileSync(`${process.env.HOME}/.sui/sui_config/sui.keystore`).toString());

export const ADMIN_KEYPAIR = toKeypair(fromB64(secretKeys[adminIndex]));
export const MINTER_KEYPAIR = toKeypair(fromB64(secretKeys[minterIndex]));
export const ADMIN_PUB_KEY = ADMIN_KEYPAIR.getPublicKey();
export const MINTER_PUB_KEY = MINTER_KEYPAIR.getPublicKey();

if (ADMIN_KEYPAIR.toSuiAddress() != addresses.addresses[adminIndex][1]) {
    throw new Error("Admin keypair does not match address");
}
if (MINTER_KEYPAIR.toSuiAddress() != addresses.addresses[minterIndex][1]) {
    throw new Error("Minter keypair does not match address");
}

