/*
04_member_tatgeting_views.sql

Purpose: Create member-level views for care-management targeting.

Scope note:
  This is rule-based segmentation for analytics practice. It is not a clinical pediction model. The goal is to create a transparent list of members who may deserve furthe review because of high cost, high ED use, or rising cost.
*/

USE ManagedCarePortfolio;
GO

/* -----------------------------------------------------------------------------
  1. Member-year base

  Grain: one row per member per year.
  Includes enrollment exposure, medical allowed cost, ED visits, PMPM, and ED rate.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_member_year_base AS
WITH member_months AS (
    SELECT
        member_id,
        measurement_year,
        COUNT(*) AS member_months
    FROM dbo.vw_member_month
    GROUP BY member_id, measurement_year
),
claims_by_member_year AS (
    SELECT
        member_id,
        YEAR(claim_date) AS measurement_year,
        SUM(allowed_amount) AS total_allowed_medical_cost,
        SUM(CASE WHEN ed_flag = 1 THEN 1 ELSE 0 END) AS ed_visits
    FROM dbo.fact_claims
    GROUP BY member_id, YEAR(claim_date)
)
SELECT
    mm.member_id,
    mm.measurement_year,
    mm.member_months,
    COALESCE(c.total_allowed_medical_cost, 0) AS total_allowed_medical_cost,
    COALESCE(c.ed_visits, 0) AS ed_visits,
    CAST(COALESCE(c.total_allowed_medical_cost, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS medical_pmpm,
    CAST(1000.0 * COALESCE(c.ed_visits, 0) / NULLIF(mm.member_months, 0) AS DECIMAL(12,2)) AS ed_visits_per_1000_member_months
FROM member_months AS mm
LEFT JOIN claims_by_member_year AS c
  ON c.member_id = mm.member_id
 AND c.measurement_year = mm.measurement_year;
GO

/* -----------------------------------------------------------------------------
  2. Top-cost member flag

  Uses CUME_DIST() to rank members within each year by total allowed cost.
  A member at or above the 99th percenrile is flagged as top 1% cost.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_member_year_top_cost AS
WITH ranked AS (
    SELECT
    b.*,
    CUME_DIST() OVER (
        PARTITION BY b.measurement_year
        ORDER BY b.total_allowed_medical_cost
    ) AS cost_percentile
    FROM dbo.vw_member_year_base b
)
SELECT
    r.*,
    CASE WHEN r.cost_percentile >= 0.99 THEN 1 ELSE 0 END AS is_top_1pt_cost
FROM ranked r;
GO

/* -----------------------------------------------------------------------------
  3. ED super-utilizer flag

  Definition used here:
    - at least 6 enrolled member months in the year, and
    - at least 4 ED visits in the year
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_member_year_ed_superutilizer AS
SELECT
    b.*,
    CASE
        WHEN b.member_months >= 6 AND b.ed_visits >= 4 THEN 1
        ELSE 0
    END AS is_ed_superutilizer
FROM dbo.vw_member_year_base b;
GO

/* -----------------------------------------------------------------------------
  4. Rising PMPM flag for 2025

  Compares each member's 2024 PMPM to 2025 PMPM.

  Exposure gate:
    - at least 6 member months in both years

  Rising-cost rule:
    - 2025 PMPM is at least $150 higher than 2024
    OR
    - 2025 PMPM is at least 25% higher than 2024
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_member_rising_pmpm_2025 AS
WITH pmpm_2024 AS (
    SELECT
        member_id,
        member_months AS member_months_2024,
        medical_pmpm AS medical_pmpm_2024
    FROM dbo.vw_member_year_base
    WHERE measurement_year = 2024
),
pmpm_2025 AS (
    SELECT
        member_id,
        member_months AS member_months_2025,
        medical_pmpm AS medical_pmpm_2025
    FROM dbo.vw_member_year_base
    WHERE measurement_year = 2025
)
SELECT
    y25.member_id,
    y24.member_months_2024,
    y25.member_months_2025,
    y24.medical_pmpm_2024,
    y25.medical_pmpm_2025,
    CAST(y25.medical_pmpm_2025 - y24.medical_pmpm_2024 AS DECIMAL(12,2)) AS pmpm_change_amount,
    CAST(
        CASE
            WHEN y24.medical_pmpm_2024 = 0 THEN NULL
            ELSE (y25.medical_pmpm_2025 - y24.medical_pmpm_2024) / y24.medical_pmpm_2024
        END AS DECIMAL(8,4)
    ) AS pmpm_change_percent,
    CASE
        WHEN y24.member_months_2024 >= 6
         AND y25.member_months_2025 >= 6
         AND (
                y25.medical_pmpm_2025 - y24.medical_pmpm_2024 >= 150
            OR (
                    y24.medical_pmpm_2024 > 0
                AND (y25.medical_pmpm_2025 - y24.medical_pmpm_2024) / y24.medical_pmpm_2024 >= 0.25
            )
         )
        THEN 1
        ELSE 0
    END AS is_rising_pmpm_2025
FROM pmpm_2025 AS y25
JOIN pmpm_2024 AS y24
  ON y24.member_id = y25.member_id;
GO

/* -----------------------------------------------------------------------------
  5. Final member targeting view

  This combines member attributes with targeting flags.
  The tier order is intentional: top-cost members are hights priority, followed by ED super-utilizers, then rising-cost members.
----------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_member_targeting AS
WITH base AS (
    SELECT
        b.member_id,
        b.measurement_year,
        b.member_months,
        b.total_allowed_medical_cost,
        b.ed_visits,
        b.medical_pmpm,
        b.ed_visits_per_1000_member_months,
        m.service_area,
        m.subregion,
        m.plan_type,
        m.risk_category
    FROM dbo.vw_member_year_base AS b
    JOIN dbo.dim_member AS m
      ON m.member_id = b.member_id
),
flags AS (
    SELECT
        base.*,
        COALESCE(tc.is_top_1pt_cost, 0) AS is_top_1pt_cost,
        COALESCE(ed.is_ed_superutilizer, 0) AS is_ed_superutilizer,
        CASE
            WHEN base.measurement_year = 2025 THEN COALESCE(rp.is_rising_pmpm_2025, 0)
            ELSE 0
        END AS is_rising_pmpm
    FROM base
    LEFT JOIN dbo.vw_member_year_top_cost AS tc
      ON tc.member_id = base.member_id
     AND tc.measurement_year = base.measurement_year
    LEFT JOIN dbo.vw_member_year_ed_superutilizer AS ed
      ON ed.member_id = base.member_id
     AND ed.measurement_year = base.measurement_year
    LEFT JOIN dbo.vw_member_rising_pmpm_2025 AS rp
      ON rp.member_id = base.member_id
)
SELECT
    flags.*,
    CASE
        WHEN is_top_1pt_cost = 1
        OR is_ed_superutilizer = 1
        OR is_rising_pmpm = 1
        THEN 1
        ELSE 0
    END AS is_targeted_member,
    CASE
        WHEN is_top_1pt_cost = 1 THEN 'Tier 1 - Top 1% cost'
        WHEN is_ed_superutilizer = 1 THEN 'Tier 2 - ED super-utilizer'
        WHEN is_rising_pmpm = 1 THEN 'Tier 3 - Rising PMPM'
        ELSE 'Not targeted'
    END AS targeting_tier
FROM flags;
GO