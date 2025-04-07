CREATE PROCEDURE sp_ImportBinaryToTable
    @binary VARBINARY(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @pos INT = 1;
    DECLARE @len INT = DATALENGTH(@binary);

    DECLARE @id INT;
    DECLARE @name NVARCHAR(100);
    DECLARE @createdAt DATETIME;

    DECLARE @output TABLE (
        Id INT,
        Name NVARCHAR(100),
        CreatedAt DATETIME
    );

    WHILE @pos <= @len
    BEGIN
        -- Read 4 bytes for INT
        SET @id = CAST(SUBSTRING(@binary, @pos, 4) AS INT);
        SET @pos += 4;

        -- Read 200 bytes for NVARCHAR(100)
        SET @name = CAST(SUBSTRING(@binary, @pos, 200) AS NVARCHAR(100));
        SET @pos += 200;

        -- Read 8 bytes for DATETIME
        SET @createdAt = CAST(SUBSTRING(@binary, @pos, 8) AS DATETIME);
        SET @pos += 8;

        INSERT INTO @output VALUES (@id, @name, @createdAt);
    END

    SELECT * FROM @output;
END
