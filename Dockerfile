# ============================================================================
# Build from official PostgreSQL 17 image
# ============================================================================
FROM tensorchord/vchord-postgres:pg17-v0.4.3

# Set environment variables to ensure we use the correct PostgreSQL installation
ENV PG_CONFIG=/usr/lib/postgresql/17/bin/pg_config
ENV PATH=/usr/lib/postgresql/17/bin:$PATH

RUN apt-get update && apt-get upgrade -y

# Install build dependencies and PostGIS
RUN apt-get install -y --no-install-recommends \
       postgresql-17-postgis-3 \
    && rm -rf /var/lib/apt/lists/*

# Verify extensions are installed in the correct location
RUN ls -la $(pg_config --pkglibdir) | grep -E '(vector|vchord)' || true

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
CMD ["postgres", "-c", "shared_preload_libraries=vchord.so", "-c", "listen_addresses=*"]
