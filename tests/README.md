# PostgreSQL Extensions Test Suite

This directory contains the test suite for validating PostgreSQL extensions in the postgres-docker-extended image.

## Overview

The test suite validates that the following extensions are properly installed and functional:

- **PostGIS**: Geographic database extender for PostgreSQL
- **pg_vector**: Vector similarity search for PostgreSQL  
- **VChord**: Enhanced vector operations from TensorChord

## Structure

```
tests/
├── test-extensions.sh     # Main test runner script
├── sql/                   # SQL test files
│   ├── test-postgis.sql   # PostGIS functionality tests
│   ├── test-pgvector.sql  # pg_vector functionality tests
│   └── test-vchord.sql    # VChord functionality tests
└── README.md             # This file
```

## Running Tests

### Prerequisites

- PostgreSQL client tools (`psql`, `pg_isready`)
- Access to a running postgres-docker-extended container

### Local Testing

1. Start the postgres-docker-extended container:
   ```bash
   docker run -d \
     --name postgres-test \
     -e POSTGRES_PASSWORD=secret \
     -p 5432:5432 \
     postgres-docker-extended:latest
   ```

2. Run the test suite:
   ```bash
   cd tests
   ./test-extensions.sh
   ```

### Environment Variables

The test runner accepts the following environment variables:

- `POSTGRES_HOST` (default: localhost)
- `POSTGRES_PORT` (default: 5432)  
- `POSTGRES_DB` (default: postgres)
- `POSTGRES_USER` (default: postgres)
- `POSTGRES_PASSWORD` (default: postgres)

Example with custom settings:
```bash
POSTGRES_PASSWORD=mypassword ./test-extensions.sh
```

## GitHub Actions Integration

The test suite is automatically run in GitHub Actions:

- **test-extensions.yml**: Standalone testing workflow
- **docker-publish.yml**: Tests are run before publishing (modified)

Tests must pass before the Docker image is published to the registry.

## Adding New Extension Tests

To add tests for a new extension:

1. Create a new SQL test file in `tests/sql/test-{extension}.sql`
2. Follow the existing pattern:
   - Check extension availability
   - Check extension installation
   - Test basic functionality
   - Use `\echo` for progress messages
   - Return test results with meaningful names

3. Add the test to `test-extensions.sh`:
   ```bash
   if ! run_sql_test "${SQL_DIR}/test-{extension}.sql" "{Extension} Test"; then
       failed_tests=$((failed_tests + 1))
   fi
   ```

## Test File Format

Each SQL test file should:

- Start with extension availability check
- Verify extension is installed  
- Test core functionality
- Use temporary tables for test data
- Return meaningful test result messages
- Include progress messages with `\echo`

Example test structure:
```sql
-- Check extension is available
SELECT 'Extension available' as test_result 
WHERE EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'extension_name');

-- Check extension is installed
SELECT 'Extension installed' as test_result 
WHERE EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'extension_name');

-- Test functionality
CREATE TEMP TABLE test_data (...);
-- ... test operations ...
SELECT 'Functionality test passed' as test_result WHERE condition;
```

## Troubleshooting

If tests fail:

1. Check container logs: `docker logs postgres-test`
2. Verify extensions are loaded: Check shared_preload_libraries setting
3. Test manually: Connect with `psql` and run commands interactively
4. Check extension versions and compatibility

## Continuous Integration

The test suite is designed to:

- Run quickly (typically under 2 minutes)
- Provide clear, actionable error messages
- Test real functionality, not just installation
- Be extensible for future extensions
- Integrate seamlessly with existing CI/CD pipeline