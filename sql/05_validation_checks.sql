/*
05_validation_checks.sql

Purpose: Validate that the dataset loaded correctly and the reporting views work.

Expected use:
  Run this after loading data and creating views. These checks do not modify data.
*/

USE ManagedCarePortfolio;
GO

/* -----------------------------------------------------------------------------
  1. Row counts by source table
----------------------------------------------------------------------------- */

SELECT
    'dim_date' AS object_name,
    COUNT(*) AS row_count
FROM dbo.dim_date

UNION ALL

SELECT
    'dim_drug',
    COUNT(*)
FROM dbo.dim_drug

UNION ALL

SELECT
    'dim_member',
    COUNT(*)
FROM dbo.dim_member

UNION ALL

SELECT
    'dim_provider',
    COUNT(*)
FROM dbo.dim_provider

UNION ALL

SELECT
    'dim_service',
    COUNT(*)
FROM dbo.dim_service

UNION ALL

SELECT
    'fact_claims',
    COUNT(*)
FROM dbo.fact_claims

UNION ALL

SELECT
    'fact_quality_measures',
    COUNT(*)
FROM dbo.fact_quality_measures

UNION ALL

SELECT
    'fact_rx_fills',
    COUNT(*)
FROM dbo.fact_rx_fills

ORDER BY object_name;

GO

/* -----------------------------------------------------------------------------
  2. Missing foreign-key matches.

  Expected result: all 0s
----------------------------------------------------------------------------- */

SELECT
    'claims_missing_member' AS check_name,
    COUNT(*) AS issue_count
FROM dbo.fact_claims AS c
LEFT JOIN dbo.dim_member AS m
  ON m.member_id = c.member_id
WHERE m.member_id IS NULL

UNION ALL

SELECT
    'claims_missing_provider',
    COUNT(*)
FROM dbo.fact_claims AS c
LEFT JOIN dbo.dim_provider AS p
  ON p.provider_id = c.provider_id
WHERE p.provider_id IS NULL

UNION ALL

SELECT
    'claims_missing_service',
    COUNT(*)
FROM dbo.fact_claims AS c
LEFT JOIN dbo.dim_service AS s
  ON s.service_code = c.service_code
WHERE s.service_code IS NULL

UNION ALL

SELECT
    'rx_missing_member',
    COUNT(*)
FROM dbo.fact_rx_fills AS r
LEFT JOIN dbo.dim_member AS m
  ON m.member_id = r.member_id
WHERE m.member_id IS NULL

UNION ALL

SELECT
    'rx_missing_drug',
    COUNT(*)
FROM dbo.fact_rx_fills AS r
LEFT JOIN dbo.dim_drug AS d
  ON d.ndc_code = r.ndc_code
WHERE d.ndc_code IS NULL

UNION ALL

SELECT
    'quality_missing_member',
    COUNT(*)
FROM dbo.fact_quality_measures AS q
LEFT JOIN dbo.dim_member AS m
  ON m.member_id = q.member_id
WHERE m.member_id IS NULL;

GO

/* -----------------------------------------------------------------------------
  3. Basic claim sanity checks
----------------------------------------------------------------------------- */

SELECT
    MIN(claim_date) AS earliest_claim_date,
    MAX(claim_date) AS latest_claim_date,
    MIN(allowed_amount) AS lowest_allowed_amount,
    MAX(allowed_amount) AS highest_allowed_amount,
    SUM(CASE WHEN allowed_amount < 0 THEN 1 ELSE 0 END) AS negative_allowed_amount_rows
FROM dbo.fact_claims;
GO

/* -----------------------------------------------------------------------------
  4. Confirm important views return rows
----------------------------------------------------------------------------- */

SELECT
    'vw_member_month' AS object_name,
    COUNT(*) AS row_count
FROM dbo.vw_member_month

UNION ALL

SELECT
    'vw_claims_enriched',
    COUNT(*)
FROM dbo.vw_claims_enriched

UNION ALL

SELECT
    'vw_payer_kpis_by_year',
    COUNT(*)
FROM dbo.vw_payer_kpis_by_year

UNION ALL

SELECT
    'vw_payer_kpis_by_year',
    COUNT(*)
FROM dbo.vw_payer_kpis_by_year

UNION ALL

SELECT
    'vw_monthly_pmpm_trend',
    COUNT(*)
FROM dbo.vw_monthly_pmpm_trend

UNION ALL

SELECT
    'vw_quality_measure_summary',
    COUNT(*)
FROM dbo.vw_quality_measure_summary

UNION ALL

SELECT
    'vw_member_year_base',
    COUNT(*)
FROM dbo.vw_member_year_base

UNION ALL

SELECT
    'vw_member_targeting',
    COUNT(*)
FROM dbo.vw_member_targeting

ORDER BY object_name;

GO

/* -----------------------------------------------------------------------------
  5. Targeting distribution. This should produce a mix of targeted and non-targeted rows.
----------------------------------------------------------------------------- */

SELECT
    measurement_year,
    targeting_tier,
    COUNT(*) AS member_year_rows,
    SUM(is_targeted_member) AS is_targeted_member_year_rows,
    CAST(1.0 * SUM(is_targeted_member) / NULLIF(COUNT(*), 0) AS DECIMAL(6,4)) AS targeted_rate
FROM dbo.vw_member_targeting
GROUP BY measurement_year, targeting_tier
ORDER BY measurement_year, targeting_tier;
GO

/* -----------------------------------------------------------------------------
  6. Annual KPI preview
----------------------------------------------------------------------------- */

SELECT *
FROM dbo.vw_payer_kpis_by_year
ORDER BY measurement_year;
GO