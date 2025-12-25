import { defineConfig } from "nitro";
export default defineConfig({
  preset: "netlify",
  modules: ["workflow/nitro"],
  plugins: ["./src/plugins/start-redis-world.ts"],
  routes: {
    "/**": "./src/index.ts",
  },
  // By default, Nitro will not bundle node_modules packages
  // This ensures @workflow-worlds/redis remains as ESM in node_modules
  // The issue is that @workflow/core uses require() internally
  // We need to ensure the build output can handle this
});
