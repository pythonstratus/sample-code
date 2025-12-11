CREATE OR REPLACE PROCEDURE sp_create_icszips
AS
    /*
    ============================================================================
    Procedure:  sp_create_icszips
    Purpose:    Recreates the ICSZIPS table from OLDZIPS, removing duplicate
                records based on the composite key columns.
    Location:   /als/execloc/d.dial
    
    Tables Used:
        - OLDZIPS (source)
        - ZIPTMP (temporary working table)
        - ICSZIPS (target)
    
    Original Script: crzips.sql
    ============================================================================
    */
    
    v_error_msg VARCHAR2(500);
    v_row_count NUMBER;
    
BEGIN
    -- =========================================================================
    -- Step 1: Create temporary working table structure
    -- =========================================================================
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE ziptmp';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN  -- Table doesn't exist
                RAISE;
            END IF;
    END;
    
    -- Create ziptmp with same structure as oldzips (empty)
    EXECUTE IMMEDIATE 'CREATE TABLE ziptmp AS (SELECT * FROM oldzips WHERE rownum = 1)';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ziptmp';
    
    -- =========================================================================
    -- Step 2: Identify and store duplicate records in ziptmp
    --         Duplicates are rows where all key fields match but rowid differs
    -- =========================================================================
    INSERT INTO ziptmp
    SELECT DISTINCT
        zip1.dizipcd,
        zip1.didocd,
        zip1.gslvl,
        zip1.roempid,
        zip1.alphabeg,
        zip1.alphaend,
        zip1.bodcd,
        zip1.bodclcd,
        zip1.acsqind
    FROM oldzips zip1, oldzips zip2
    WHERE zip1.dizipcd   = zip2.dizipcd
      AND zip1.didocd    = zip2.didocd
      AND zip1.gslvl     = zip2.gslvl
      AND zip1.alphabeg  = zip2.alphabeg
      AND zip1.alphaend  = zip2.alphaend
      AND zip1.rowid    <> zip2.rowid
      AND zip1.rowid     > zip2.rowid;
    
    v_row_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Duplicate records identified: ' || v_row_count);
    
    -- =========================================================================
    -- Step 3: Drop and recreate ICSZIPS table
    -- =========================================================================
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE icszips';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;
    
    EXECUTE IMMEDIATE '
        CREATE TABLE icszips (
            DIZIPCD     NUMBER(5),
            DIDOCD      NUMBER(2),
            GSLVL       NUMBER(2),
            ROEMPID     NUMBER(8),
            ALPHABEG    CHAR(1),
            ALPHAEND    CHAR(1),
            BODCD       VARCHAR2(2),
            BODCLCD     VARCHAR2(3),
            ACSQIND     NUMBER(1),
            CONSTRAINT pk_zips PRIMARY KEY (didocd, dizipcd, gslvl, alphabeg, alphaend)
        ) ORGANIZATION INDEX';
    
    -- =========================================================================
    -- Step 4: Populate ICSZIPS with non-duplicate records
    --         (all records from oldzips MINUS the duplicates in ziptmp)
    -- =========================================================================
    INSERT INTO icszips (
        dizipcd,
        didocd,
        gslvl,
        roempid,
        alphabeg,
        alphaend,
        bodcd,
        bodclcd,
        acsqind
    )
    SELECT
        dizipcd,
        didocd,
        gslvl,
        roempid,
        alphabeg,
        alphaend,
        bodcd,
        bodclcd,
        acsqind
    FROM oldzips
    MINUS
    SELECT DISTINCT
        dizipcd,
        didocd,
        gslvl,
        roempid,
        alphabeg,
        alphaend,
        bodcd,
        bodclcd,
        acsqind
    FROM ziptmp;
    
    v_row_count := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Records inserted into ICSZIPS: ' || v_row_count);
    
    -- =========================================================================
    -- Step 5: Create index and compute statistics
    -- =========================================================================
    EXECUTE IMMEDIATE 'CREATE INDEX icszips_roid_ix ON icszips (roempid) TABLESPACE dial_ind';
    
    DBMS_OUTPUT.PUT_LINE('Index icszips_roid_ix created successfully');
    
    -- Gather table statistics (using ANALYZE for broader compatibility)
    EXECUTE IMMEDIATE 'ANALYZE TABLE icszips COMPUTE STATISTICS';
    
    DBMS_OUTPUT.PUT_LINE('Table statistics computed');
    
    -- =========================================================================
    -- Step 6: Grant permissions
    -- =========================================================================
    EXECUTE IMMEDIATE 'GRANT SELECT ON dial.icszips TO als';
    EXECUTE IMMEDIATE 'GRANT SELECT ON dial.icszips TO alsrpt';
    EXECUTE IMMEDIATE 'GRANT SELECT ON dial.icszips TO dialrpt';
    
    DBMS_OUTPUT.PUT_LINE('Grants applied successfully');
    
    -- Commit the transaction
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Procedure sp_create_icszips completed successfully');
    
EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_error_msg);
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'sp_create_icszips failed: ' || v_error_msg);
END sp_create_icszips;
/
