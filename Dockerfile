# Stage 1: Build the React frontend
FROM node:22-alpine AS frontend-builder
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm ci

COPY frontend ./
RUN npm run build

# Stage 2: Build the Haskell backend
FROM haskell:9.6 AS backend-builder
WORKDIR /app/backend

# Retry apt-get up to 3 times to handle transient network failures
RUN apt-get update --fix-missing -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

COPY backend/haskell-to-sqlite.cabal ./
COPY LICENSE ./
RUN cabal update
RUN cabal build --only-dependencies -j4

COPY backend ./
RUN cabal install --installdir=/app/bin --install-method=copy

# Stage 3: Lightweight runtime
FROM debian:bullseye-slim
WORKDIR /app

RUN apt-get update -o Acquire::Retries=3 && \
    apt-get install -y --no-install-recommends \
    libsqlite3-0 \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=backend-builder /app/bin/flood-susceptibility /app/flood-susceptibility
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

EXPOSE 3000
CMD ["/app/flood-susceptibility"]