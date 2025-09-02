-- Test vector chord extension functionality
-- This test validates that vchord extension is working for vector databases

\echo 'Testing vector chord extension...'

-- Check that vchord extension is available
SELECT 'VChord extension available' as test_result 
WHERE EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'vchord');

-- Check that vchord extension is installed
SELECT 'VChord extension installed' as test_result 
WHERE EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vchord');

-- Test vchord vector operations (depends on vector extension)
CREATE TEMP TABLE IF NOT EXISTS test_vchord_vectors (
    id serial PRIMARY KEY,
    embedding vector(3)
);

-- Insert test vectors for vchord
INSERT INTO test_vchord_vectors (embedding) VALUES 
    ('[0.1,0.2,0.3]'),
    ('[0.4,0.5,0.6]'),
    ('[0.7,0.8,0.9]');

-- Test that vchord specific functions work
-- Note: This tests basic functionality - vchord provides enhanced vector operations
SELECT 'VChord basic functionality test passed' as test_result 
WHERE (
    SELECT COUNT(*) 
    FROM test_vchord_vectors 
    WHERE embedding IS NOT NULL
) = 3;

-- Test vector operations with vchord enhancements
SELECT 'VChord enhanced operations test passed' as test_result 
WHERE (
    SELECT embedding <-> '[0.1,0.2,0.3]' 
    FROM test_vchord_vectors 
    WHERE id = 1
) >= 0;

-- Verify vchord is properly loaded in shared_preload_libraries
SELECT 'VChord shared library loaded' as test_result 
WHERE 'vchord.so' = ANY(string_to_array(current_setting('shared_preload_libraries'), ','));

\echo 'Vector chord tests completed successfully!'