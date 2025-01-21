import { SuiClient } from "@mysten/sui.js/client";
import { ADMIN_PUB_KEY, MINTER_KEYPAIR, MINTER_PUB_KEY, SUI_FULLNODE_URL } from "../src/config";
import { mint } from "../src/mint";
import { getMintCap } from "../src/get-mintcap";
import { createMultisigPubKey } from "../src/multisig";

async function run() {
    const client = new SuiClient({ url: SUI_FULLNODE_URL });

    const multisigPubKey = await createMultisigPubKey({
        pubKeys: [ADMIN_PUB_KEY, MINTER_PUB_KEY],
        weights: [1, 1],
        threshold: 1,
    });
    const mintCap = await getMintCap({
        client,
        owner: multisigPubKey.toSuiAddress(),
    });

    if (!mintCap) {
        throw new Error('MintCap not found');
    }

    const resp = await mint({
        client,
        minterSigner: MINTER_KEYPAIR,
        mintCap,
        adminPubKey: ADMIN_PUB_KEY,
    });
    console.log(resp);
}

run();


// async funct
