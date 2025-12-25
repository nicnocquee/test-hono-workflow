import { defineNitroPlugin } from "nitro/~internal/runtime/plugin";

// Singleton to ensure we only create one world instance
let worldInstance: any = null;
let worldStartPromise: Promise<void> | null = null;

const isServerless =
  process.env.NETLIFY ||
  process.env.AWS_LAMBDA_FUNCTION_NAME ||
  process.env.VERCEL;

async function ensureWorldStarted() {
  if (worldInstance) {
    return worldInstance;
  }

  if (worldStartPromise) {
    await worldStartPromise;
    return worldInstance;
  }

  worldStartPromise = (async () => {
    try {
      console.log("Initializing Redis World...");
      const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";

      const { createWorld } = await import("@workflow-worlds/redis");

      worldInstance = createWorld({
        redisUrl: REDIS_URL,
      });

      // Start the world with a timeout to prevent hanging in serverless
      const startPromise = worldInstance.start?.();
      if (startPromise) {
        // Use shorter timeout in serverless (3s) vs traditional server (10s)
        const timeout = isServerless ? 3000 : 10000;
        await Promise.race([
          startPromise,
          new Promise((_, reject) =>
            setTimeout(
              () =>
                reject(
                  new Error(`Redis connection timeout after ${timeout}ms`)
                ),
              timeout
            )
          ),
        ]);
      }

      console.log("Redis World initialized successfully");
    } catch (error) {
      console.error("Error initializing Redis World:", error);
      // Reset promise so we can retry
      worldStartPromise = null;
      throw error;
    }
  })();

  await worldStartPromise;
  return worldInstance;
}

export default defineNitroPlugin(async () => {
  // In serverless environments, start connection asynchronously without blocking
  // The connection will be awaited when the workflow API is first used
  if (isServerless) {
    console.log(
      "Serverless environment detected - initializing Redis asynchronously"
    );
    // Start in background, but don't block plugin initialization
    ensureWorldStarted().catch((error) => {
      console.error("Background Redis initialization failed:", error);
      // Will retry on first workflow call
    });
  } else {
    // Traditional server - block on initialization
    try {
      await ensureWorldStarted();
    } catch (error) {
      console.error("Failed to initialize Redis World:", error);
      // Continue anyway - will retry on first use
    }
  }
});

// Export the ensure function so it can be used by the workflow API if needed
export { ensureWorldStarted };
