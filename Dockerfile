# Stage 1: Build stage
FROM node:24 AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including dev dependencies for build)
# Use npm install to allow platform-specific package resolution
RUN npm install     

# Copy source files
COPY . .

ARG WORKFLOW_DEBUG
ARG REDIS_URL
ENV WORKFLOW_DEBUG=${WORKFLOW_DEBUG}
ENV REDIS_URL=${REDIS_URL}

# Build the application
RUN npm run build

# Expose the port (adjust if your app uses a different port)
EXPOSE 3000

# Run the built application
CMD ["node", "index.mjs"]

