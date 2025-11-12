# ============================================================================
# Build from official PostgreSQL 17 image
# ============================================================================
FROM debian:13

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl
# \ && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://repo.pigsty.io/pig | bash  # install pig cli
RUN pig repo set
RUN pig install -y pg17
RUN pig install -y vector vchord postgis

ENV PG_HOME=/var/lib/postgresql
ENV PGDATA=${PG_HOME}/data

# Create non-root postgres user and prepare data directory
# RUN if ! id -u postgres >/dev/null 2>&1; then \
#       useradd -r -m -U -d "${PG_HOME}" -s /bin/bash postgres; \
#     fi \
#  && mkdir -p "${PGDATA}" \
#  && chown -R postgres:postgres "${PG_HOME}"

# Initialise the database cluster during build
USER postgres
RUN /usr/lib/postgresql/17/bin/initdb -D "${PGDATA}"

EXPOSE 5432

CMD ["/usr/lib/postgresql/17/bin/postgres", "-D", "/var/lib/postgresql/data", "-c", "listen_addresses=*"]
# CMD ["/bin/bash"]
