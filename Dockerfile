# ── Stage 1: install dependencies ─────────────────────────────
# Uses Alpine for a tiny base image
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package manifests first to leverage Docker layer caching
COPY package.json yarn.lock ./

# Install ALL deps (prod + dev) needed to build Next.js
RUN yarn install --frozen-lockfile


# ── Stage 2: build the Next.js app ───────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Bring in node_modules from previous stage
COPY --from=deps /app/node_modules ./node_modules

# Copy the rest of the source
COPY . .

# Build for production (creates .next/ directory)
RUN yarn build


# ── Stage 3: runtime container ───────────────────────────────
FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

# Copy only what is needed to run the app
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
# If you use next.config.js, copy it too:
COPY --from=builder /app/next.config.js ./next.config.js

EXPOSE 3000

# Next.js serves the production build with "next start"
CMD ["yarn", "start"]
