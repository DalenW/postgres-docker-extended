# ============================================================================
# Build from official PostgreSQL 17 image
# ============================================================================
FROM debian:12

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y curl

RUN curl -fsSL https://repo.pigsty.io/pig | bash  # install pig cli
RUN pig repo set
RUN pig install -y pg17
RUN pig install -y vector vchord postgis

CMD ["postgres", "-c", "listen_addresses=*"]
