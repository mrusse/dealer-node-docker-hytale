# ==============================================================================
# Hytale Server Docker Image
# ==============================================================================
# Runs a Hytale game server with automatic updates via hytale-downloader.
#
# SECURITY: No credentials are stored in this image. All authentication
# tokens must be provided at runtime via environment variables.
# ==============================================================================

FROM eclipse-temurin:25-jdk-alpine

LABEL maintainer="Dealer Node <administration@dealernode.app>"
LABEL description="Hytale Game Server"
LABEL version="1.0.0"

# Install dependencies
RUN apk add --no-cache \
    curl \
    unzip \
    bash \
    jq \
    gcompat && \
    # some builds expect /lib64/ld-linux-x86-64.so.2
    if [ -e /lib/ld-linux-x86-64.so.2 ] && [ ! -e /lib64/ld-linux-x86-64.so.2 ]; then \
      ln -s /lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2; \
    fi

# Create non-root user for security
RUN addgroup -S hytale && adduser -S hytale -G hytale

# Create server directory
WORKDIR /server

# Download hytale-downloader CLI
RUN curl -fsSL -o hytale-downloader.zip "https://downloader.hytale.com/hytale-downloader.zip" && \
    unzip hytale-downloader.zip && \
    mv hytale-downloader-linux-amd64 hytale-downloader && \
    chmod +x hytale-downloader && \
    rm hytale-downloader.zip hytale-downloader-windows-amd64.exe QUICKSTART.md 2>/dev/null || true

# Create directories for persistent data
RUN mkdir -p /server/universe /server/mods /server/config && \
    chown -R hytale:hytale /server

# Copy entrypoint script
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Expose UDP port for QUIC protocol
EXPOSE 5520/udp

# Default environment variables (no secrets here!)
ENV SERVER_NAME="Hytale Server - (Dealer Node)"
ENV MAX_PLAYERS=10
ENV MEMORY_MB=4096
ENV AUTH_MODE=authenticated
ENV VIEW_DISTANCE=10

# Health check - verify server process is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -f "java.*HytaleServer\.jar" >/dev/null || exit 1

# Run as non-root user
USER hytale

ENTRYPOINT ["/entrypoint.sh"]`
and docker-compose.yml
`version: "3.8"

services:
  hytale:
    stdin_open: true
    tty: true
    image: hytale-server:local
    container_name: hytale-server
    ports:
      - "0.0.0.0:5520:5520/udp"
    environment:
      HYTALE_CREDENTIALS_JSON: '{}'
      SERVER_NAME: "My Hytale Server"
      MAX_PLAYERS: "5"
      MEMORY_MB: "14336"
      AUTH_MODE: "authenticated"
    volumes:
      - hytale-data:/server
    restart: unless-stopped

volumes:
  hytale-data:
