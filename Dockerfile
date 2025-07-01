############################################
# Stage 1 – deps                           #
############################################
FROM node:20-alpine AS deps

WORKDIR /app

# Enable Corepack + Yarn 4.9.1
RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# Copy manifest files
COPY package.json yarn.lock ./

# Force Yarn to produce node_modules
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable


############################################
# Stage 2 – build                          #
############################################
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# Copy deps + source
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the Next.js storefront
RUN yarn build


############################################
# Stage 3 – runtime                        #
############################################
FROM node:20-alpine

WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

ENV NODE_ENV=production

COPY --from=builder /app ./

EXPOSE 3000
CMD ["yarn","start"]
