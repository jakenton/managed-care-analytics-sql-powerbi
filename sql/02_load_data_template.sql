/*
02_load_data_template.sql

Purpose: Load the CSV files into SQL Server using BULK INSERT

Before running:
  1. Update the @BasePath value below so it points to your local project folder.
  2. Make sure SQL Server can access that folder.
  3. Load dimensions first, then facts, because fact tables have foreign keys.

Alternatively:
  You can use the SQL Server Import Wizard instead of this script.
  In this case, make sure to match each CSV file to the table with the same name.
*/

USE ManagedCarePortfolio;
GO


/* --------------------------------------------------
  Load Dimension Tables
-------------------------------------------------- */

BULK INSERT dbo.dim_member
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\dim_member.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT dbo.dim_provider
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\dim_provider.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT dbo.dim_service
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\dim_service.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT dbo.dim_drug
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\dim_drug.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT dbo.dim_date
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\dim_date.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

/* --------------------------------------------------
  Load Fact Tables
-------------------------------------------------- */

BULK INSERT dbo.fact_claims
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\fact_claims.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT dbo.fact_rx_fills
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\fact_rx_fills.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

BULK INSERT dbo.fact_quality_measures
FROM 'C:\Data-Analytics-Projects\managed-care-project\managed-care-analytics-sql-powerbi\raw_data_simulated\fact_quality_measures.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);

GO