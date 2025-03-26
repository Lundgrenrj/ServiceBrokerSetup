CREATE TABLE #-Place- (
    -Place-ID INT,
    Name NVARCHAR(255),
    Location NVARCHAR(255)
);

CREATE TABLE #-Place-2 (
    -Place-ID INT,
    InspectionDate DATE,
    Warranty DATE
);

-- Extract -Place- Data
INSERT INTO #-Place- (-Place-ID, Name, Location)
SELECT 
    T.c.value('(-Place-ID)[1]', 'INT'),
    T.c.value('(Name)[1]', 'NVARCHAR(255)'),
    T.c.value('(Location)[1]', 'NVARCHAR(255)')
FROM @xml.nodes('/-Place-s/-Place-Data/-Place-') AS T(c);

-- Extract -Place-2 Data
INSERT INTO #-Place-2 (-Place-ID, InspectionDate, Warranty)
SELECT 
    T.c.value('(-Place-ID)[1]', 'INT'),
    T.c.value('(InspectionDate)[1]', 'DATE'),
    T.c.value('(Warranty)[1]', 'DATE')
FROM @xml.nodes('/-Place-s/-Place-Data/-Place-2') AS T(c);

-- Verify results
SELECT * FROM #-Place-;
SELECT * FROM #-Place-2;