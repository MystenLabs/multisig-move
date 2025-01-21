import { SuiClient } from "@mysten/sui.js/client";
import { ADMIN_CAP, ADMIN_KEYPAIR, MINTER_PUB_KEY, PACKAGE_ID, SUI_FULLNODE_URL } from "../src/config";
import { createSharedSpace } from "../src/create-shared-space";

async function run() {
    const resp = await createSharedSpace({
        client: new SuiClient({ url: SUI_FULLNODE_URL }),
        signers: [ADMIN_KEYPAIR],
        adminCap: ADMIN_CAP,
        pubKeys: [ADMIN_KEYPAIR.getPublicKey(), MINTER_PUB_KEY],
        weights: [1, 1],
        threshold: 1
    });

    const sharedSpace = resp.objectChanges.find((oc) => {
        return oc.type === 'created' && oc.objectType === `${PACKAGE_ID}::shared_space::SharedSpace`;
    });
    console.log(sharedSpace);
}

run();

