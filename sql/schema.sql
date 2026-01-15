USE ManagedCarePortfolio;
GO

/* ===========================================================================
Schema Definition: Managed Care Analytics Data Model
Tech: SQL Server (T-SQL)

Purpose:
 Defines the physical star schema used for managed care analytics,
 including member enrollment, medical claims, pharmacy fills,
 quality measures, and calendar dimensions.

Notes:
 - All data used in this project is fully synthetic.
 - This file is DDL only (table structure). It does NOT load data.
 - Tables are created only if they do not already exist.

============================================================================ */

--

-- Managed Care Portfolio Schema (SQL Server / T-SQL)

CREATE TABLE dim_member (
  member_id INT PRIMARY KEY,
  service_area VARCHAR(10),
  subregion VARCHAR(50),
  plan_type VARCHAR(50),
  risk_category VARCHAR(20),
  enrollment_start_date DATE,
  enrollment_end_date DATE
);

CREATE TABLE dim_provider (
  provider_id INT PRIMARY KEY,
  provider_type VARCHAR(50),
  specialty VARCHAR(100),
  service_area VARCHAR(10)
);

CREATE TABLE dim_service (
  service_code VARCHAR(20) PRIMARY KEY,
  service_category VARCHAR(50),
  service_description VARCHAR(255)
);

CREATE TABLE dim_drug (
  ndc_code VARCHAR(20) PRIMARY KEY,
  drug_class VARCHAR(100)
);

CREATE TABLE dim_date (
  date DATE PRIMARY KEY,
  year INT,
  month INT,
  month_start DATE
);

CREATE TABLE fact_claims (
  claim_id INT PRIMARY KEY,
  member_id INT,
  provider_id INT,
  service_code VARCHAR(20),
  claim_date DATE,
  allowed_amount DECIMAL(12,2),
  ed_flag BIT
);

CREATE TABLE fact_rx_fills (
  rx_id INT PRIMARY KEY,
  member_id INT,
  pharmacy_id INT,
  ndc_code VARCHAR(20),
  fill_date DATE,
  days_supply INT
);

CREATE TABLE fact_quality_measures (
  member_id INT,
  measure_name VARCHAR(200),
  eligible_flag BIT,
  compliant_flag BIT,
  measurement_year INT
);

USE ManagedCarePortfolio;
GO


-- Loading dim_member
TRUNCATE TABLE dbo.dim_member;

SELECT COUNT(*) AS rows_loaded
FROM dbo.dim_member;

SELECT TOP 10 *
FROM dbo.dim_member
ORDER BY member_id;

-- Loading dim_provider
TRUNCATE TABLE dbo.dim_provider;

SELECT COUNT(*) AS rows_loaded
FROM dbo.dim_provider;

SELECT TOP 10 *
FROM dbo.dim_provider;

-- Loading dim_service
TRUNCATE TABLE dbo.dim_service;

SELECT COUNT(*) AS rows_loaded
FROM dbo.dim_service;

SELECT TOP 10 *
FROM dbo.dim_service;

-- Loading dim_drug
TRUNCATE TABLE dbo.dim_drug;

SELECT COUNT(*) AS rows_loaded
FROM dbo.dim_drug;

SELECT *
FROM dbo.dim_drug;

SELECT DISTINCT drug_class
FROM dbo.dim_drug;

-- Loading dim_date
TRUNCATE TABLE dbo.dim_date;

SELECT COUNT(*) AS rows_loaded
FROM dbo.dim_date;

SELECT *
FROM dbo.dim_date;

-- Loading fact_claims
TRUNCATE TABLE dbo.fact_claims;

SELECT COUNT(*) AS rows_loaded
FROM dbo.fact_claims;

SELECT *
FROM dbo.fact_claims;

-- Loading fact_rx_fills
TRUNCATE TABLE dbo.fact_rx_fills;

SELECT COUNT(*) AS rows_loaded
FROM dbo.fact_rx_fills;

SELECT *
FROM dbo.fact_rx_fills;

-- Loading fact_quality_measures
TRUNCATE TABLE dbo.fact_quality_measures;

SELECT COUNT(*) AS rows_loaded
FROM dbo.fact_quality_measures;

SELECT *
FROM dbo.fact_quality_measures;

SELECT 'dim_member' AS table_name, COUNT(*) AS n FROM dim_member
UNION ALL SELECT 'dim_provider', COUNT(*) FROM dim_provider
UNION ALL SELECT 'dim_service', COUNT(*) FROM dim_service
UNION ALL SELECT 'dim_drug', COUNT(*) FROM dim_drug
UNION ALL SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL SELECT 'fact_claims', COUNT(*) FROM fact_claims
UNION ALL SELECT 'fact_rx_fills', COUNT(*) FROM fact_rx_fills
UNION ALL SELECT 'fact_quality_measures', COUNT(*) FROM fact_quality_measures;

-- Run to confirm that joins won't blow up later:

-- Any claims with missing member_id?
SELECT COUNT(*) AS claims_missing_member
FROM dbo.fact_claims c
LEFT JOIN dbo.dim_member m
ON m.member_id = c.member_id
WHERE m.member_id IS NULL;

-- Any rx fills with missing member_id?
SELECT COUNT(*) AS rx_missing_member
FROM dbo.fact_rx_fills r
LEFT JOIN dbo.dim_member m
ON m.member_id = r.member_id
WHERE m.member_id IS NULL;