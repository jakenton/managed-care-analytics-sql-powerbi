
/* ===========================================================================
Core Analytics Layer: Member-Month Spine & Payer KPIs
Tech: SQL Server (T-SQL)

Prerequisites:
 Creates the foundational analytical views used throughout the project,
 centered on a member-month enrollment spine that enables accurate
 exposure-adjusted payer metrics.

Primary Output:
 - dbo.vw_member_month
   (one row per member per enrolled month)

Key Analytics Enabled:
 - Per Member Per Month (PMPM) cost calculations
 - ED utilization per 1,000 member-months
 - Stratification by service area, plan type, and risk category
 - Alignment of claims, pharmacy, and quality data to a common denominator

Design Rationale:
 - Member-month is the standard denominator for managed care analytics
 - Centralizing this logic prevents duplicated or inconsistent PMPM logic
 - Downstream risk stratification and Power BI reporting depend on this view

============================================================================ */

CREATE OR ALTER VIEW vw_member_month AS
SELECT
  m.member_id,
  d.month_start,
  m.service_area,
  m.subregion,
  m.plan_type,
  m.risk_category
FROM dim_member m
JOIN dim_date d
  ON d.date BETWEEN m.enrollment_start_date AND m.enrollment_end_date;
GO

-- Run risk_stratification.sql next
SELECT TOP 20 *
FROM dbo.vw_member_month;

SELECT COUNT(*) AS member_month_rows
FROM dbo.vw_member_month;