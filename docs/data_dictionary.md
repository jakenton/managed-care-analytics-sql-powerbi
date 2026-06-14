# Data Dictionary

This project uses fully synthetic payer-style data. It is designed to resemble a simplified managed care reporting environment.

## Source Tables

### `dim_member`

Grain: one row per member

| Column                  | Type    | Description                                     |
| ----------------------- | ------- | ----------------------------------------------- |
| `member_id`             | INT     | Unique synthetic member identifier              |
| `service_area`          | VARCHAR | State or market area, such as AZ, NM, or TX     |
| `subregion`             | VARCHAR | Smaller geographic area within the service area |
| `plan_type`             | VARCHAR | Synthetic insurance product type                |
| `risk_category`         | VARCHAR | Baseline risk group used for reporting slices   |
| `enrollment_start_date` | DATE    | First enrolled date in the simulated period     |
| `enrollment_end_date`   | DATE    | Last enrolled date in the simulated period      |

### `dim_provider`

Grain: one row per provider

| Column          | Type    | Description                                                       |
| --------------- | ------- | ----------------------------------------------------------------- |
| `provider_id`   | INT     | Unique synthetic provider identifier                              |
| `provider_type` | VARCHAR | Provider grouping, such as PCP, Specialist, Hospital, or Facility |
| `specialty`     | VARCHAR | Provider specialty                                                |
| `service_area`  | VARCHAR | Provider service area                                             |

### `dim_service`

Grain: one row per medical service code

| Column                | Type    | Description                                                          |
| --------------------- | ------- | -------------------------------------------------------------------- |
| `service_code`        | VARCHAR | Synthetic medical service code                                       |
| `service_category`    | VARCHAR | Service category, such as ED, Inpatient, Outpatient, Imaging, or Lab |
| `service_description` | VARCHAR | Plain-language service desciption                                    |

### `dim_drug`

Grain: one row per synthetic drug code

| Column       | Type    | Description               |
| ------------ | ------- | ------------------------- |
| `ndc_code`   | VARCHAR | Synthetic drug identifier |
| `drug_class` | VARCHAR | Drug class                |

### `dim_date`

Grain: one row per calendar date

| Column        | Type | Description                          |
| ------------- | ---- | ------------------------------------ |
| `date`        | DATE | Calendar date                        |
| `year`        | INT  | Calendar year                        |
| `month`       | INT  | Calendar month number                |
| `month_start` | DATE | First day of the corresponding month |

### `fact_claims`

Grain: one row per synthetic medical claim

| Column           | Type    | Description                                              |
| ---------------- | ------- | -------------------------------------------------------- |
| `claim_id`       | INT     | Unique synthetic claim identifier                        |
| `member_id`      | INT     | Member associated with the claim                         |
| `provider_id`    | INT     | Provider associated with the claim                       |
| `service_code`   | VARCHAR | Medical service code                                     |
| `claim_date`     | DATE    | Claim date                                               |
| `allowed_amount` | DECIMAL | Synthetic allowed medical cost                           |
| `ed_flag`        | BIT     | Indicates whether the claim is counted as ED utilization |

### `fact_rx_fills`

Grain: one row per synthetic pharmacy fill

| Column        | Type    | Description                               |
| ------------- | ------- | ----------------------------------------- |
| `rx_id`       | INT     | Unique synthetic pharmacy-fill identifier |
| `member_id`   | INT     | Member associated with the pharmacy fill  |
| `pharmacy_id` | INT     | Synthetic pharmacy identifier             |
| `ndc_code`    | VARCHAR | Synthetic drug identifier                 |
| `fill_date`   | DATE    | Fill date                                 |
| `days_supply` | DECIMAL | Days supplied                             |

### `fact_quality_measures`

Grain: one row per member, measure, and measurement year

| Column             | Type    | Description                        |
| ------------------ | ------- | ---------------------------------- |
| `member_id`        | INT     | Unique synthetic claim identifier  |
| `measure_name`     | INT     | Member associated with the claim   |
| `eligible_flag`    | INT     | Provider associated with the claim |
| `compliant_flag`   | VARCHAR | Medical service code               |
| `measurement_year` | DATE    | Claim date                         |

## Derived Views

### `vw_member_month`

Grain: one row per member per enrolled month

Purpose: provides the denominator for PMPM and utilization-rate calculations

### `vw_claims_enriched`

Grain: one row per claim

Purpose: joins claim records to member, provider, and service attributes for reporting

### `vw_payer_kpis_by_year`

Grain: one row per year

Purpose: annual payer summary metrics, including enrolled members, member months, total allowed medical cost, medical PMPM, and ED visits per 1,000 member months

### `vw_payer_kpis_by_service_area_year`

Grain: one row per service are per year

Purpose: compares payer KPIs across markets/service areas

### `vw_monthly_pmpm_trend`

Grain: one row per month

Purpose: supports monthly trend reporting for PMPM and ED utilization

### `vw_quality_measure_summary`

Grain: one row per measure per year

Purpose: summarizes eligible members, compliant members, and compliance rates

### `vw_member_year_base`

Grain: one row per member per year

Purpose: creates the base member-year table used for targeting logic

### `vw_member_year_top_cost`

Grain: one row per member per year

Purpose: flags members at or above the 99th percentile of annual allowed medical cost

### `vw_member_year_ed_superutilizer`

Grain: one row per member per year

Purpose: flags member with at least six months of enrollment and at least four ED visits in the year

### `vw_member_rising_pmpm_2025`

Grain: one row per member with both 2024 and 2025 exposure

Purpose flags members whose PMPM increased meaningfully from 2024 to 2025

### `vw_member_targeting`

Grain: One row per member per year

Purpose: final Power BI-read care-management targeting view with member attributes, cost/utilization metrics, targeting flags, and tier labels