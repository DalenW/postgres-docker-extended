# ============================================================================
# Build from official PostgreSQL 17 image
# ============================================================================
FROM postgres:17

# Set environment variables to ensure we use the correct PostgreSQL installation
ENV PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config
ENV PATH=/usr/lib/postgresql/17/bin:$PATH

RUN mkdir /tmp_pgvector
RUN mkdir /tmp_vectorchord

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

# Verify we're using the correct PostgreSQL installation
RUN echo "PostgreSQL config path: $(which pg_config)" && \
    echo "PostgreSQL version: $(pg_config --version)" && \
    echo "PostgreSQL libdir: $(pg_config --pkglibdir)" && \
    echo "PostgreSQL sharedir: $(pg_config --sharedir)"

# Build and install pgvector using explicit pg_config
RUN cd /tmp_pgvector \
    && git clone --branch v0.7.4 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make PG_CONFIG=${PG_CONFIG} \
    && make PG_CONFIG=${PG_CONFIG} install

# Install VectorChord (deb package installs to the correct location automatically)
RUN cd /tmp_vectorchord \
    && wget https://github.com/tensorchord/VectorChord/releases/download/0.5.0/postgresql-17-vchord_0.5.0-1_amd64.deb \
    && apt-get update \
    && apt-get install -y ./postgresql-17-vchord_0.5.0-1_amd64.deb \
    && rm postgresql-17-vchord_0.5.0-1_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Verify extensions are installed in the correct location
RUN ls -la $(pg_config --pkglibdir) | grep -E '(vector|vchord)' || true

# Clean up build directories
RUN rm -rf /tmp_pgvector /tmp_vectorchord

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
