/*
01_create_tables.sql

Purpose: Create the source tables for the managed care analytics project.

Design choice:
The model uses dimensions and facts because this is the common pattern behind many BI/reporting datasets. Dimensions describe people,  proviers, services, dates, or drugs. Facts store events such as claims, pharmacy fills, and quality-measure results.

This scropt drops and recreates the tables so the project can be rebuilt cleanly
*/

USE ManagedCarePortfolio;
GO

-- Drop views first because views depend on the tables.
DROP VIEW IF EXISTS dbo.vw_member_targeting;
DROP VIEW IF EXISTS dbo.vw_member_year_ed_superutilizer;
DROP VIEW IF EXISTS dbo.vw_member_rising_pmpm_2025;
DROP VIEW IF EXISTS dbo.vw_member_year_top1pct;
DROP VIEW IF EXISTS dbo.vw_member_year_base;
DROP VIEW IF EXISTS dbo.vw_quality_measure_summary;
DROP VIEW IF EXISTS dbo.vw_payer_kpis_by_service_area_year;
DROP VIEW IF EXISTS dbo.vw_payer_kpis_by_year;
DROP VIEW IF EXISTS dbo.vw_claims_enriched;
DROP VIEW IF EXISTS dbo.vw_monthly_pmpm_trend;
DROP VIEW IF EXISTS dbo.vw_member_month;
GO

-- Drop fact tables before dimensions because facts reference dimensions.
DROP TABLE IF EXISTS dbo.fact_quality_measures;
DROP TABLE IF EXISTS dbo.fact_rx_fills;
DROP TABLE IF EXISTS dbo.fact_claims;
DROP TABLE IF EXISTS dbo.dim_date;
DROP TABLE IF EXISTS dbo.dim_drug;
DROP TABLE IF EXISTS dbo.dim_service;
DROP TABLE IF EXISTS dbo.dim_provider;
DROP TABLE IF EXISTS dbo.dim_member;
GO

/* --------------------------------------------------
  Dimension Tables
-------------------------------------------------- */

CREATE TABLE dbo.dim_member (
    member_id INT NOT NULL PRIMARY KEY,
    service_area VARHCAR(10) NOT NULL,
    subregion VARCHAR(50) NOT NULL,
    plan_type VARCHAR(50) NOT NULL,
    risk_category VARCHAR(20) NOT NULL,
    enrollment_start_date DATE NOT NULL,
    enrollment_end_date DATE NOT NULL
);
GO

CREATE TABLE dbo.dim_provider (
    provider_id INT NOT NULL PRIMARY KEY,
    provider_type VARCHAR(50) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    service_area VARCHAR(10) NOT NULL
);
GO

CREATE TABLE dbo.dim_service (
    service_code VARCHAR(20) NOT NULL PRIMARY KEY,
    service_category VARCHAR(50) NOT NULL,
    service_description VARCHAR(255) NOT NULL
);
GO

CREATE TABLE dbo.dim_drug (
    ndc_code VARCHAR(20) NOT NULL PRIMARY KEY,
    drug_class VARCHAR(100) NOT NULL
);
GO

CREATE TABLE dbo.dim_date (
    [date] DATE NOT NULL PRIMARY KEY,
    [year] INT NOT NULL,
    [month] INT NOT NULL,
    month_start DATE NOT NULL
);
GO

/* --------------------------------------------------
  Fact Tables
-------------------------------------------------- */

CREATE TABLE dbo.fact_claims (
    claim_id INT NOT NULL PRIMARY KEY,
    member_id INT NOT NULL,
    provider_id INT NOT NULL,
    service_code VARCHAR(20) NOT NULL,
    claim_date DATE NOT NULL,
    allowed_amount DECIMAL(12,2) NOT NULL,
    ed_flag BIT NOT NULL
);
GO

CREATE TABLE dbo.fact_rx_fills (
    rx_id INT NOT NULL PRIMARY KEY
    member_id INT NOT NULL,
    pharmacy_id INT NOT NULL,
    ndc_code VARCHAR(20) NOT NULL,
    fill_date DATE NOT NULL,
    days_supply INT NOT NULL
);
GO
CREATE TABLE dbo.fact_quality_measures (
    member_id INT NOT NULL,
    measure_name VARCHAR(200) NOT NULL,
    eligible_flag BIT NOT NULL,
    compliant_flag BIT NOT NULL,
    measurement_year INT NOT NULL
);
GO