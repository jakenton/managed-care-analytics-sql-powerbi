
/* ===========================================================================
Risk Stratification + Care Management Targeting
Tech: SQL Server (T-SQL)

Prerequisites:
 - dbo.vw_member_month exists
 - dbo.fact_claims exists and is populated

Output Views:
 1) dbo.vw_member_year_base
 2) dbo.vw_member_year_top1pct
 3) dbo.vw_member_rising_pmpm_2025
 4) dbo.vw_member_year_ed_superutilizer
 5) dbo.vw_member_targeting    (unified Power BI ready)

============================================================================ */

USE ManagedCarePortfolio;
GO

/* ===========================================================================
1) vw_member_year_base
Purpose: Create a member-year analytic base at the grain: (member_id, year)

Includes:
 - member_months (exposure)
 - total_allowed_med (annual allowed)
 - ed_visits (annual ED count)
 - pmpm_med (allowed / member_months)

============================================================================ */

CREATE OR ALTER VIEW vw_member_year_base AS

-- mm: enrollment exposure by member-year from the member-month spine
WITH mm AS (
  SELECT member_id,
    YEAR(vm.month_start) AS year,
    COUNT(*) AS member_months
  FROM dbo.vw_member_month vm
  GROUP BY
    vm.member_id,
    YEAR(vm.month_start)
),

-- cy: annual claims rollup by member-year from the claims fact
cy AS (
  SELECT
    c.member_id,
    YEAR(c.claim_date) AS year,
    SUM(c.allowed_amount) AS total_allowed_med,
    SUM(CASE WHEN c.ed_flag = 1 THEN 1 ELSE 0 END) AS ed_visits
  FROM dbo.fact_claims c
  GROUP BY
    c.member_id,
    YEAR(c.claim_date)
)

-- Combine exposure + cost/utilization
SELECT
  mm.member_id,
  mm.year,
  mm.member_months,

-- If a member has enrollment but no claims in that year, treat spend/ED as 0
  ISNULL(cy.total_allowed_med,0) AS total_allowed_med,
  ISNULL(cy.ed_visits,0) AS ed_visits,

-- PMPM: per-member-per-month cost, uses exposure denominator
  CASE
    WHEN mm.member_months = 0 THEN NULL
    ELSE 1.0 * ISNULL(cy.total_allowed_med, 0) / mm.member_months
  END AS pmpm_med
FROM mm
LEFT JOIN cy
    ON cy.member_id = mm.member_id
    AND cy.year = mm.year;
GO

/* ===============================================================================
2) vw_member_year_top1pct
Purpose: Flag members whose annual allowed spend is in the top 1% within each year

Method:
 PERCENT_RANK() returns values in [0, 1].
 >= 0.99 approximates "top 1%" within each year.

================================================================================= */

CREATE OR ALTER VIEW dbo.vw_member_year_top1pct AS
SELECT
    b.*,

    -- Within each year, rank members by total_allowed_med
    CASE
        WHEN PERCENT_RANK() OVER (
                PARTITION BY b.year
                ORDER BY b.total_allowed_med
            ) >= 0.99
        THEN 1 ELSE 0
    END AS is_top_1pct_cost
FROM dbo.vw_member_year_base b;
GO

/* ===========================================================================
3) vw_member_rising_pmpm_2025
Purpose: Identify members whose PMPM meaningfully increased from 2024 to 2025,
         indicating "rising risk" even if they are not yet top 1%.

Exposure thresholds (to reduce noise):
 - >= 6 member_months in 2024 AND += 6 member-months in 2025

 Rising logic (reasonable, interpretable thresholds):
 - absolte increase >= $150 PMPM
   OR
 - relative increase >= 25%

============================================================================ */

CREATE OR ALTER VIEW dbo.vw_member_rising_pmpm_2025 AS
WITH y24 AS (
    SELECT
        member_id,
        member_months AS member_months_2024,
        pmpm_med      AS pmpm_2024
    FROM dbo.vw_member_year_base
    WHERE year = 2024
),
y25 AS (
    SELECT
        member_id,
        member_months AS member_months_2025,
        pmpm_med      AS pmpm_2025
    FROM dbo.vw_member_year_base
    WHERE year = 2025
)
SELECT
    y25.member_id,

    -- Keep 2024 + 2025 PMPM for explainability
    y24.member_months_2024,
    y25.member_months_2025,
    y24.pmpm_2024,
    y25.pmpm_2025,

    -- Absolute and percent change
    (y25.pmpm_2025 - y24.pmpm_2024) AS pmpm_delta,
    CASE
        WHEN y24.pmpm_2024 IS NULL OR y24.pmpm_2024 = 0 THEN NULL
        ELSE (y25.pmpm_2025 - y24.pmpm_2024) / y24.pmpm_2024
    END AS pmpm_pct_change,

    -- Rising PMPM flag with exposure gating + thresholds
    CASE
        WHEN y24.member_months_2024 >= 6
        AND y25.member_months_2025 >= 6
        AND (
            (y25.pmpm_2025 - y24.pmpm_2024) >= 150
            OR
            (
                y24.pmpm_2024 > 0
                AND (y25.pmpm_2025 - y24.pmpm_2024) / y24.pmpm_2024 >= 0.25
            )
        )
        THEN 1 ELSE 0
    END AS is_rising_pmpm_2025
