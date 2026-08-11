# Managed Care Analytics: SQL Server + Power BI

## Project Overview

This portfolio project simulates a managed care analytics workflow using **SQL Server** and **Power BI**. The project was designed to practice working with payer-style healthcare data and translating claims, enrollment, utilization, and quality data into reporting metrics that could support operational and care-management decisions.

The worklflow uses SQL Server to organize the simulated data, calculate reusable healthcare metrics, and create reporting views. Power BI is then used to build an interactive dashboard from those views.

The project focuses on several common managed care analytics concepts, including

- Per member per month (PMPM) medical cost
- Member-month enrollment exposure
- Emergency department (ED) utilization
- Service-area comparisons
- Quality measure compliance
- High-cost member identification
- Rising-cost member identification
- Rule-based care-management targeting

**Data note:** All data used in this project is synthetic and was created for portfolio and learning purposes. The project does not contain protected health information (PHI) or real patient/member data.

---

## Business Questions

The project was built around questions that a payer or managed care analytics team might need to answer:

1. How many members are enrolled, and how much enrollment exposure do they contribute?
2. What is the plan's total allowed medical cost and medical PMPM?
3. How is medical PMPM changing over time?
4. How does medical cost vary across service area?
5. How frequently are members using the emergency department after adjusting for enrollment?
6. Which service areas have higher ED utilization?
7. How are members performing on selected quality measures?
8. Which members may warrant additiona; review because of high cost, repeated ED use, or rising PMPM?

These questions guided the SQL reporting layer and the Power BI dashboard design.

---

## Tools and Skills Demonstrated

### SQL Server

- Relational table design
- Fact and dimension tables
- Primary and foreign keys
- CSV loading with `BULK INSERT`
- Joins
- Aggregations
- Common table expressions (CTEs)
- `CASE` expressions
- Window functions
- Reusable SQL views
- Date and enrollment logic
- Data validation queries

### Power BI

- SQL Server data connections
- Data modeling and relationships
- Date dimensions
- DAX measures
- KPI cards
- Slicers
- Trend analysis
- Service-area comparisons
- Visual-level filtering
- Dashboard formatting and design

### Healthcare Analytics

- Member months
- Medical PMPM
- ED visits per 1,000 member months
- Allowed medical cost
- Enrollment-adjusted utilization
- Quality measure compliance
- High-cost member segmentation
- ED super-utilizer identification
- Rising-cost analysis

---

## Data Model

The simulated dataset follows a simplified dimensional structure.

### Dimension Tables

| Table          | Purpose                                                                        |
| -------------- | ------------------------------------------------------------------------------ |
| `dim_member`   | Member demographics, enrollment dates, plan type, risk category, and geography |
| `dim_provider` | Provider type, specialty, and service area                                     |
| `dim_service`  | Service codes, categories, and description                                     |
| `dim_drug`     | Drug and therapeutic-class information                                         |
| `dim_date`     | Calendar dates used for reporting and enrollment calculations                  |

### Fact Tables

| Table                    | Purpose                                                                |
| ------------------------ | ---------------------------------------------------------------------- |
| `fact_claims`            | Member claims, allowed amounts, services, providers, and ED indicators |
| `fact_rx_fills`          | Pharmacy fill activity                                                 |
| `fact_quality_measures`  | Member-level quality measure eligibility and compliance                |

This structure separates descriptive attributes from transactional and measurement data while supporting reusable reporting views.

---

## SQL Workflow

The SQL portion of the project is organized as a sequence of scripts.

### `01_create_tables.sql`

Creates the dimension and fact tables used by the project, including primary and foreign-key relationships.

### `02_load_data_template.sql`

Loads the simulated CSV files into SQL Server using `BULK INSERT`.

Dimension tables are loaded before fact tables so that referenced records exist before foreign-key-dependent data is inserted.

### `03_core_reporting_views.sql`

Creates reusable reporting views for Power BI and SQL analysis, including

- Member-month enrollment
- Enriched claims
- Annual payer KPIs
- Service-area payer KPIs
- Monthly PMPM trends
- Quality measure summaries

### `04_member_targeting_views.sql`

Creates member-level analytical views used for transparent, rule-based care-management targeting.

The targeting logic considers

- Top 1% annual medical cost
- ED super-utilization
- Rising PMPM

This is intentionally **rule-based segmentation rather then a clinical prediction model**.

### `05_validation_checks.sql`

Runs validation checks after the data and reporting views are created.

The checks include

- Source-table row counts
- Missing dimension/foreign-key matches
- Claim date and allowed-amount sanity checks
- Reporting-view row counts
- Targeting distributions
- Annual KPI reconciliation

---

## Core Healthcare Metrics

### Member Months

A member month represents one member enrolled for one month.

For example:

- A member enrolled for an entire year contributes **12 member months**.
- A member enrolled for three months contributes **3 member months**.

Member months provide an enrollment-adjusted denominator for comparing populations with different amounts of enrollment exposure.

### Medical PMPM

**Medical PMPM = Total Allowed Medical Cost / Member Months**

PMPM normalizes medical spending for enrollment exposure and makes cost comparisons more meaningful across periods and populations.

### ED Visits per 1,000 Member Months

**ED Visits per 1,000 Member Months = (ED Visits / Member Months) × 1,000**

This provides an enrollment-adjusted utilization rate rather than comparing raw ED visit counts.

---

## Monthly Trend Logic

During dashboard development, the initial monthly PMPM visualization showed unusually high values during early months of the simulated enrollment period.

The underlying PMPM calculation was mathematically correct: those months contained substantially fewer member months, producing a smaller denomminator.

Rather than changing or removing the underlying data, the reporting view includes an `is_steady_state_month` flag:

