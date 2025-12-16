# syntax=docker/dockerfile:1

# ----------------------------
# 1) Build (Vite/React)
# ----------------------------
FROM node:20-alpine AS build
WORKDIR /app

# Narzędzia pod node-gyp (często konieczne na Alpine)
RUN apk add --no-cache python3 make g++ libc6-compat

# Cache warstw: najpierw tylko manifesty
COPY package.json ./
COPY package-lock.json* ./

# Jeśli masz problemy z peer deps, odkomentuj --legacy-peer-deps
RUN npm install --no-audit --no-fund
# RUN npm install --no-audit --no-fund --legacy-peer-deps

# Reszta kodu
COPY . .

# build-arg z docker-compose
ARG API_KEY
ENV VITE_API_KEY="${API_KEY}"

RUN npm run build

# ----------------------------
# 2) Runtime (Nginx)
# ----------------------------
FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
