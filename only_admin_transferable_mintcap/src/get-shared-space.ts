import { RawData, SuiClient } from "@mysten/sui.js/client";
import { PACKAGE_ID } from "./config";
import { SuiObjectRef } from "@mysten/sui.js/dist/cjs/bcs";

namespace getSharedSpaceBCS {
    export type Args = {
        client: SuiClient;
        owner: string;
        objectId?: string;
    }
    export type Result = Promise<{
        objectRef: SuiObjectRef,
        rawData: Extract<RawData, { dataType: 'moveObject' }>
    }>
};

export async function getSharedSpaceBCS(args: getSharedSpaceBCS.Args): getSharedSpaceBCS.Result {
    const { client, owner, objectId } = args;

    const sharedSpace = await client.getOwnedObjects({
        owner,
        filter: objectId ?
            { ObjectId: objectId } :
            { StructType: `${PACKAGE_ID}::shared_space::SharedSpace` },
        limit: 1,
        options: {
            showBcs: true,
        },
    });
    const bcs = sharedSpace.data[0].data?.bcs;
    if (!bcs) {
        throw new Error("Shared space not found");
    }
    const rawData = bcs as Extract<RawData, { dataType: 'moveObject' }>;
    return {
        objectRef: sharedSpace.data[0].data!,
        rawData
    }
}