```sql
CASE
    WHEN member_months >= 0.90 * maximum_member_months THEN 1
    ELSE 0
END
```

This identifies months where enrollment is at least 90% of the highest monthly enrollment in the dataset.

The Power BI executive trend can therefore focus on steady-state enrollment months while preserving the complete underlying data for analysis.

This distinction is important because a technically correct metric does not always provide the clearest answer to a particular business question.

---

# Care-Management Targeting

The project creates a transparent member-level targeting framework based on three analytical rules.

### Top-Cost Members

`CUME_DIST()` is used to evaluate annual medical cost within each measurement year and identify memebers at the top of the cost distribution.

### ED Super-Utilizers

Member are flagged when they meet the project's defined enrollment and ED-use thresholds.

### Rising PMPM

2024 and 2025 member-level PMPM are compared to identify members experiencing meaninful increases in medical cost.

The final targeting view assigns members to priority tiers based on these rules.

The purpose is not to determine clinical and automatically. Instead, the output represents an anlytical review list that could serve as a starting point for further investigation.

---

## Data Validation

Validation is treated as a separate step in the workflow rather than assuming that successful query execution means the results are correct.

The validation process checks whether

- expected records loaded,
- fact records match their dimension tables,
- dates and claim amounts fall within reasonable ranges,
- reporting views return expected results,
- targeting rules produce plausible distributions,
- and key dashboard metrics reconcile with SQL results.

Validation outputs are documented separately in `validation_results.md`, with supporting CSV exports and screenshots retained as project evidence.

---

## Power BI Dashboard 

The Power BI report is designed as a multi-page managed care analytics dashboard.

### Page 1 &endash; Executive Overview

The Executive Overview summarizes plan-level performance using the following:

- Enrolled Members
- Member Months
- Total Allowed Medical Cost
- Medical PMPM
- ED Visits per 1,000 Member Months
- Monthly Medical PMPM Trend
- Medical PMPM by Service Area
- ED Utilization by Service Area

A year slicer allows the user to change the reporting period.

The page is intentionally limited to high-level measures so that the most important information can be understood quickly.

### Planned Analytical Pages

Additional dashboard pages extend the executive view into

- **Cost & Utilization Analysis**
- **Care Management Targeting**

These pages provide progressively more detailed analysis while keeping the executive overview focused.

---

## Dashboard Design

The dashboard uses a consistent visual design intended to emphasize readability rather than decorative complexity.

### Primary Palette

| Purpose            | Color     |
| ------------------ | --------- |
| Primary            | `#8C1D40` |
| Secondary          | `#6B7280` |
| Accent             | `#C9A227` |
| Positive indicator | `#2E7D32` |
| Background         | `#FAFAFA` |
| Main text          | `#2F2F2F` |

The report uses **Segoe UI** and **Segoe UI Semibold** for consistent typography.

Maroon is used as the primary data and navigation color, while muted gold is used selectively as an accent.

---

## Project Structure

```text
managed-care-analytics/
│
├── raw_data_simulated/
│   ├── dim_date.csv
│   ├── dim_drug.csv
│   ├── dim_member.csv
│   ├── dim_provider.csv
│   ├── dim_service.csv
│   ├── fact_claims.csv
│   ├── fact_quality_measures.csv
│   └── fact_rx_fills.csv
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_data_template.sql
│   ├── 03_core_reporting.views.sql
│   ├── 04_member_targeting_views.sql
│   └── 05_validation_checks.sql
│
├── validation/
│   ├── validation_results.md
│   ├── CSV outputs
│   └── validation screenshots
│
├── data_dictionary.md
├── sql_logic_guide.md
├── power_bi_build_guide.md
└── README.md
```

*Folder and file names may be adjusted as the project is finalized.*

---

## Reproducing the SQL Workflow

To build the SQL portion of the project:

1. Create the `ManagedCarePortfolio` database in SQL Server.
2. Run `01_create_tables.sql`.
3. Update the local CSV paths in `02_load_data_template.sql`.
4. Run `02_load_data_template.sql`.
5. Run `03_core_reporting_views.sql`.
6. Run `04_validation_checks.sql`.
7. Run `05_validation_checks.sql`.
8. Compare the results with the documented validation outputs.
9. Connect Power BI to the reporting views.

The scripts are intentionally numbered so that the expected execution order is clear.

---

## Documentation

The repository includes supporting documentation intended to make the analytical logic easier to review and reproduce.

- **`data_dictionary.md`** - describes tables, columns, and important fields.
- **`sql_logic_guide.md`** - explains key SQL and healthcare analytics concepts in plain language.
- **`validation_results.md`** - documents validation outputs and expected results.
- **`power_bi_build_guide.md`** - documents the dashboard structure and Power BI implementation.

Documentation is maintained alongside the code because undestandnig the assumptions and business logic behind an analysis is as important as understanding the syntax used to produce it.

---

## Project Status

**Current phase:** Power BI dashboard development and final validation.

Completed:

- SQL Server schema
- Simulated data loading workflow
- Core reporting views
- Member targeting logic
- SQL validation workflow
- Data dictionary
- SQL logic documentation
- Executive Overview dashboard development

In progress:

- Final Executive Overview formatting and validation
- Additional analytical dashboard pages
- Final repository documentation and screenshots

---

## Key Takeaways

This project demonstrates and end-to-end analytics workflow rather than a collaction of isolated SQL queries or Power BI visuals.

The project moves from

**simulated source data → relational tables → validated SQL reporting views → healthcare metrics → Power BI reporting**

The main technical lesson has been that building useful healthcare analytics requires more than calculating a metric correctly. Enrollmenent exposure, metric definitions, validation, reporting grain, and the business question being answered all affect how results should be interpreted and presented.