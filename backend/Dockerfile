# Stage 1
FROM node:21 AS backend-builder

# setup the working dir
WORKDIR /app

# code
COPY package*.json ./

# packages install
RUN npm i

COPY . .

# Stage 2
FROM node:21-slim

# setup the working dir
WORKDIR /app

# copy the above stage as compressed
COPY --from=backend-builder /app .

COPY .env .env

# Port
EXPOSE 5555

# App
CMD ["npm", "start"]