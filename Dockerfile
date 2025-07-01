# ---------- Build stage -------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

COPY package.json yarn.lock ./
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable

COPY . .
RUN yarn build          # produces .next/ for production

# ---------- Runtime stage ----------------------------------------------
FROM node:20-alpine
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

ENV NODE_ENV=production

# Copy production artefacts + node_modules
COPY --from=build /app ./

EXPOSE 3000
CMD ["yarn","start"]
