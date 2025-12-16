# ---------- build stage ----------
FROM node:20-alpine AS build

WORKDIR /app

# Instalacja zależności (lepsze cache)
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./

# Wybierz menedżer po lockfile (npm domyślnie)
RUN if [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    else npm i; fi

# Kod źródłowy
COPY . .

# (opcjonalnie) klucze/build-time env do Vite:
# docker build --build-arg VITE_API_KEY=xxx .
ARG VITE_API_KEY
ENV VITE_API_KEY=${VITE_API_KEY}

# Build (Vite -> /app/dist)
RUN npm run build

# ---------- runtime stage ----------
FROM nginx:1.27-alpine

# Konfiguracja Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Statyki
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
