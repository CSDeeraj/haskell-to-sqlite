# Stage 1: Build the Haskell application
FROM haskell:9.4 as builder

WORKDIR /app

# Install native dependencies for sqlite-simple
RUN apt-get update && apt-get install -y libsqlite3-dev

# Copy cabal file and resolve dependencies first (for docker layer caching)
COPY haskell-to-sqlite.cabal ./
RUN cabal update
RUN cabal build --only-dependencies -j4

# Copy all source files
COPY . .

# Build and install the binary to a predictable location
RUN cabal install --installdir=/app/bin --install-method=copy

# Stage 2: Create the lightweight runtime image
FROM debian:bullseye-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libsqlite3-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled executable from the builder stage
COPY --from=builder /app/bin/flood-susceptibility /app/flood-susceptibility

# Copy the SQLite database
# Note: Ensure flood_susceptibility.db is in the project root
COPY flood_susceptibility.db /app/

# Set the port (Render will use $PORT, this is for local reference)
EXPOSE 3000

# Run the backend
CMD ["/app/flood-susceptibility"]
