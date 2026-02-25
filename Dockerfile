# ================================
# Build stage
# ================================
FROM swift:5.9-jammy as build

WORKDIR /build

# Copy package manifest first for dependency caching
COPY Package.swift .
COPY Sources ./Sources

# Build with optimizations
RUN swift build -c release --static-swift-stdlib

# ================================
# Runtime stage
# ================================
FROM ubuntu:jammy

RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libcurl4 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /build/.build/release/App .

EXPOSE 8080

ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
