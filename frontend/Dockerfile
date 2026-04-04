# ------------------- Stage 1: Build ------------------------------
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Build the app (IMPORTANT)
RUN npm run build

# ------------------- Stage 2: Production ------------------------------
FROM nginx:alpine

# Copy only build files (VERY SMALL SIZE)
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
