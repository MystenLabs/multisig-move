import pino from "pino";

export const logger = pino({
  name: "multisig",
  level: "info",
});
