ManagedCarePortfolio;
GO

/* =============================================================================
Validation Checks: Data Load + View Outputs
Tech: SQL Server (T-SQL)

Purpose:
	Quick sanity checks to confirm:
	 - Tables are populated
	 - Keys join cleanly
	 - Required views exist and return rows
	 - Targeting flags produce reasonable distributions

NOTE:
This script does NOT modify data (no TRUNCATE/DELETE).
================================================================================ */

/* ================================================================================
1) Row-count sanity check
=================================================================================*/

SELECT  'dbo.dim_member' AS table_name, COUNT(*) AS n FROM dbo.dim_member
UNION ALL SELECT 'dbo.dim_provider', COUNT(*) FROM dbo.dim_provider
UNION ALL SELECT 'dbo.dim_service', COUNT(*) FROM dbo.dim_service
UNION ALL SELECT 'dbo.dim_drug', COUNT(*) FROM dbo.dim_drug
UNION ALL SELECT 'dbo.dim_date', COUNT(*) FROM dbo.dim_date
UNION ALL SELECT 'dbo.fact_claims', COUNT(*) FROM dbo.fact_claims
UNION ALL SELECT 'dbo.fact_rx_fills', COUNT(*) FROM dbo.fact_rx_fills
UNION ALL SELECT 'dbo.fact_quality_measures', COUNT(*) FROM dbo.fact_quality_measures
GO

/* ================================================================================
2) Key integrity checks (joins won't blow up)
=================================================================================*/

-- Claims missing member_id in dim_member
SELECT COUNT(*) AS claims_missing_member
FROM dbo.fact_claims c
LEFT JOIN dbo.dim_member m
ON m.member_id = c.member_id
Where m.member_id IS NULL;
GO

-- RX fills missing member_id in dim_member
SELECT COUNT(*) AS rx_missing_member
FROM dbo.fact_rx_fills r
LEFT JOIN dbo.dim_member m
ON m.member_id = r.member_id
WHERE m.member_id IS NULL;
GO

/* ================================================================================
3) Confirm required views exist
=================================================================================*/

SELECT
	s.name AS schema_name,
	v.name AS view_name
FROM sys.views v
JOIN sys.schemas s ON s.schema_id = v.schema_id
WHERE v.name IN (
	'vw_member_month',
	'vw_member_year_base',
	'vw_member_year_top1pct',
	'vw_member_rising_pmpm_2025',
	'vw_member_year_ed_superutilizer',
	'vw_member_targeting'
)
ORDER BY v.name;
GO

/* ================================================================================
3) Confirm required views exist
=================================================================================*/

SELECT COUNT(*) AS vw_member_month_rows
FROM dbo.vw_member_month;
GO

SELECT COUNT(*) AS vw_member_year_base_rows
FROM dbo.vw_member_year_base;
GO

SELECT COUNT(*) AS vw_member_year_base_rows
FROM dbo.vw_member_year_base;
GO

SELECT COUNT(*) AS vw_member_targeting_rows
FROM dbo.vw_member_targeting;
GO