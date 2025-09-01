# ============================================================================
# Build from Ubuntu 22.04 base with Postgres 17 + PostGIS
# ============================================================================
FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basics
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       wget \
       ca-certificates \
       gnupg \
       build-essential \
       git \
       gosu\
       && apt-get upgrade -y

# Install PostgreSQL 17 and PostGIS
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && echo "deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       postgresql-17 \
       postgresql-server-dev-17 \
       postgresql-17-postgis-3 \
       postgresql-client-17 \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/lib/postgresql/17/bin:$PATH"

# Build pgvector
RUN git clone https://github.com/pgvector/pgvector.git /tmp/pgvector \
    && cd /tmp/pgvector \
    && make \
    && make install \
    && rm -rf /tmp/pgvector

# Install VectorChord
RUN wget https://github.com/tensorchord/VectorChord/releases/download/0.5.0/postgresql-17-vchord_0.5.0-1_amd64.deb \
    && apt-get update \
    && apt install -y ./postgresql-17-vchord_0.5.0-1_amd64.deb \
    && rm postgresql-17-vchord_0.5.0-1_amd64.deb

# Set up PostgreSQL environment
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres
ENV PGDATA=/var/lib/postgresql/data

# Health check
HEALTHCHECK CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# Configure PostgreSQL for VectorChord
# VectorChord + pgvector (optional optimization)
# ENV POSTGRES_CONFIG_shared_preload_libraries=vchord,vector


# Copy initialization scripts
# COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/
RUN mkdir /docker-entrypoint-initdb.d

RUN echo '#!/bin/bash\n\
set -e\n\
\n\
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL\n\
    CREATE EXTENSION IF NOT EXISTS postgis;\n\
    CREATE EXTENSION IF NOT EXISTS postgis_topology;\n\
    CREATE EXTENSION IF NOT EXISTS vector;\n\
    CREATE EXTENSION IF NOT EXISTS vchord CASCADE;\n\
EOSQL' > /docker-entrypoint-initdb.d/00-init-extensions.sh

# Use the official PostgreSQL entrypoint
COPY --from=postgres:17 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-c", "shared_preload_libraries=vchord,vector"]