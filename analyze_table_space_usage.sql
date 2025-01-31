SET NOCOUNT ON  -- Prevents the message that shows the count of affected rows from being returned

-- Drop the temporary table if it already exists to ensure a clean start
IF EXISTS (SELECT * FROM TempDb.dbo.SysObjects WHERE NAME = '##Space_Used') 
    DROP TABLE ##Space_Used

-- Create a temporary table to store space usage information for each user table
CREATE TABLE ##Space_Used (
    name nvarchar(500),
    rows char(11),
    reserved varchar(18),
    index_size varchar(18),
    unused varchar(18)
)

DECLARE @User_Table_Name varchar(200)  -- Declare a variable to hold table names

-- Declare a cursor to iterate over all user tables in the database
DECLARE User_Tables_Cursor CURSOR FOR
SELECT name
FROM Dbo.SysObjects
WHERE XTYPE = 'U'  -- 'U' indicates user tables

OPEN User_Tables_Cursor  -- Open the cursor

-- Fetch the first table name into the variable
FETCH NEXT FROM User_Tables_Cursor INTO @User_Table_Name
WHILE @@FETCH_STATUS = 0  -- Loop until all tables are processed
BEGIN
    -- Insert space usage information for the current table into the temporary table
    INSERT INTO ##Space_Used
    EXEC sp_spaceused @User_Table_Name

    -- Fetch the next table name
    FETCH NEXT FROM User_Tables_Cursor INTO @User_Table_Name
END

CLOSE User_Tables_Cursor  -- Close the cursor
DEALLOCATE User_Tables_Cursor  -- Deallocate the cursor to free resources

-- Drop another temporary table if it exists (though it seems unused in the script)
IF EXISTS (SELECT * FROM TempDb.dbo.SysObjects WHERE NAME = '##Space_Used2') 
    DROP TABLE ##Space_Used2

-- Select and display space usage information along with compression details
SELECT DISTINCT
    TableName = LEFT(a.Name, 500),  -- Table name
    "RowCount" = a.Rows,  -- Number of rows in the table
    Reserved_Phys_Size_KB = CONVERT(int, LEFT(a.Reserved, PATINDEX('% KB', a.Reserved) - 1)),  -- Reserved size in KB
    b.create_date,  -- Table creation date
    b.modify_date,  -- Table last modification date
    CompressionType = CASE  -- Determine the type of compression applied
        WHEN MAX(p.data_compression) = 0 THEN 'None'
        WHEN MAX(p.data_compression) = 1 THEN 'Row'
        WHEN MAX(p.data_compression) = 2 THEN 'Page'
        ELSE 'Unknown'
    END,
    CompressionCommand = CASE  -- Generate a command to apply page compression if not compressed
        WHEN MAX(p.data_compression) = 0 THEN 
            'ALTER TABLE ' + QUOTENAME(b.name) + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);'
        ELSE NULL
    END
FROM ##Space_Used a
JOIN sys.tables b ON a.Name = b.name  -- Join with sys.tables to get additional table metadata
JOIN sys.partitions p ON b.object_id = p.object_id  -- Join with sys.partitions to get compression info
GROUP BY a.Name, a.Rows, a.Reserved, b.create_date, b.modify_date  -- Group by necessary columns
ORDER BY 1  -- Order the results by table name