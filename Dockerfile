# ─────────────────────────────────────────────────────────────
# Stage 1 — Build
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS build
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# Install deps
COPY package.json yarn.lock ./
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable

# Copy source
COPY . .

# Build without static generation fetches
RUN NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY:-dev_key} \
    NEXT_PUBLIC_MEDUSA_BACKEND_URL=${NEXT_PUBLIC_MEDUSA_BACKEND_URL:-http://localhost:9000} \
    yarn build:ci          # <-- key change

# ─────────────────────────────────────────────────────────────
# Stage 2 — Runtime
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

ENV NODE_ENV=production

COPY --from=build /app ./

EXPOSE 3000
CMD ["yarn","start"]
