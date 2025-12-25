# Stage 1: Build stage
FROM node:24 AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including dev dependencies for build)
# Use npm install to allow platform-specific package resolution
RUN npm install --include=optional

# Copy source files
COPY . .

ARG WORKFLOW_DEBUG
ARG REDIS_URL
ENV WORKFLOW_DEBUG=${WORKFLOW_DEBUG}
ENV REDIS_URL=${REDIS_URL}

# Build the application
RUN npm run build

# Stage 2: Production stage
FROM node:24-slim AS production

WORKDIR /app

# Copy the built output from builder stage
COPY --from=builder /app/.output ./

# Navigate to server directory and install production dependencies
WORKDIR /app/server

# Install production dependencies from Nitro's generated package.json
RUN npm ci --omit=dev --ignore-scripts || true

COPY --from=builder /app/node_modules/.nitro ./node_modules/.nitro

# Expose the port (adjust if your app uses a different port)
EXPOSE 3000

ARG WORKFLOW_DEBUG
ARG REDIS_URL

# Set environment to production
ENV NODE_ENV=production
ENV WORKFLOW_DEBUG=${WORKFLOW_DEBUG}
ENV REDIS_URL=${REDIS_URL}

# Required environment variables:
# - REDIS_URL: Redis connection URL (defaults to redis://localhost:6379 if not set)
#   Example: redis://localhost:6379 or redis://user:password@host:6379
# Optional environment variables (for serverless detection):
# - NETLIFY, AWS_LAMBDA_FUNCTION_NAME, VERCEL

# Run the built application
CMD ["node", "index.mjs"]

