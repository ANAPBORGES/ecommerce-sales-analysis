-- ============================================
-- Query 2: Cohort Retention Analysis
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================
-- Business question:
-- Of customers who made their first purchase in a given month,
-- how many returned to buy again in subsequent months?

WITH first_purchase AS (
  -- Get each customer's first purchase month (their cohort)
  SELECT
    customer_id,
    MIN(DATE_TRUNC(DATE(order_purchase_timestamp), MONTH)) AS cohort_month
  FROM
    `analytics-portfolio-496419.olist.orders`
  WHERE
    order_status = 'delivered'
  GROUP BY
    customer_id
),

orders_with_cohort AS (
  -- Join all orders with the customer's cohort month
  SELECT
    o.customer_id,
    fp.cohort_month,
    DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) AS order_month,
    DATE_DIFF(
      DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH),
      fp.cohort_month,
      MONTH
    ) AS month_number
  FROM
    `analytics-portfolio-496419.olist.orders` o
    JOIN first_purchase fp ON o.customer_id = fp.customer_id
  WHERE
    o.order_status = 'delivered'
),

cohort_size AS (
  -- Count customers per cohort (month 0 = acquisition)
  SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_customers
  FROM
    orders_with_cohort
  WHERE
    month_number = 0
  GROUP BY
    cohort_month
)

-- Final cohort retention table
SELECT
  owc.cohort_month,
  cs.cohort_customers,
  owc.month_number,
  COUNT(DISTINCT owc.customer_id)                              AS retained_customers,
  ROUND(
    COUNT(DISTINCT owc.customer_id) / cs.cohort_customers * 100,
    1
  )                                                            AS retention_rate_pct
FROM
  orders_with_cohort owc
  JOIN cohort_size cs ON owc.cohort_month = cs.cohort_month
GROUP BY
  owc.cohort_month,
  cs.cohort_customers,
  owc.month_number
ORDER BY
  owc.cohort_month ASC,
  owc.month_number ASC;