FROM y25
JOIN y24
ON y24.member_id = y25.member_id;
GO

/* ========================================================================
4) vw_member_year_ed_superutilizer
Purpose: Flag members with very high ED use in a year,
         with an exposire minimum to avoid partial-year noise.

Rule:
 - member_months >= 6
 - ed_visits >= 4

========================================================================== */

CREATE OR ALTER VIEW dbo.vw_member_year_ed_superutilizer AS
SELECT
    b.*,
    CASE
        WHEN b.member_months >= 6 AND b.ed_visits >= 4
        THEN 1 ELSE 0
    END AS is_ed_superutilizer
FROM dbo.vw_member_year_base b;
GO

/* ===========================================================================
5) vw_member_targeting (POWER BI-ready unified output)
Purpose: One table to drive the "Care Management Targeting" page.

Adds:
 - is_top_1pct_cost
 - is_rising_pmpm_2025 (only meaninful for year = 2025)
 - is_ed_superutilizer
 - is_targeted_member (any flag)
 - targeting_tier

 Also joins in dim_member attributes to support slicing the following:
 - service_are, subregion, plan_type, risk_category

============================================================================ */

CREATE OR ALTER VIEW dbo.vw_member_targeting AS
WITH base_enriched AS (
    SELECT
        b.member_id,
        b.year,
        b.member_months,
        b.total_allowed_med,
        b.ed_visits,
        b.pmpm_med,

        -- Bring member attributes or slicing in Power BI
        m.service_area,
        m.subregion,
        m.plan_type,
        m.risk_category
    FROM dbo.vw_member_year_base b
    JOIN dbo.dim_member m
    ON m.member_id = b.member_id
),

flags AS (
    SELECT
        be.*,

        -- Top 1% annual cost flag (year-specific)
        ISNULL(t.is_top_1pct_cost, 0) AS is_top_1pct_cost,

        -- ED super-utilizer flag (year-specific)
        ISNULL(e.is_ed_superutilizer, 0) AS is_ed_superutilizer,

        -- Rising PMPM flag (only defined for 2025 members with 2024 + 2025 exposure)
        CASE
            WHEN be.year = 2025 THEN ISNULL(r.is_rising_pmpm_2025, 0)
            ELSE 0
        END AS is_rising_pmpm
    FROM base_enriched be
    LEFT JOIN dbo.vw_member_year_top1pct t
        ON t.member_id = be.member_id
        AND t.year = be.year
    LEFT JOIN dbo.vw_member_year_ed_superutilizer e
        ON e.member_id = be.member_id
        AND e.year = be.year
    LEFT JOIN dbo.vw_member_rising_pmpm_2025 r
        ON r.member_id = be.member_id
)

SELECT
    f.*,

    -- Any-flag targeting indicator
    CASE
        WHEN f.is_top_1pct_cost = 1
            OR f.is_ed_superutilizer = 1
            OR f.is_rising_pmpm = 1
        THEN 1 ELSE 0
    END AS is_targeted_member,

    /* Tiering logic (simple + explainable):
       Tier 1: Top 1% cost (highest priority)
       Tier 2: ED super-utilizer (urgent utilization)
       Tier 3: Rising PMPM (emerging risk)
       Not Targeted: None of the above
    */
    CASE
        WHEN f.is_top_1pct_cost = 1
            THEN 'Tier 1: Top 1% cost'
        WHEN f.is_ed_superutilizer = 1
            THEN 'Tier 2: ED super-utilizer'
        WHEN f.is_rising_pmpm = 1
            THEN 'Tier 3: Rising PMPM'
        ELSE 'Not targeted'
    END AS targeting_tier

FROM flags f;
GO


-- View sample high-cost members
SELECT TOP 20 *
FROM dbo.vw_member_targeting
ORDER BY year DESC, total_allowed_med DESC;

-- Distribution check
SELECT year,
    COUNT(DISTINCT member_id) AS total_members,
    SUM(is_top_1pct_cost) AS top_1pct_members,
    SUM(is_ed_superutilizer) AS ed_superutilizers
FROM dbo.vw_member_targeting
GROUP BY year
ORDER BY year;

-- Verification that vw_member_month exists:
SELECT
  s.name AS schema_name,
  v.name AS view_name
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE v.name = 'vw_member_month';

-- Sanity check that vw_member_month has data:
SELECT TOP 10 *
FROM dbo.vw_member_month;

SELECT COUNT(*) AS n_rows
FROM dbo.vw_member_month;

-- Check views exist:
SELECT v.name
FROM sys.views v
WHERE v.name IN (
    'vw_member_year_base',
    'vw_member_year_top1pct',
    'vw_member_rising_pmpm_2025',
    'vw_member_year_ed_superutilizer',
    'vw_member_targeting'
)
ORDER BY v.name;

-- Confirm targeting output:
SELECT TOP 20 *
FROM dbo.vw_member_targeting
ORDER BY
    is_targeted_member DESC,
    total_allowed_med DESC;

-- Check number of targeted members by year/tier:
SELECT
 year,
 targeting_tier,
 COUNT(DISTINCT member_id) AS members
FROM dbo.vw_member_targeting
WHERE is_targeted_member = 1
GROUP BY year, targeting_tier
ORDER BY year, targeting_tier;
