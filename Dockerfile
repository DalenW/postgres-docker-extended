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
       gosu \
       locales \
    && apt-get upgrade -y

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

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

# Create postgres user and directories
RUN groupadd -r postgres --gid=999 \
    && useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres \
    && mkdir -p /var/lib/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql

# Create required directories
RUN mkdir -p /var/run/postgresql \
    && chown -R postgres:postgres /var/run/postgresql \
    && chmod 2777 /var/run/postgresql

# Set up PostgreSQL environment
ENV POSTGRES_USER=postgres
ENV POSTGRES_DB=postgres
ENV PGDATA=/var/lib/postgresql/data
ENV PATH="/usr/lib/postgresql/17/bin:$PATH"

# Create data directory
RUN mkdir -p "$PGDATA" \
    && chown -R postgres:postgres "$PGDATA" \
    && chmod 700 "$PGDATA"

# Create initialization directory
RUN mkdir -p /docker-entrypoint-initdb.d

# Create initialization script
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

# Copy and set permissions for entrypoint
COPY --from=postgres:17 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Health check
HEALTHCHECK CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# Switch to postgres user
USER postgres

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-c", "shared_preload_libraries=vchord,vector"]
