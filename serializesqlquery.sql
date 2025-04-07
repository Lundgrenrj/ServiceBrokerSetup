CREATE PROCEDURE sp_ExportQueryToBinary
    @sql NVARCHAR(MAX),
    @binary VARBINARY(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @dynamicSql NVARCHAR(MAX);
    DECLARE @tempTable TABLE (
        Id INT,
        Name NVARCHAR(100),
        CreatedAt DATETIME
    );

    SET @dynamicSql = '
        INSERT INTO @tempTable
        ' + CHAR(13) + @sql;

    EXEC sp_executesql @dynamicSql, N'@tempTable TABLE (Id INT, Name NVARCHAR(100), CreatedAt DATETIME)', @tempTable = @tempTable;

    DECLARE @rowBinary VARBINARY(MAX);
    SET @binary = 0x;

    DECLARE @id INT, @name NVARCHAR(100), @createdAt DATETIME;

    DECLARE cur CURSOR FOR
    SELECT Id, Name, CreatedAt FROM @tempTable;

    OPEN cur;
    FETCH NEXT FROM cur INTO @id, @name, @createdAt;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @rowBinary =
            CAST(@id AS BINARY(4)) +
            CAST(@name AS VARBINARY(200)) +
            CAST(@createdAt AS BINARY(8));

        SET @binary = @binary + @rowBinary;

        FETCH NEXT FROM cur INTO @id, @name, @createdAt;
    END

    CLOSE cur;
    DEALLOCATE cur;
END
