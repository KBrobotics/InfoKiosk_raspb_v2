# syntax=docker/dockerfile:1

# ----------------------------
# 1) Build (Vite/React)
# ----------------------------
FROM node:20-alpine AS build

WORKDIR /app

# Najpierw lockfile + package.json dla cache warstw
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./

# Instalacja zależności zależnie od użytego lockfile
RUN if [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then corepack enable && pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm install; fi

# Kod źródłowy
COPY . .

# build-arg z docker-compose: API_KEY=...
ARG API_KEY

# Vite udostępnia w kodzie tylko zmienne z prefixem VITE_
# (czytane w aplikacji: import.meta.env.VITE_API_KEY)
ENV VITE_API_KEY="${API_KEY}"

# Build produkcyjny (Vite -> /app/dist)
RUN npm run build

# ----------------------------
# 2) Runtime (Nginx)
# ----------------------------
FROM nginx:1.27-alpine AS runtime

# Własny config Nginx (SPA routing + cache)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Wrzucamy zbudowane pliki
COPY --from=build /app/dist /usr/share/nginx/html

# (opcjonalnie) prosty healthcheck endpoint jest w nginx.conf (/healthz)
# HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
#   CMD wget -qO- http://127.0.0.1/healthz || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
