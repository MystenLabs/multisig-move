import { SuiClient, SuiObjectData } from "@mysten/sui.js/client";
import { PACKAGE_ID } from "./config";

export async function getMintCap(args: {
    client: SuiClient;
    owner: string;
}): Promise<SuiObjectData | null | undefined> {
    const { client, owner } = args;


    const mintCap = await client.getOwnedObjects({
        owner,
        filter:
            { StructType: `${PACKAGE_ID}::mintcap::MintCap` },
        limit: 1,
    });
    return mintCap.data.at(0)?.data;
}
