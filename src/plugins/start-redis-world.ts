import { defineNitroPlugin } from "nitro/~internal/runtime/plugin";
export default defineNitroPlugin(async () => {
  // Dynamic import to avoid edge runtime bundling issues
  console.log("Starting Redis World...");
  const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

  const { createWorld } = await import("@workflow-worlds/redis");

  console.log(`Gonna call createWorld with ${REDIS_URL}`);
  const world = createWorld({
    redisUrl: REDIS_URL,
  });

  try {
    await world.start?.();
    console.log("Redis World started");
  } catch (error) {
    console.error("Error starting Redis World", error);
  }
});
