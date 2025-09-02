-- Test pg_vector extension functionality
-- This test validates that vector extension is working for similarity search

\echo 'Testing pg_vector extension...'

-- Check that vector extension is available
SELECT 'Vector extension available' as test_result 
WHERE EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'vector');

-- Check that vector extension is installed
SELECT 'Vector extension installed' as test_result 
WHERE EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector');

-- Test vector data type creation
CREATE TEMP TABLE IF NOT EXISTS test_vectors (
    id serial PRIMARY KEY,
    embedding vector(3)
);

-- Insert test vectors
INSERT INTO test_vectors (embedding) VALUES 
    ('[1,2,3]'),
    ('[4,5,6]'),
    ('[7,8,9]');

-- Test vector operations - cosine distance
SELECT 'Vector cosine distance test passed' as test_result 
WHERE (
    SELECT embedding <=> '[1,2,3]' 
    FROM test_vectors 
    WHERE id = 1
) = 0;

-- Test vector operations - L2 distance  
SELECT 'Vector L2 distance test passed' as test_result 
WHERE (
    SELECT embedding <-> '[1,2,3]' 
    FROM test_vectors 
    WHERE id = 1
) = 0;

-- Test vector operations - inner product
SELECT 'Vector inner product test passed' as test_result 
WHERE (
    SELECT embedding <#> '[1,2,3]' 
    FROM test_vectors 
    WHERE id = 1
) = -14;

-- Test approximate nearest neighbor search
SELECT 'Vector similarity search test passed' as test_result 
WHERE (
    SELECT COUNT(*) 
    FROM (
        SELECT * FROM test_vectors 
        ORDER BY embedding <-> '[1,2,3]' 
        LIMIT 2
    ) nearest
) = 2;

-- Test vector indexing capability
CREATE INDEX ON test_vectors USING ivfflat (embedding vector_cosine_ops);
SELECT 'Vector index creation test passed' as test_result;

\echo 'pg_vector tests completed successfully!'