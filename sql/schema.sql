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

-- ===========
-- Dimensions
-- ===========

IF OBJECT_ID('dbo.dim_member', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.dim_member (
	  member_id INT NOT NULL PRIMARY KEY,
	  service_area VARCHAR(10) NULL,
	  subregion VARCHAR(50) NULL,
	  plan_type VARCHAR(50) NULL,
	  risk_category VARCHAR(20) NULL,
	  enrollment_start_date DATE NULL,
	  enrollment_end_date DATE NULL
	);
END;
GO

IF OBJECT_ID('dbo.dim_provider', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.dim_provider (
	  provider_id INT NOT NULL PRIMARY KEY,
	  provider_type VARCHAR(50) NULL,
	  specialty VARCHAR(100) NULL,
	  service_area VARCHAR(10) NULL
	);
END;
GO

IF OBJECT_ID('dbo.dim_service', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.dim_service (
	  service_code VARCHAR(20) NOT NULL PRIMARY KEY,
	  service_category VARCHAR(50) NULL,
	  service_description VARCHAR(255) NULL
	);
END;
GO

IF OBJECT_ID('dbo.dim_drug', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.dim_drug (
	  ndc_code VARCHAR(20) NOT NULL PRIMARY KEY,
	  drug_class VARCHAR(100) NULL
	);
END;
GO

IF OBJECT_ID('dbo.dim_date', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.dim_date (
	  date DATE NOT NULL PRIMARY KEY,
	  year INT NULL,
	  month INT NULL,
	  month_start DATE NULL
	);
END;
GO

-- ===========
-- Facts
-- ===========

IF OBJECT_ID('dbo.fact_claims', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.fact_claims (
	  claim_id INT NOT NULL PRIMARY KEY,
	  member_id INT NULL,
	  provider_id INT NULL,
	  service_code VARCHAR(20) NULL,
	  claim_date DATE NULL,
	  allowed_amount DECIMAL(12,2) NULL,
	  ed_flag BIT NULL
	);
END;
GO

IF OBJECT_ID('dbo.fact_rx_fills', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.fact_rx_fills (
	  rx_id INT NOT NULL PRIMARY KEY,
	  member_id INT NULL,
	  pharmacy_id INT NULL,
	  ndc_code VARCHAR(20) NULL,
	  fill_date DATE NULL,
	  days_supply INT NULL
	);
END;
GO

IF OBJECT_ID('dbo.fact_quality_measures', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.fact_quality_measures (
	  member_id INT NOT NULL,
	  measure_name VARCHAR(200) NOT NULL,
	  eligible_flag BIT NOT NULL,
	  compliant_flag BIT NULL,
	  measurement_year INT NULL
	  CONSTRAINT pk_fact_quality_measures
		PRIMARY KEY (member_id, measure_name, measurement_year)
	);
END;
GO