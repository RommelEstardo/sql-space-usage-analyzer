# sql-space-usage-analyzer

# SQL Server Table Space Usage Analyzer

## Overview
This SQL script provides detailed analysis of table space usage in SQL Server databases. It generates a comprehensive report showing table sizes, compression status, and provides recommendations for compression optimization.

## Features
- Analyzes space usage for all user tables in the database
- Reports physical size, row counts, and reserved space
- Identifies current compression status for each table
- Generates ready-to-use compression commands for uncompressed tables
- Includes table creation and modification dates
- Orders results by table name for easy reference

## Prerequisites
- SQL Server instance with appropriate permissions
- Access to system views (sys.tables, sys.partitions)
- Permission to create temporary tables
- Permission to execute sp_spaceused stored procedure

## How It Works
1. Creates a global temporary table (##Space_Used) to store space usage information
2. Uses a cursor to iterate through all user tables in the database
3. Collects space usage information using sp_spaceused
4. Joins with system tables to gather additional metadata
5. Generates compression recommendations where applicable

## Output Columns
- `TableName`: Name of the table (limited to 500 characters)
- `RowCount`: Number of rows in the table
- `Reserved_Phys_Size_KB`: Physical space reserved for the table in kilobytes
- `create_date`: When the table was created
- `modify_date`: When the table was last modified
- `CompressionType`: Current compression status (None, Row, Page, or Unknown)
- `CompressionCommand`: SQL command to apply page compression (if table is uncompressed)

## Usage
```sql
-- Simply execute the script in your database context
USE YourDatabaseName
GO
-- Run the entire script
```

## Technical Notes
- Uses SET NOCOUNT ON to suppress row count messages
- Automatically handles cleanup of temporary objects
- Includes error handling for existing temporary tables
- Groups results to handle tables with multiple partitions

## Best Practices
- Review compression recommendations before applying them
- Run during off-peak hours on large databases
- Consider impact on CPU when applying compression
- Back up database before applying any compression changes

## Example Output
```plaintext
TableName  RowCount  Reserved_Phys_Size_KB  create_date  modify_date  CompressionType  CompressionCommand
----------------------------------------------------------------------------------------------
Table1     1000      5120                   2024-01-01   2024-01-30   None            ALTER TABLE [Table1] REBUILD...
Table2     5000      10240                  2024-01-01   2024-01-30   Page            NULL
```
