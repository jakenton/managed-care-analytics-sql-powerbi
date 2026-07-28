# Power BI Build Guide

## Project Goal

The goal of this dashboard is to demonstrate how healthcare analytics can be used to understand health plan performance, identify cost and utilization trends, and prioritize members for care-management review.

 The dashboard is built on top of the SQL Server reporting views included in this project.

 ---

 # Dashboard Structure

 The report contains three pages.

 1. Executive Overview
 2. Cost & Utilization Analysis
 3. Care Management Targeting

 The pages are designed to tell a complete analytical story, beginning with overall perfromance, drilling into operational drivers, and ending with actionable member targeting.

 ---

 # Page 1 - Executive Overview

## Business Question

How is the health plan performing overall?

## Primary Audience

- Healthcare Analytics Manager
- Population Health Director
- Managed Care Leadership

## SQL Views

- vw_payer_kpis_by_year
- vw_payer_kpis_by_service_area_year
- vw_monthly_pmpm_trend

## KPI Cards

- Enrolled Members
- Member Months
- Total Allowed Medical Cost
- Medical PMPM
- ED Visits per 1,000 Member Moths

## Visuals

- Monthly Medical PMPM Trend
- Medical PMPM by Service Area
- ED Visits per 1,000 Member Months by Service Area

## Filters

- Measurement Year

---

# Page 2 - Cost & Utilization Analysis

## Business Question

Where are healthcare costs and utilization concentrated?

## Primary Audience

- Healthcare Data Analyst
- Population Health Analyst
- Managed Care Operations

## SQL Views

- vw_claims_enriched
- vw_quality_measure_summary

## Visuals

- Total Allowed Cost by Service Category
- Total Allowed Cost by Provider Specialty
- Claim Volume by Service Category
- Medical PMPM by Risk Category
- Medical PMPM by Plan Type
- Quality Measure Compliance Rate

## Filters

- Measurement Year
- Service Area
- Plan Type

---

# Page 3 - Care Management Targeting

## Business Question

Which members should receive additional review by a care-management team?

## Primary Audience

- Care Management
- Population Health
- Clinical Operations

## SQL Views

- vw_member_targeting

## KPI Cards

- Targeted Member
- Percent of Members Targeted
- Top 1% Cost Members
- ED Super-Utilizers
- Rising PMPM Members

## Visuals

- Targeting Tier Distribution
- Targeted Members by Service Area
- Targeted Members by Risk Category
- Targeted Members by Plan Type

## Detail Table

Display the following fields:

- Member ID
- Measurement Year
- Service Area
- Plan Type
- Risk Category
- Medical PMPM
- ED Visists
- Targeting Tier

---

# Dashboard Design Principles

This dashboard follows several design principles.

- Present summary metrics before detailed analysis
- Normalize costs and utilization using member months where appropriate
- Keep dashboards uncluttered
- Use consistent colors and formatting across all pages
- Prioritize readability over visual complexity

---

# Validation

After building each page:

- Compare Power BI values against the SQL validation queries
- Confirm KPI values match the SQL reporting views
- Verify slicers filter all visuals correctly
- Confirm calculated measures produce expected values

---

# Project Outcome

This dashboard demonstrates an end-to-end healthcare analytics workflow:

1. Relational database design
2. SQL Server data loading
3. Reporting view development
4. Data validation
5. Power BI dashboard development
6. Business-focused analytical storytelling