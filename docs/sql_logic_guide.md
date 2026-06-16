# SQL Logic Guide

This guide explains the main SQL logic in plain English so the project is easier to discuss in interviews.

## 1. Why the Project Uses Fact and Dimension Tables

The project separates descriptive information from event/activity information.

Dimensions answer "who, what, where, and when" questions:

- Which member?
- Which provider?
- Which service?
- Which date?
- Which drug class?

Fact tables answer "what happened" questions:

- A medical claim happened.
- A pharmacy fill happened.
- A quality measure result was recorded.

This structure makes it easier to build reusable reporting views and Power BI visuals.

## 2. Member-Month Logic

The most important view is `vw_member_month`.

It creates one row for every month that a member is enrolled. For example:

- A member enrolled January through December contributes 12 member months.
- A member enrolled January through March contributes 3 member months.

This is important becusae healthcare cost and utilization should be adjusted for enrollment exposure.

## 3. PMPM Calculation

PMPM means per member per month.

```text
Medical PMPM = Total Allowed Medical Cost / Member Months
```

The SQL uses `NULLIF(member_months, 0)` to avoid dividing by zero.

Example:

```sql
CAST(total_allowed_medical_cost / NULLIF(member_months, 0) AS DECIMAL(12,2))
```

This converts the result to a clean currency-style number with two decimal places.

## 4. ED Visits per 1,000 Member Months

The ED utilization rate is normalized to 1,000 member months.

```text
ED Visits per 1,000 Member Months = ED Visits / Member Months * 1,000
```

This makes ED utilization easier to compare across groups with different enrollment sizes.

## 5. Why the SQL Uses CTEs

CTEs make the logic easier to read.

Instead of writing one large query, the scripts break the work into named steps.
For example:

1. Count member months.
2. Summarize claims.
3. Join the two summaries.
4. Calculate final metrics.

Breaking the logic into smaller steps makes the queries easier to understand and maintain.

## 6. Why the SQL Uses `CASE`

`CASE` is used to create flags and conditional counts.

Examples:

```sql
SUM(CASE WHEN ed_flag = 1 THEN 1 ELSE 0 END) AS ed_visits
```

This counts only claims where the ED flag equals 1.

```sql
CASE WHEN member_months >= 6 AND ed_visits >= 4 THEN 1 ELSE 0 END
```

This creates a 1/0 flag for ED super-utilizers.

## 7. Why the SQL Uses `CUME_DIST()`

`CUME_DIST()` is a window function used to find members near the top of the cost distribution.

In this project, it is used to flag member at or above the 99th percentile of annual allowed medical cost.

Plain-language explanation:

> I used a window function to rank members within each year by annual cost, then flagged the members with costs at the very top of the overall distribution.

## 8. Care-Management Targeting Logic

The final targeting view uses three transparent business rules:

1. Top 1% cost member
2. ED super-utilizer
3. Rising PMPM member

The goal is not to predict clinical outcomes. The goal is to build a practical review list that a care-management team could use as a starting point.

## 9. Validation Logic

The validation script checks the following:

- whether the expected number of records loaded,
- whether foreign-key relationships match,
- whether claim amoints and dates look reasonable,
- whether views return rows,
- and whether targeting flags produce a reasonable distribution.

This is important because analytics is not just about creating dashboards; one also needs to make sure the underlying data is accurate and trustworthy. 