#!/bin/bash

# Main test runner for PostgreSQL extensions
# Tests PostGIS, pg_vector, and vector chord extensions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-postgres}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-postgres}"

# Test directory
TEST_DIR="$(dirname "$0")"
SQL_DIR="${TEST_DIR}/sql"

echo -e "${YELLOW}=== PostgreSQL Extension Test Suite ===${NC}"
echo "Testing PostgreSQL extensions: PostGIS, pg_vector, vector chord"
echo "Host: ${POSTGRES_HOST}:${POSTGRES_PORT}"
echo "Database: ${POSTGRES_DB}"
echo "User: ${POSTGRES_USER}"
echo ""

# Function to run a SQL test file
run_sql_test() {
    local test_file="$1"
    local test_name="$2"
    
    echo -e "${YELLOW}Running ${test_name}...${NC}"
    
    if PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f "${test_file}" > /tmp/test_output.log 2>&1; then
        echo -e "${GREEN}✓ ${test_name} passed${NC}"
        
        # Show test results
        if grep -q -E "(test_result|NOTICE)" /tmp/test_output.log; then
            echo "  Results:"
            grep -E "(test_result|NOTICE)" /tmp/test_output.log | sed 's/^/    /'
        fi
        return 0
    else
        echo -e "${RED}✗ ${test_name} failed${NC}"
        echo "Error output:"
        cat /tmp/test_output.log | sed 's/^/    /'
        return 1
    fi
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT 1;" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PostgreSQL is ready${NC}"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts - PostgreSQL not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}✗ PostgreSQL failed to become ready after $max_attempts attempts${NC}"
    return 1
}

# Function to check basic PostgreSQL info
check_postgres_info() {
    echo -e "${YELLOW}PostgreSQL Information:${NC}"
    PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "SELECT version();" | head -3
    echo ""
}

# Main test execution
main() {
    local failed_tests=0
    
    # Wait for PostgreSQL
    if ! wait_for_postgres; then
        exit 1
    fi
    
    # Show PostgreSQL info
    check_postgres_info
    
    # Run tests
    echo -e "${YELLOW}=== Running Extension Tests ===${NC}"
    
    if ! run_sql_test "${SQL_DIR}/test-postgis.sql" "PostGIS Extension Test"; then
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    
    if ! run_sql_test "${SQL_DIR}/test-pgvector.sql" "pg_vector Extension Test"; then
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    
    if ! run_sql_test "${SQL_DIR}/test-vchord.sql" "Vector Chord Extension Test"; then
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
    
    # Summary
    echo -e "${YELLOW}=== Test Summary ===${NC}"
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! All extensions are working correctly.${NC}"
        exit 0
    else
        echo -e "${RED}✗ $failed_tests test(s) failed${NC}"
        exit 1
    fi
}

# Check if required files exist
if [ ! -f "${SQL_DIR}/test-postgis.sql" ]; then
    echo -e "${RED}Error: PostGIS test file not found${NC}"
    exit 1
fi

if [ ! -f "${SQL_DIR}/test-pgvector.sql" ]; then
    echo -e "${RED}Error: pg_vector test file not found${NC}"
    exit 1
fi

if [ ! -f "${SQL_DIR}/test-vchord.sql" ]; then
    echo -e "${RED}Error: Vector chord test file not found${NC}"
    exit 1
fi

# Run main function
main "$@"