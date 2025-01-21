import { SuiClient } from "@mysten/sui.js/client";
import { ADMIN_CAP, ADMIN_KEYPAIR, MINTER_PUB_KEY, PACKAGE_ID, SUI_FULLNODE_URL } from "../src/config";
import { createMintCap } from "../src/create-mintcap";

async function run() {
    const resp = await createMintCap({
        client: new SuiClient({ url: SUI_FULLNODE_URL }),
        adminSigner: ADMIN_KEYPAIR,
        adminCap: ADMIN_CAP,
        minterPubKey: MINTER_PUB_KEY
    });

    const mintCap = resp.objectChanges.find((oc) => {
        return oc.type === 'created' && oc.objectType === `${PACKAGE_ID}::mintcap::MintCap`;
    });
    console.log(mintCap);
}

run();

