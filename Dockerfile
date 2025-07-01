# ---------- Build stage -------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# 1. install deps
COPY package.json yarn.lock ./
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable

# 2. copy source
COPY . .

# 3. build‑time args we’ll forward from docker‑compose.yml
ARG NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_MEDUSA_BACKEND_URL

# 4. write the ONLY env vars the starter cares about
RUN printf '%s\n' \
  "NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY}" \
  "NEXT_PUBLIC_MEDUSA_BACKEND_URL=${NEXT_PUBLIC_MEDUSA_BACKEND_URL}" \
  "SKIP_BUILD_STATIC_GENERATION=true" \
  > .env

# 5. compile (reads .env automatically)
RUN yarn build

# ---------- Runtime stage ----------------------------------------------
FROM node:20-alpine
WORKDIR /app
RUN corepack enable && corepack prepare yarn@4.9.1 --activate
ENV NODE_ENV=production

COPY --from=build /app ./

EXPOSE 3000
CMD ["yarn","start"]
