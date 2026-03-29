# Stage 1: Build the React frontend
FROM node:22-alpine AS frontend-builder
WORKDIR /app/frontend

COPY frontend/package*.json ./
RUN npm ci

COPY frontend ./
RUN npm run build

# Stage 2: Build the Haskell backend
FROM haskell:9.4 AS backend-builder
WORKDIR /app/backend

# Install native dependencies for sqlite-simple
RUN apt-get update && apt-get install -y libsqlite3-dev

# Copy cabal file and resolve dependencies first (for docker layer caching)
COPY backend/haskell-to-sqlite.cabal ./
RUN cabal update
RUN cabal build --only-dependencies -j4

# Copy all backend source files
COPY backend ./

# Build and install the binary to a predictable location
RUN cabal install --installdir=/app/bin --install-method=copy

# Stage 3: Create the lightweight runtime image
FROM debian:bullseye-slim
WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled executable from the backend builder stage
COPY --from=backend-builder /app/bin/flood-susceptibility /app/flood-susceptibility


# Copy the built frontend artifacts from the frontend builder stage
COPY --from=frontend-builder /app/frontend/dist /app/frontend/dist

# Render will use $PORT, default is 3000
EXPOSE 3000

# Run the backend
CMD ["/app/flood-susceptibility"]
