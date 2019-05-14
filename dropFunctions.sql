DO
    $do$
    DECLARE
    _sql text;
    BEGIN
        SELECT INTO _sql
        string_agg(format('DROP %s %s;'
                , CASE WHEN proisagg THEN 'AGGREGATE' ELSE 'FUNCTION' END
                , oid::regprocedure)
            , E'\n')
        FROM   pg_proc
        WHERE  pronamespace = 'public'::regnamespace;  -- schema name here!

        IF _sql IS NOT NULL THEN
            RAISE NOTICE '%', _sql;  -- debug / check first
            -- EXECUTE _sql;         -- uncomment payload once you are sure
        ELSE 
            RAISE NOTICE 'No fuctions found in schema %', quote_ident(_schema);
        END IF;
END
$do$  LANGUAGE plpgsql;
