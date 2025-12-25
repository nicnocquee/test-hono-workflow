import { defineConfig } from "nitro";
export default defineConfig({
  modules: ["workflow/nitro"],
  plugins: ["./src/plugins/start-redis-world.ts"],
  routes: {
    "/**": "./src/index.ts",
  },
});
