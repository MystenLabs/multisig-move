import pino from "pino";

export const logger = pino({
  name: "weather-oracle",
  level: "info",
});
