# Base stage
FROM node:18-alpine AS base
WORKDIR /app
RUN npm i -g pnpm

# Dependency installation stage
FROM base AS install
WORKDIR /app
COPY package.json pnpm-lock.yaml .
RUN pnpm install

# Build stage (project compilation)
FROM install AS build
COPY . .
RUN pnpm build

# Production stage -------------------------------------
FROM base AS production

WORKDIR /app

COPY --from=build /app/.next ./.next
COPY --from=build /app/next.config.mjs ./next.config.mjs
COPY --from=build /app/public ./public

COPY --from=install /app/node_modules ./node_modules
COPY --from=install /app/package.json ./package.json

# Note: Don't expose ports here, Compose will handle that for us
CMD ["pnpm", "start"]

# Development stage -------------------------------
FROM install AS development
WORKDIR /app
COPY . .

# Note: Don't expose ports here, Compose will handle that for us
CMD ["pnpm", "dev"]