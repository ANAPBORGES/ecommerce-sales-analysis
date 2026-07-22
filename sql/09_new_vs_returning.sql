-- ============================================================
-- Query 9: New vs Returning Revenue — Aggregated Split
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- What share of total revenue comes from new vs returning customers?
-- Shaped as rows (not columns) to feed a donut chart in Looker Studio.
-- Self-contained (no dependency on a view that could expire in a sandbox).

WITH valid_items AS (
  SELECT order_id, user_id,
    DATE_TRUNC(DATE(created_at), MONTH) AS order_month,
    sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
),
user_first AS (
  SELECT user_id, MIN(order_month) AS first_month
  FROM valid_items GROUP BY user_id
),
order_level AS (
  SELECT
    vi.order_id,
    SUM(vi.sale_price)                AS order_revenue,
    (vi.order_month = uf.first_month) AS is_new
  FROM valid_items vi
  JOIN user_first uf ON vi.user_id = uf.user_id
  GROUP BY vi.order_id, vi.order_month, uf.first_month
)

SELECT 'New Customers'       AS customer_type, ROUND(SUM(IF(is_new, order_revenue, 0)), 2)     AS revenue FROM order_level
UNION ALL
SELECT 'Returning Customers' AS customer_type, ROUND(SUM(IF(NOT is_new, order_revenue, 0)), 2) AS revenue FROM order_level;
