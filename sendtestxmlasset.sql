CREATE PROCEDURE dbo.SendTestXML-Place-
    @-Place-ID INT
AS
BEGIN
    DECLARE @xml XML;

    SET @xml = (
        SELECT 
            -- First XML for -Place- table
            (SELECT a.* 
             FROM AVE-Place-.dbo.-Place- a WITH (NOLOCK) 
             WHERE a.-Place-ID = @-Place-ID 
             FOR XML PATH('-Place-'), TYPE),
             
            -- Second XML for -Place-2 table
            (SELECT b.* 
             FROM AVE-Place-2.dbo.-Place-2 b WITH (NOLOCK) 
             WHERE b.-Place-ID = @-Place-ID 
             FOR XML PATH('-Place-2'), TYPE)
        FOR XML PATH('-Place-Data'), ROOT('-Place-s'), TYPE
    );

    SELECT @xml;
END;
