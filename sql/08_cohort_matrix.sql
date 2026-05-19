-- ============================================================
-- Query 8: Full Cohort Retention Matrix
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- For customers acquired in each month, what % are still active at month 1, 2, 3...?
-- Which cohorts have the best long-term retention?
-- Is retention improving for newer cohorts?
--
-- Output format: one row per (cohort_month × month_number) pair,
-- plus pre-pivoted columns for months 0–12 for direct use in heatmap tools.

WITH first_purchase AS (
  -- Assign each customer to their acquisition cohort (first delivered order month)
  SELECT
    customer_id,
    DATE_TRUNC(MIN(DATE(order_purchase_timestamp)), MONTH) AS cohort_month
  FROM `analytics-portfolio-496419.olist.orders`
  WHERE order_status = 'delivered'
  GROUP BY customer_id
),

monthly_activity AS (
  -- All months in which each customer placed at least one delivered order
  SELECT DISTINCT
    o.customer_id,
    DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) AS activity_month
  FROM `analytics-portfolio-496419.olist.orders` o
  WHERE o.order_status = 'delivered'
),

cohort_activity AS (
  -- Join activity back to cohort to compute month_number
  -- month_number 0 = acquisition month, 1 = one month later, etc.
  SELECT
    fp.cohort_month,
    DATE_DIFF(ma.activity_month, fp.cohort_month, MONTH)  AS month_number,
    COUNT(DISTINCT ma.customer_id)                         AS active_customers
  FROM first_purchase fp
  JOIN monthly_activity ma ON fp.customer_id = ma.customer_id
  GROUP BY fp.cohort_month, month_number
),

cohort_sizes AS (
  -- Cohort size = active customers at month_number 0 (acquisition month)
  SELECT
    cohort_month,
    active_customers AS cohort_size
  FROM cohort_activity
  WHERE month_number = 0
)

SELECT
  FORMAT_DATE('%Y-%m', ca.cohort_month)                   AS cohort_month,
  cs.cohort_size,
  ca.month_number,
  ca.active_customers,
  ROUND(ca.active_customers / cs.cohort_size * 100, 1)    AS retention_rate_pct,

  -- Pre-pivoted retention rates for months 0–12
  -- Enables heatmap visualisation without additional transformation in the BI tool
  MAX(CASE WHEN ca.month_number = 0  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month)                    AS m00_pct,
  MAX(CASE WHEN ca.month_number = 1  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month)                    AS m01_pct,
  MAX(CASE WHEN ca.month_number = 2  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month)                    AS m02_pct,
  MAX(CASE WHEN ca.month_number = 3  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month)                    AS m03_pct,
  MAX(CASE WHEN ca.month_number = 6  THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month)                    AS m06_pct,
  MAX(CASE WHEN ca.month_number = 12 THEN ROUND(ca.active_customers / cs.cohort_size * 100, 1) END)
    OVER (PARTITION BY ca.cohort_month)                    AS m12_pct

FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month ASC, ca.month_number ASC;
