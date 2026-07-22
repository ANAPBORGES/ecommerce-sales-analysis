-- ============================================================
-- Query 10: Repeat Purchase Windows
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- Of customers who returned, how quickly did they come back?
-- What % repeated within 30, 90 and 180 days?
-- Shaped as rows to feed a bar chart in Looker Studio. Self-contained.

WITH order_values AS (
  SELECT order_id, user_id, DATE(MIN(created_at)) AS order_date
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY order_id, user_id
),
ranked_orders AS (
  SELECT user_id, order_date,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date ASC, order_id ASC) AS purchase_rank
  FROM order_values
),
journey AS (
  SELECT
    DATE_DIFF(second.order_date, first.order_date, DAY) AS days_to_repeat,
    second.order_date IS NOT NULL                       AS repeated
  FROM ranked_orders first
  LEFT JOIN ranked_orders second
    ON first.user_id = second.user_id AND second.purchase_rank = 2
  WHERE first.purchase_rank = 1
),
agg AS (
  SELECT
    COUNTIF(repeated) AS repeat_customers,
    ROUND(COUNTIF(days_to_repeat <= 30)  / NULLIF(COUNTIF(repeated), 0) * 100, 1) AS w30,
    ROUND(COUNTIF(days_to_repeat <= 90)  / NULLIF(COUNTIF(repeated), 0) * 100, 1) AS w90,
    ROUND(COUNTIF(days_to_repeat <= 180) / NULLIF(COUNTIF(repeated), 0) * 100, 1) AS w180
  FROM journey
)

SELECT '1 - Within 30 days'  AS repeat_window, w30  AS repeat_pct FROM agg
UNION ALL
SELECT '2 - Within 90 days'  AS repeat_window, w90  AS repeat_pct FROM agg
UNION ALL
SELECT '3 - Within 180 days' AS repeat_window, w180 AS repeat_pct FROM agg;
