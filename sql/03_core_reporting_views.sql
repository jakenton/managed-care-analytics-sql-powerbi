/*
03_core_reporting_views.sql

Purpose: Build reusable reporting views for Power BI and SQL analysis.

Important concept:
  The member-month view creates one row for each month a member is enrolled. This gives us the denominator for PMPM and utilization-rate calculations. In healthcare analytics, we adjust cost and utilization for how long members were actually enrolled.
*/

/* -----------------------------------------------------------------------------
  1. Member-month enrollment spine

  Grain: one row per member per enrolled month.
  Example: one member enrolled for all of 2024 contributes 12 rows for 2024.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_member_month AS
SELECT
    m.member_id,
    d.month_start,
    d.[year] AS measurement_year,
    d.[month] AS measurement_month,
    m.service_area,
    m.subregion,
    m.plan_type,
    m.risk_category
FROM dbo.dim_member m
JOIN dbo.dim_date d
  ON d.[date] = d.month_start
 AND d.month_start >= DATEFROMPARTS(YEAR(m.enrollment_start_date), MONTH(m.enrollment_start_date), 1)
 AND d.month_start <= DATEFROMPARTS(YEAR(m.enrollment_end_date), MONTH(m.enrollment_end_date), 1);
GO

/* -----------------------------------------------------------------------------
  2. Enriched claims view

  This keeps claim-level detail but adds descriptive fields form the dimensions.
  It is useful for Power BI visuals and ad hoc SQL analysis.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_claims_enriched AS
SELECT
    c.claim_id,
    c.member_id,
    c.provider_id,
    c.service_code,
    c.claim_date,
    DATEFROMPARTS(YEAR(c.claim_date), MONTH(c.claim_date), 1) AS claim_month_start,
    YEAR(c.claim_date) AS claim_year,
    c.allowed_amount,
    c.ed_flag,
    m.service_area AS member_service_area,
    m.subregion,
    m.plan_type,
    m.risk_category,
    p.provider_type,
    p.specialty,
    p.service_area AS provider_service_area,
    s.service_category,
    s.service_description
FROM dbo.fact_claims c
JOIN dbo.dim_member m
  ON m.member_id = c.member_id
JOIN dbo.dim_provider p
  ON p.provider_id = c.provider_id
JOIN dbo.dim_service s
  ON s.service_code = s.service_code;
GO

/* -----------------------------------------------------------------------------
  3. Annual payer KPI view

  This view summarizes the full population by year.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_payer_kpis_by_year AS
WITH member_months AS (
    SELECT
        measurement_year,
        COUNT(*) AS member_months,
        COUNT(DISTINCT member_id) AS enrolled_members
    FROM dbo.vw_member_month
    GROUP BY measurement_year
),
claims AS (
    SELECT
        YEAR(claim_date) AS measurement_year,
        COUNT(*) AS claim_count,
        SUM(allowed_amount) AS total_allowed_medical_cost,
        SUM(CASE WHEN ed_flag = 1 THEN 1 ELSE 0 END) AS ed_visits
    FROM dbo.fact_claims
    GROUP BY YEAR(claim_date)
)
SELECT
    mm.measurement_year,
    mm.enrolled_members,
    mm.member_months,
    COALESCE(c.claim_count, 0) AS claim_count,
    COALESCE(c.total_allowed_medical_cost, 0) AS total_allowed_medical_cost,
    COALESCE(c.ed_visits, 0) AS ed_visits,
    CAST(COALESCE(c.total_allowed_medical_cost, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS medical_pmpm,
    CAST(1000.0 * COALESCE(c.ed_visits, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS ed_visits_per_1000_member_months
FROM member_months mm
LEFT JOIN claims c
    ON c.measurement_year = mm.measurement_year;
GO

/* -----------------------------------------------------------------------------
  4. Annual payer KPI view by service area

  This supports geographic/service-market comparison.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_payer_kpis_by_service_area_year AS
WITH member_months AS (
    SELECT
        measurement_year,
        service_area,
        COUNT(*) AS member_months,
        COUNT(DISTINCT member_id) AS enrolled_members
    FROM dbo.vw_member_month
    GROUP BY measurement_year, service_area
),
claims AS (
    SELECT
        YEAR(c.claim_date) AS measurement_year,
        m.service_area,
        COUNT(*) AS claim_count,
        SUM(c.allowed_amount) AS total_allowed_medical_cost,
        SUM(CASE WHEN c.ed_flag = 1 THEN 1 ELSE 0 END) AS ed_visits
    FROM dbo.fact_claims c
    JOIN dbo.dim_member m
      ON m.member_id = c.member_id
    GROUP BY YEAR(c.claim_date), m.service_area
)
SELECT
    mm.measurement_year,
    mm.service_area,
    mm.enrolled_members,
    mm.member_months,
    COALESCE(c.claim_count, 0) AS claim_count,
    COALESCE(c.total_allowed_medical_cost, 0) AS total_allowed_medical_cost,
    COALESCE(c.ed_visits, 0) AS ed_visits,
    CAST(COALESCE(c.total_allowed_medical_cost, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS medical_pmpm,
    CAST(1000.0 * COALESCE(c.ed_visits, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS ed_visits_per_1000_member_months
FROM member_months mm
LEFT JOIN claims c
    ON c.measurement_year = mm.measurement_year
   AND c.service_area = mm.service_area;
GO

/* -----------------------------------------------------------------------------
  5. Monthly PMPM trend

  This is useful for Power BI line charts.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_monthly_pmpm_trend AS
WITH member_months AS (
    SELECT
        month_start,
        COUNT(*) AS member_months
    FROM dbo.vw_member_month
    GROUP BY month_start
),
claims AS (
    SELECT
        DATEFROMPARTS(YEAR(claim_date), MONTH(claim_date), 1) AS month_start,
        SUM(allowed_amount) AS total_allowed_medical_cost,
        SUM(CASE WHEN ed_flag = 1 THEN 1 ELSE 0 END) AS ed_visits
    FROM dbo.fact_claims
    GROUP BY DATEFROMPARTS(YEAR(claim_date), MONTH(claim_date), 1)
)
SELECT
    mm.month_start,
    YEAR(mm.month_start) AS measurement_year,
    MONTH(mm.month_start) AS measurement_month,
    mm.member_months,
    COALESCE(c.total_allowed_medical_cost, 0) AS total_allowed_medical_cost,
    COALESCE(c.ed_visits, 0) AS ed_visits,
    CAST(COALESCE(c.total_allowed_medical_cost, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS medical_pmpm,
    CAST(1000.0 * COALESCE(c.ed_visits, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS ed_visits_per_1000_member_months
FROM member_months mm
LEFT JOIN claims c
  ON c.month_start = mm.month_start;
GO

/* -----------------------------------------------------------------------------
  6. Quality measure summary

  This summarizes eligible and compliant members by measure and year.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_quality_measure_summary AS
SELECT
    measurement_year,
    measure_name,
    COUNT(*) AS member_measure_rows,
    SUM(CASE WHEN eligible_flag = 1 THEN 1 ELSE 0 END) AS eligible_members,
    SUM(CASE WHEN eligible_flag = 1 AND compliant_flag = 1 THEN 1 ELSE 0 END) AS compliant_members,
    CAST(
        1.0 * SUM(CASE WHEN eligible_flag = 1 AND compliant_flag = 1 THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN eligible_flag = 1 THEN 1 ELSE 0 END), 0)
        AS DECIMAL(6,4)
    ) AS compliance_rate
FROM dbo.fact_quality_measures
GROUP BY measurement_year, measure_name;
GO