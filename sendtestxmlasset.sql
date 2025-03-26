CREATE PROCEDURE dbo.SendTestXMLPlace
    @PlaceID INT
AS
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'DECLARE @xml XML;
    SET @xml = (
        SELECT ';

    -- Temporary table to store column names
    DECLARE @Columns TABLE (ColumnName NVARCHAR(128));

    -- Insert column names from Place
    INSERT INTO @Columns (ColumnName)
    SELECT c.name
    FROM Place.sys.columns c
    INNER JOIN Place.sys.tables t ON c.object_id = t.object_id
    WHERE t.name = 'Place';

    -- Insert column names from Place2 (avoiding duplicates)
    INSERT INTO @Columns (ColumnName)
    SELECT c.name
    FROM Place2.sys.columns c
    INNER JOIN Place2.sys.tables t ON c.object_id = t.object_id
    WHERE t.name = 'Place2'
    AND c.name NOT IN (SELECT ColumnName FROM @Columns);

    -- Construct the dynamic SELECT statement
    DECLARE @ColumnList NVARCHAR(MAX) = '';
    DECLARE @ColumnName NVARCHAR(128);

    DECLARE colCursor CURSOR FOR
    SELECT ColumnName FROM @Columns;

    OPEN colCursor;
    FETCH NEXT FROM colCursor INTO @ColumnName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Build COALESCE condition for overlapping columns
        SET @ColumnList = @ColumnList + 
            'COALESCE(a.[' + @ColumnName + '], b.[' + @ColumnName + ']) AS [' + @ColumnName + '], ';

        FETCH NEXT FROM colCursor INTO @ColumnName;
    END;
    CLOSE colCursor;
    DEALLOCATE colCursor;

    -- Remove last comma and add FROM clause
    SET @ColumnList = LEFT(@ColumnList, LEN(@ColumnList) - 1);
    SET @sql = @sql + @ColumnList + '
        FROM Place.dbo.Place a
        LEFT OUTER JOIN Place2.dbo.Place2 b ON b.PlaceID = a.PlaceID
        WHERE a.PlaceID = @PlaceID
        FOR XML PATH(''PlaceData''), ROOT(''Places''), TYPE
    );
    SELECT @xml;';

    -- Execute the
END