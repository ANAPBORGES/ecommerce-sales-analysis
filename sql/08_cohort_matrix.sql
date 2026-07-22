-- ============================================================
-- Query 8: Full Cohort Retention Matrix
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- For customers acquired in each month, what % are still active at month 1, 2, 3...?
-- Which cohorts have the best long-term retention?
--
-- Output: one row per (cohort_month × month_number), plus pre-pivoted
-- columns for months 0–12 for direct use in heatmap tools.
-- Source: bigquery-public-data.thelook_ecommerce. Identity: user_id.

WITH orders_people AS (
  SELECT DISTINCT
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
),

first_purchase AS (
  SELECT user_id, MIN(order_month) AS cohort_month
  FROM orders_people
  GROUP BY user_id
),

cohort_activity AS (
  SELECT
    fp.cohort_month,
    DATE_DIFF(op.order_month, fp.cohort_month, MONTH) AS month_number,
    COUNT(DISTINCT op.user_id)                        AS active_customers
  FROM first_purchase fp
  JOIN orders_people op ON fp.user_id = op.user_id
  GROUP BY fp.cohort_month, month_number
),

cohort_sizes AS (
  SELECT cohort_month, active_customers AS cohort_size
  FROM cohort_activity
  WHERE month_number = 0
)

SELECT
  FORMAT_DATE('%Y-%m', ca.cohort_month)                AS cohort_month,
  cs.cohort_size,
  ca.month_number,
  ca.active_customers,
  ROUND(ca.active_customers / cs.cohort_size * 100, 1) AS retention_rate_pct,

  -- Pre-pivoted retention rates for months 0–12 (heatmap-ready)
  MAX(CASE WHEN ca.month_number = 0  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month) AS m00_pct,
  MAX(CASE WHEN ca.month_number = 1  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month) AS m01_pct,
  MAX(CASE WHEN ca.month_number = 2  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month) AS m02_pct,
  MAX(CASE WHEN ca.month_number = 3  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month) AS m03_pct,
  MAX(CASE WHEN ca.month_number = 6  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month) AS m06_pct,
  MAX(CASE WHEN ca.month_number = 12 THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month) AS m12_pct

FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month ASC, ca.month_number ASC;
