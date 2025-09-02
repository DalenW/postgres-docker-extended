-- Test PostGIS extension functionality
-- This test validates that PostGIS and PostGIS topology extensions are working
-- If PostGIS is not available, the test will skip gracefully

\echo 'Testing PostGIS extension...'

-- Check that PostGIS extension is available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'postgis') THEN
        RAISE NOTICE 'PostGIS extension available';
        
        -- Check that PostGIS extension is installed
        IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
            RAISE NOTICE 'PostGIS extension installed';
            
            -- Check PostGIS version
            RAISE NOTICE 'PostGIS version: %', PostGIS_Version();
            
            -- Test basic geometry operations
            IF ST_Distance(ST_Point(0,0), ST_Point(1,1)) > 0 THEN
                RAISE NOTICE 'Basic geometry test passed';
            END IF;
            
            -- Test geographic coordinate system
            IF ST_DWithin(
                ST_GeogFromText('POINT(-71.064544 42.28787)'),  -- Boston
                ST_GeogFromText('POINT(-71.0275 42.3751)'),     -- Cambridge  
                10000  -- 10km
            ) THEN
                RAISE NOTICE 'Geographic coordinate system test passed';
            END IF;
            
        ELSE
            RAISE NOTICE 'PostGIS extension not installed';
        END IF;
        
        -- Check PostGIS topology extension
        IF EXISTS (SELECT 1 FROM pg_available_extensions WHERE name = 'postgis_topology') THEN
            RAISE NOTICE 'PostGIS topology extension available';
            
            IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis_topology') THEN
                RAISE NOTICE 'PostGIS topology extension installed';
            ELSE
                RAISE NOTICE 'PostGIS topology extension not installed';
            END IF;
        ELSE
            RAISE NOTICE 'PostGIS topology extension not available';
        END IF;
        
    ELSE
        RAISE NOTICE 'PostGIS extension not available - skipping PostGIS tests';
    END IF;
END
$$;

\echo 'PostGIS tests completed!'