USE ManagedCarePortfolio;
GO

/* =============================================================================
Core Analytics Layer: Member-Month Spine & Payer KPIs
Tech: SQL Server (T-SQL)

Prerequisites:
 Creates the foundational analytical views used throughout the project,
 centered on a member-month enrollment spine that enables accurate
 exposure-adjusted payer metrics (e.g., PMPM).

Primary Output:
 - dbo.vw_member_month
   (one row per member per enrolled month)

Design Rationale:
 - Member-month is the standard denominator for managed care analytics.
 - Centralizing this logic prevents inconsistent PMPM calculations.
 - Downstream risk stratification and Power BI reporting depend on this view.

================================================================================ */

CREATE OR ALTER VIEW dbo.vw_member_month AS
SELECT
  m.member_id,
  d.month_start,         -- month start date used as the monthly grain key
  m.service_area,
  m.subregion,
  m.plan_type,
  m.risk_category
FROM dbo.dim_member m
JOIN dbo.dim_date d
  ON d.date BETWEEN m.enrollment_start_date AND m.enrollment_end_date;
WHERE d.date = d.month_start;
GO