import { TransactionBlock } from "@mysten/sui.js/transactions";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { SuiClient } from "@mysten/sui.js/client";
import * as dotenv from "dotenv";
import { logger } from "./utils/logger";

(async () => {
  dotenv.config({ path: "../.env" });

  const phrase = process.env.ADMIN_PHRASE;
  const keypair = Ed25519Keypair.deriveKeypair(phrase!);

  // Client
  const fullnode = process.env.FULLNODE!;
  const client = new SuiClient({
    url: fullnode,
  });

  const packageId = process.env.PACKAGE_ID;
  const moduleName = "multisig";

  let transactionBlock = new TransactionBlock();

  // ED25519
  const key1 = [
    0, 13, 125, 171, 53, 140, 141, 173, 170, 78, 250, 0, 73, 167, 91, 7, 67,
    101, 85, 177, 10, 54, 130, 25, 187, 104, 15, 112, 87, 19, 73, 215, 117,
  ];
  // Secp256k1
  let key2 = [
    1, 2, 14, 23, 205, 89, 57, 228, 107, 25, 102, 65, 150, 140, 215, 89, 145,
    11, 162, 87, 126, 39, 250, 115, 253, 227, 135, 109, 185, 190, 197, 188, 235,
    43,
  ];
  // Secp256r1
  let key3 = [
    2, 3, 71, 251, 175, 35, 240, 56, 171, 196, 195, 8, 162, 113, 17, 122, 42,
    76, 255, 174, 221, 188, 95, 248, 28, 117, 23, 188, 108, 116, 167, 237, 180,
    48,
  ];

  transactionBlock.moveCall({
    target: `${packageId}::${moduleName}::create_multisig_address`,
    arguments: [
      transactionBlock.pure([key1, key2, key3], "vector<vector<u8>>"), // pks: vector<vector<u8>>
      transactionBlock.pure([1, 1, 1], "vector<u8>"), // weights: vector<u8>
      transactionBlock.pure(2), // threshold: u16
    ],
  });

  try {
    await client.signAndExecuteTransactionBlock({
      transactionBlock: transactionBlock,
      signer: keypair,
    });
  } catch (e) {
    logger.error(e);
  }
})();
