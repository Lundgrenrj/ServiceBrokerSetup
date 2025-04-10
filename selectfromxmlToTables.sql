DECLARE @TableName1 NVARCHAR(128) = '-places-';  -- First table
DECLARE @TableName2 NVARCHAR(128) = '-places-2'; -- Second table
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @columns NVARCHAR(MAX) = '';

-- Step 1: Get column names dynamically for -places- using FOR XML PATH('')
SELECT @columns = STUFF((
    SELECT ', T.c.value(''(' + COLUMN_NAME + ')[1]'', ''NVARCHAR(MAX)'') AS [' + COLUMN_NAME + ']'
    FROM sys.columns
    WHERE OBJECT_ID = OBJECT_ID('AVE-places-.dbo.' + @TableName1) -- Adjust schema if needed
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Step 2: Construct the query for -places-
SET @sql = 'SELECT ' + @columns + ' INTO #-places- FROM @xml.nodes(''/-places-s/-places-Data/-places-'') AS T(c);';

-- Execute the dynamic SQL for -places-
EXEC sp_executesql @sql, N'@xml XML', @xml;

-- Reset variables for the second table
SET @sql = '';
SET @columns = '';

-- Step 3: Get column names dynamically for -places-2
SELECT @columns = STUFF((
    SELECT ', T.c.value(''(' + COLUMN_NAME + ')[1]'', ''NVARCHAR(MAX)'') AS [' + COLUMN_NAME + ']'
    FROM sys.columns
    WHERE OBJECT_ID = OBJECT_ID('AVE-places-2.dbo.' + @TableName2) -- Adjust schema if needed
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

-- Step 4: Construct the query for -places-2
SET @sql = 'SELECT ' + @columns + ' INTO #-places-2 FROM @xml.nodes(''/-places-s/-places-Data/-places-2'') AS T(c);';

-- Execute the dynamic SQL for -places-2
EXEC sp_executesql @sql, N'@xml XML', @xml;

-- Step 5: Query the dynamically created tables using more dynamic SQL
SET @sql = 'SELECT * FROM #-places-; SELECT * FROM #-places-2;';
EXEC sp_executesql @sql;