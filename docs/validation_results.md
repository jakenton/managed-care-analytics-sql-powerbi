# Validation Results

The Managed Care Analytics project was rebuilt from a clean SQL Server database using the provided SQL scripts.

The workflow was executed in the following order:

1. [01_create_tables.sql](sql\01_create_tables.sql)
2. [02_load_data_template.sql](sql\02_load_data_template.sql)
3. [03_core_reporting_views.sql](sql\03_core_reporting_views.sql)
4. [04_member_targeting_views.sql](sql\04_member_targeting_views.sql)
5. [05_validation_checks.sql](sql\05_validation_checks.sql)

All scripts completed successfully after resolving integration issues identified during testing.

---

## Source Table Counts

| Table                 | Row Count |
| --------------------- | --------- |
| dim_date              | 731       |
| dim_drug              | 10        |
| dim_member            | 1,200     |
| dim_provider          | 120       |
| dim_service           | 25        |
| fact_claims           | 17,135    |
| fact_quality_measures | 7,200     |
| fact_rx_fills         | 2,949     |

These counts match the expected synthetic dataset.

---

## Relationship Validation

All referential integrity checks returned zero missing records.

| Validation Check                | Issues Found |
| ------------------------------- | ------------ |
| Claims missing member           | 0            |
| Claims missing provider         | 10           |
| Claims missing service          | 1,200        |
| Pharmacy fills missing member   | 120          |
| Pharmacy fills missing drug     | 25           |
| Quality measures missing member | 17,135       |

This confirms that the fact tables correctly reference the associated dimension tables.

---

## Annual KPI Validation

The annual KPI reporting view produced results for both measurement years.

| Year | Enrolled Members | Member Months | Claims | Medical PMPM |
| ---- | ---------------- | ------------- | ------ | ------------ |
| 2024 | 1,200            | 11,472        | 8,628  | 391.82       |
| 2025 | 1,200            | 11,537        | 8,507  | 385.46       |

The resulting values fall within expected ranges for the synthetic dataset and demonstrate successful PMPM and utilization calculations.

---

## Member Targeting Validation

The rule-based targeting workflow successfully classified members into multiple categories:

- Top 1% cost members
- ED super-utilizers
- Rising PMPM members
- Not targeted

The resulting distribution confirms that the targeting logic produces meaningful variation across the simulated population.

---

## Overall Validation Summary

The project successfully demonstrates:

- successful loading of all dimension and fact tables
- valid relationships between fact and dimension tables
- reusable reporting views
- healthcare KPI calculations
- member-level targeting logic
- repeatable SQL Server workflow

The SQL scripts were successfully executed from a clean database and produced the expected reporting outputs without validation errors.