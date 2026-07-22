-- ============================================================
-- Query 1: Revenue Analysis — Monthly Trends + New vs Returning
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- How has revenue evolved month over month?
-- How much comes from new vs returning customers?
-- Is growth accelerating or decelerating?
--
-- Source: bigquery-public-data.thelook_ecommerce (Google public dataset).
-- Revenue recognition: an item counts as revenue only when its status is
-- not 'Cancelled' or 'Returned'. Customer identity uses user_id (one per
-- person), so new vs returning is measured cleanly at the person level.

WITH valid_items AS (
  SELECT
    order_id,
    user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
),

user_first AS (
  -- Each customer's acquisition month
  SELECT user_id, MIN(order_month) AS first_month
  FROM valid_items
  GROUP BY user_id
),

order_level AS (
  -- Collapse items to one row per order, flag whether it was placed in
  -- the customer's acquisition month (new) or later (returning)
  SELECT
    vi.order_id,
    vi.user_id,
    vi.order_month,
    SUM(vi.sale_price)              AS order_revenue,
    (vi.order_month = uf.first_month) AS is_new
  FROM valid_items vi
  JOIN user_first uf ON vi.user_id = uf.user_id
  GROUP BY vi.order_id, vi.user_id, vi.order_month, uf.first_month
),

monthly AS (
  SELECT
    order_month,
    FORMAT_DATE('%Y-%m', order_month)                          AS year_month,
    COUNT(DISTINCT order_id)                                   AS total_orders,
    COUNT(DISTINCT user_id)                                    AS unique_customers,
    ROUND(SUM(order_revenue), 2)                               AS total_revenue,
    ROUND(SUM(order_revenue) / COUNT(DISTINCT order_id), 2)    AS avg_order_value,
    COUNT(DISTINCT IF(is_new, user_id, NULL))                  AS new_customers,
    COUNT(DISTINCT IF(NOT is_new, user_id, NULL))              AS returning_customers,
    ROUND(SUM(IF(is_new, order_revenue, 0)), 2)               AS new_customer_revenue,
    ROUND(SUM(IF(NOT is_new, order_revenue, 0)), 2)           AS returning_customer_revenue
  FROM order_level
  GROUP BY order_month
)

SELECT
  year_month,
  order_month,
  total_orders,
  unique_customers,
  total_revenue,
  avg_order_value,
  new_customers,
  returning_customers,
  new_customer_revenue,
  returning_customer_revenue,
  ROUND(new_customer_revenue / NULLIF(total_revenue, 0), 4)       AS new_revenue_pct,
  ROUND(returning_customer_revenue / NULLIF(total_revenue, 0), 4) AS returning_revenue_pct,
  LAG(total_revenue) OVER (ORDER BY order_month)                  AS prev_month_revenue,
  ROUND(
    (total_revenue - LAG(total_revenue) OVER (ORDER BY order_month))
    / NULLIF(LAG(total_revenue) OVER (ORDER BY order_month), 0), 4
  )                                                               AS mom_growth_pct,
  ROUND(
    AVG(total_revenue) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
    2
  )                                                               AS rolling_3m_avg_revenue
FROM monthly
ORDER BY order_month;
