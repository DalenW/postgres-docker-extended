# Postgres Docker Extended

Postgres 17 with PostGIS, PgVector, and VectorChord.
Primarily used for running Immich, Dawarich, and a bunch of other docker containers off one postgres instance at home.

## Extensions Included

- **pg_vector**: Vector similarity search for PostgreSQL - enables storing and querying vector embeddings
- **VectorChord**: Enhanced vector operations from TensorChord - provides optimized vector database capabilities  
- **PostGIS**: Geographic database extender for PostgreSQL (when available)

## Usage

Building the image locally
```bash
docker build --platform linux/amd64 -t postgres-docker-extended:latest .
```

Run the image locally
```bash
docker run -d --name postgres-docker-extended-test-container --platform linux/amd64 -e POSTGRES_PASSWORD=secret postgres-docker-extended:latest
```

## Testing

This repository includes a comprehensive test suite to validate that all extensions are properly installed and functional.

### Running Tests Locally

```bash
# Start the container
docker run -d --name postgres-test -e POSTGRES_PASSWORD=secret -p 5432:5432 postgres-docker-extended:latest

# Run the test suite
cd tests
POSTGRES_PASSWORD=secret ./test-extensions.sh
```

### Continuous Integration

The test suite automatically runs in GitHub Actions:
- Tests run on every push and pull request
- Docker image is only published if all tests pass
- Tests validate pg_vector, VectorChord, and PostGIS functionality

See the [tests/README.md](tests/README.md) for detailed testing documentation.

## Branches

- `main`: Production-ready image with GitHub Actions for publishing
- `test-suite`: Development branch with comprehensive testing infrastructure