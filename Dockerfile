# ---------- Build stage -------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

COPY package.json yarn.lock ./
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable

COPY . .

ARG NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
ARG NEXT_PUBLIC_MEDUSA_BACKEND_URL

# 1. Export vars at build time
ENV NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY}
ENV NEXT_PUBLIC_MEDUSA_BACKEND_URL=${NEXT_PUBLIC_MEDUSA_BACKEND_URL}
ENV SKIP_BUILD_STATIC_GENERATION=true

# 2. Inject env directly into the build step
RUN NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY} \
    NEXT_PUBLIC_MEDUSA_BACKEND_URL=${NEXT_PUBLIC_MEDUSA_BACKEND_URL} \
    SKIP_BUILD_STATIC_GENERATION=${SKIP_BUILD_STATIC_GENERATION} \
    yarn build

# ---------- Runtime stage ----------------------------------------------
FROM node:20-alpine
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

ENV NODE_ENV=production

COPY --from=build /app ./

EXPOSE 3000
CMD ["yarn", "start"]
