CREATE PROCEDURE dbo.SendTestXML-Place-
    @-Place-ID INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @ColumnList NVARCHAR(MAX) = N'';
    DECLARE @ColumnName NVARCHAR(128);
    DECLARE @Source NVARCHAR(10);

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

    -- Construct the dynamic SELECT statement in chunks
    DECLARE colCursor CURSOR FOR
    SELECT ColumnName, Source FROM @Columns;

    OPEN colCursor;
    FETCH NEXT FROM colCursor INTO @ColumnName, @Source;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @Source = 'Both'
            SET @ColumnList = @ColumnList + N'COALESCE(a.[' + @ColumnName + N'], b.[' + @ColumnName + N']) AS [' + @ColumnName + N'], ';
        ELSE IF @Source = '-Place-'
            SET @ColumnList = @ColumnList + N'a.[' + @ColumnName + N'] AS [' + @ColumnName + N'], ';
        ELSE
            SET @ColumnList = @ColumnList + N'b.[' + @ColumnName + N'] AS [' + @ColumnName + N'], ';

        -- If @ColumnList gets too large, break into chunks to avoid SQL Server limitations
        IF LEN(@ColumnList) > 3000
        BEGIN
            PRINT @ColumnList; -- Debugging: Print part of the SQL
            SET @ColumnList = N''; -- Reset for next chunk
        END

        FETCH NEXT FROM colCursor INTO @ColumnName, @Source;
    END;
    CLOSE colCursor;
    DEALLOCATE colCursor;

    -- Trim trailing comma and space
    IF LEN(@ColumnList) > 0
        SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 2);

    -- Assemble full SQL statement
    SET @sql = N'DECLARE @xml XML;
    SET @xml = (
        SELECT ' + @ColumnList + N'
        FROM AVE-Place-.dbo.-Place- a
        LEFT OUTER JOIN AVE-Place-2.dbo.-Place-2 b ON b.-Place-ID = a.-Place-ID
        WHERE a.-Place-ID = @-Place-ID
        FOR XML PATH(''-Place-Data''), ROOT(''-Place-s''), TYPE
    );
    SELECT @xml;';

    -- Debugging: Print SQL if needed
    PRINT @sql; -- Comment out in production

    -- Execute the dynamic SQL
    EXEC sp_executesql @sql, N'@-Place-ID INT', @-Place-ID;
END;
