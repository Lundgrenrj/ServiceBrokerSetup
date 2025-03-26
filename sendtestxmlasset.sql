CREATE PROCEDURE dbo.SendTestXML-Place-
    @-Place-ID INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'DECLARE @xml XML;
    SET @xml = (
        SELECT ';

    -- Temporary tables to store column names
    DECLARE @-Place-Columns TABLE (ColumnName NVARCHAR(128));
    DECLARE @-Place-2Columns TABLE (ColumnName NVARCHAR(128));
    DECLARE @Columns TABLE (ColumnName NVARCHAR(128), Source NVARCHAR(10));

    -- Get column names from -Place-
    INSERT INTO @-Place-Columns (ColumnName)
    SELECT c.name
    FROM AVE-Place-.sys.columns c
    INNER JOIN AVE-Place-.sys.tables t ON c.object_id = t.object_id
    WHERE t.name = '-Place-';

    -- Get column names from -Place-2
    INSERT INTO @-Place-2Columns (ColumnName)
    SELECT c.name
    FROM AVE-Place-2.sys.columns c
    INNER JOIN AVE-Place-2.sys.tables t ON c.object_id = t.object_id
    WHERE t.name = '-Place-2';

    -- Merge column lists, marking their source
    INSERT INTO @Columns (ColumnName, Source)
    SELECT ColumnName, 'Both'
    FROM @-Place-Columns
    WHERE ColumnName IN (SELECT ColumnName FROM @-Place-2Columns) -- Exists in both tables

    UNION ALL

    SELECT ColumnName, '-Place-'
    FROM @-Place-Columns
    WHERE ColumnName NOT IN (SELECT ColumnName FROM @-Place-2Columns) -- Exists only in -Place-

    UNION ALL

    SELECT ColumnName, '-Place-2'
    FROM @-Place-2Columns
    WHERE ColumnName NOT IN (SELECT ColumnName FROM @-Place-Columns); -- Exists only in -Place-2

    -- Construct the dynamic SELECT statement
    DECLARE @ColumnList NVARCHAR(MAX) = '';
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @Source NVARCHAR(10);

    DECLARE colCursor CURSOR FOR
    SELECT ColumnName, Source FROM @Columns;

    OPEN colCursor;
    FETCH NEXT FROM colCursor INTO @ColumnName, @Source;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Source = 'Both'
            SET @ColumnList = @ColumnList + 
                'COALESCE(a.[' + @ColumnName + '], b.[' + @ColumnName + ']) AS [' + @ColumnName + '], ';
        ELSE IF @Source = '-Place-'
            SET @ColumnList = @ColumnList + 
                'a.[' + @ColumnName + '] AS [' + @ColumnName + '], ';
        ELSE
            SET @ColumnList = @ColumnList + 
                'b.[' + @ColumnName + '] AS [' + @ColumnName + '], ';

        FETCH NEXT FROM colCursor INTO @ColumnName, @Source;
    END;
    CLOSE colCursor;
    DEALLOCATE colCursor;

    -- Ensure @ColumnList is not empty before trimming
    IF LEN(@ColumnList) > 0
        SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 2); -- Remove last comma and space

    -- Append FROM clause only if columns exist
    IF LEN(@ColumnList) > 0
    BEGIN
        SET @sql = @sql + @ColumnList + '
            FROM AVE-Place-.dbo.-Place- a
            LEFT OUTER JOIN AVE-Place-2.dbo.-Place-2 b ON b.-Place-ID = a.-Place-ID
            WHERE a.-Place-ID = @-Place-ID
            FOR XML PATH(''-Place-Data''), ROOT(''-Place-s''), TYPE
        );
        SELECT @xml;';
    
        -- Execute the dynamic SQL
        EXEC sp_executesql @sql, N'@-Place-ID INT', @-Place-ID;
    END
    ELSE
    BEGIN
        PRINT 'No columns found for -Place- and -Place-2';
    END
END;
