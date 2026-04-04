# Stage 1: Build
FROM node:21-alpine AS builder

WORKDIR /app

COPY package*.json ./

# Only production deps
RUN npm install --omit=dev

COPY . .

# Stage 2: Production
FROM node:21-alpine

WORKDIR /app

# Sirf required files copy karo
COPY --from=builder /app .

COPY .env .env

EXPOSE 5555

CMD ["node", "index.js"]
