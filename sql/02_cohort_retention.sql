-- ============================================
-- Query 2: Cohort Retention Analysis
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================
-- Business question:
-- Of customers who made their first purchase in a given month,
-- how many returned to buy again in subsequent months?
--
-- Source: bigquery-public-data.thelook_ecommerce.
-- Identity: user_id (one per person). Valid sales exclude Cancelled/Returned.

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

orders_with_cohort AS (
  SELECT
    op.user_id,
    fp.cohort_month,
    op.order_month,
    DATE_DIFF(op.order_month, fp.cohort_month, MONTH) AS month_number
  FROM orders_people op
  JOIN first_purchase fp ON op.user_id = fp.user_id
),

cohort_size AS (
  SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_customers
  FROM orders_with_cohort
  WHERE month_number = 0
  GROUP BY cohort_month
)

SELECT
  owc.cohort_month,
  cs.cohort_customers,
  owc.month_number,
  COUNT(DISTINCT owc.user_id)                                  AS retained_customers,
  ROUND(COUNT(DISTINCT owc.user_id) / cs.cohort_customers * 100, 1) AS retention_rate_pct
FROM orders_with_cohort owc
JOIN cohort_size cs ON owc.cohort_month = cs.cohort_month
GROUP BY owc.cohort_month, cs.cohort_customers, owc.month_number
ORDER BY owc.cohort_month ASC, owc.month_number ASC;
