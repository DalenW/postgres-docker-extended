# Postgres Docker Extended

Postgres 17 with PostGIS, PgVector, and VectorChord.
Primarily used for running Immich, Dawarich, and a bunch of other docker containers off one postgres instance at home.

## Usage

Building the image locally
```bash
docker build --platform linux/amd64 -t postgres-docker-extended:latest .
```

Run the image locally
```bash
docker run -d --name postgres-docker-extended-test-container --platform linux/amd64 -e POSTGRES_PASSWORD=secret postgres-docker-extended:latest
```