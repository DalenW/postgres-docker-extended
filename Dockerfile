# ============================================================================
# Build from official PostgreSQL 17 image
# ============================================================================
FROM postgres:17

RUN mkdir /tmp_pgvector

RUN apt-get update && apt-get upgrade -y

# Install build dependencies and PostGIS
RUN apt-get install -y --no-install-recommends \
       build-essential \
       git \
       ca-certificates \
       postgresql-server-dev-17 \
       postgresql-17-postgis-3 \
       postgresql-17-postgis-3-scripts \
       wget \
    && rm -rf /var/lib/apt/lists/*

# Build and install pgvector
RUN cd /tmp_pgvector \
    && git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install

# Install VectorChord
RUN cd /tmp \
    && wget https://github.com/tensorchord/VectorChord/releases/download/0.5.0/postgresql-17-vchord_0.5.0-1_amd64.deb \
    && apt-get update \
    && apt-get install -y ./postgresql-17-vchord_0.5.0-1_amd64.deb \
    && rm postgresql-17-vchord_0.5.0-1_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create initialization script for extensions
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL\n\
    CREATE EXTENSION IF NOT EXISTS postgis;\n\
    CREATE EXTENSION IF NOT EXISTS postgis_topology;\n\
    CREATE EXTENSION IF NOT EXISTS vector;\n\
    CREATE EXTENSION IF NOT EXISTS vchord CASCADE;\n\
EOSQL' > /docker-entrypoint-initdb.d/00-init-extensions.sh \
    && chmod +x /docker-entrypoint-initdb.d/00-init-extensions.sh

# Set PostgreSQL configuration for shared libraries
CMD ["postgres", "-c", "shared_preload_libraries=vchord,vector", "-c", "listen_addresses=*"]
