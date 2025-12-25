# Stage 1: Build stage
FROM node:22-slim AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci

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

