FROM node:22-alpine

RUN apk add --no-cache bash curl

WORKDIR /app

# Copy package files first for layer caching
COPY package*.json ./
RUN npm install

COPY . .
