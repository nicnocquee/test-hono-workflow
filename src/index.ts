import { Hono } from "hono";
import { start } from "workflow/api";
import { handleUserSignup } from "./workflows/user-signup.js";
import { ensureWorldStarted } from "./plugins/start-redis-world.js";

const app = new Hono();

// Middleware to ensure Redis world is ready before handling requests
app.use("*", async (c, next) => {
  try {
    await ensureWorldStarted();
  } catch (error) {
    console.error("Failed to ensure Redis world is ready:", error);
    // Continue anyway - workflow system might handle it
  }
  await next();
});

app.post("/api/signup", async (c) => {
  const { email } = await c.req.json();
  await start(handleUserSignup, [email]);
  return c.json({ message: "User signup workflow started" });
});
export default app;
