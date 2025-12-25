# Stage 1: Build stage
FROM node:22-slim AS builder

# Install build dependencies for native modules (needed for @swc/core)
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including dev dependencies for build)
# Use npm install to allow platform-specific package resolution
# This is necessary because package-lock.json may have been generated on a different platform
RUN npm install --include=optional

# Verify @swc/core has the correct platform binary installed
RUN node -e "try { require('@swc/core'); console.log('@swc/core loaded successfully'); } catch(e) { console.error('@swc/core failed:', e.message); process.exit(1); }"

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Stage 2: Production stage
FROM node:22-slim AS production

WORKDIR /app

# Copy the built output from builder stage
COPY --from=builder /app/.output ./

# Navigate to server directory and install production dependencies
WORKDIR /app/server

# Install production dependencies from Nitro's generated package.json
RUN npm ci --omit=dev --ignore-scripts || true

# Expose the port (adjust if your app uses a different port)
EXPOSE 3000

# Set environment to production
ENV NODE_ENV=production

# Required environment variables:
# - REDIS_URL: Redis connection URL (defaults to redis://localhost:6379 if not set)
#   Example: redis://localhost:6379 or redis://user:password@host:6379
# Optional environment variables (for serverless detection):
# - NETLIFY, AWS_LAMBDA_FUNCTION_NAME, VERCEL

# Run the built application
CMD ["node", "index.mjs"]

