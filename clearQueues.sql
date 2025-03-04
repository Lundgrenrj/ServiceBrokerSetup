DECLARE @ConvHandle UNIQUEIDENTIFIER;

DECLARE conv_cursor CURSOR FOR
SELECT conversation_handle FROM sys.conversation_endpoints;

OPEN conv_cursor;

FETCH NEXT FROM conv_cursor INTO @ConvHandle;

WHILE @@FETCH_STATUS = 0
BEGIN
    END CONVERSATION @ConvHandle WITH CLEANUP;
    FETCH NEXT FROM conv_cursor INTO @ConvHandle;
END

CLOSE conv_cursor;
DEALLOCATE conv_cursor;
