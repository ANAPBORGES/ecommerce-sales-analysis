-- ============================================================
-- Query 5: Customer Journey — Repeat Purchase Funnel
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- What percentage of customers come back for a second purchase?
-- How long does it take? Do they spend more on the second order?
-- How does the repeat rate vary by the time window (30 / 90 / 180 days)?
--
-- Source: bigquery-public-data.thelook_ecommerce. Identity: user_id.

WITH order_values AS (
  -- One row per order with its total value
  SELECT
    order_id,
    user_id,
    DATE(MIN(created_at))    AS order_date,
    SUM(sale_price)          AS order_value
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
  GROUP BY order_id, user_id
),

ranked_orders AS (
  SELECT
    user_id,
    order_id,
    order_date,
    order_value,
    ROW_NUMBER() OVER (
      PARTITION BY user_id
      ORDER BY order_date ASC, order_id ASC   -- deterministic tiebreaker
    ) AS purchase_rank
  FROM order_values
),

customer_journey AS (
  SELECT
    first.user_id,
    first.order_date                                     AS first_purchase_date,
    first.order_value                                    AS first_order_value,
    second.order_date                                    AS second_purchase_date,
    second.order_value                                   AS second_order_value,
    DATE_DIFF(second.order_date, first.order_date, DAY)  AS days_to_repeat
  FROM ranked_orders first
  LEFT JOIN ranked_orders second
    ON first.user_id = second.user_id
    AND second.purchase_rank = 2
  WHERE first.purchase_rank = 1
)

SELECT
  COUNT(*)                                                   AS total_customers,
  COUNTIF(second_purchase_date IS NOT NULL)                 AS repeat_customers,
  ROUND(COUNTIF(second_purchase_date IS NOT NULL) / COUNT(*) * 100, 1) AS repeat_rate_pct,

  ROUND(COUNTIF(days_to_repeat <= 30)  / NULLIF(COUNTIF(second_purchase_date IS NOT NULL), 0) * 100, 1) AS pct_repeat_within_30d,
  ROUND(COUNTIF(days_to_repeat <= 90)  / NULLIF(COUNTIF(second_purchase_date IS NOT NULL), 0) * 100, 1) AS pct_repeat_within_90d,
  ROUND(COUNTIF(days_to_repeat <= 180) / NULLIF(COUNTIF(second_purchase_date IS NOT NULL), 0) * 100, 1) AS pct_repeat_within_180d,

  ROUND(AVG(days_to_repeat), 0)                             AS avg_days_to_repeat,
  ROUND(AVG(first_order_value), 2)                          AS avg_first_order_value,
  ROUND(AVG(CASE WHEN second_purchase_date IS NOT NULL THEN second_order_value END), 2) AS avg_second_order_value,
  ROUND(AVG(CASE WHEN second_purchase_date IS NOT NULL THEN second_order_value - first_order_value END), 2) AS avg_order_value_uplift
FROM customer_journey;
