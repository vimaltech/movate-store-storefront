###### Stage 1 ­— install dependencies #########################
FROM node:20-alpine AS deps

# 1 Enable Corepack and activate the Yarn version the project requests
RUN corepack enable && corepack prepare yarn@4.9.1 --activate

WORKDIR /app

# 2 Leverage Docker cache: copy manifest files first
COPY package.json yarn.lock ./

# 3 Yarn 4 syntax: immutable install fails if lockfile or node version drift
RUN yarn install --immutable

###### Stage 2 ­— build application ############################
FROM node:20-alpine AS builder
RUN corepack enable && corepack prepare yarn@4.9.1 --activate
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Backend build: compile TS + admin UI (adjust if you don’t need it)
RUN yarn build

###### Stage 3 ­— runtime image ################################
FROM node:20-alpine
RUN corepack enable && corepack prepare yarn@4.9.1 --activate
WORKDIR /app

ENV NODE_ENV=production
COPY --from=builder /app ./

EXPOSE 9000
CMD ["sh","-c","medusa migrations run && yarn start"]
