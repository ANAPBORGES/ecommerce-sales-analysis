-- ============================================================
-- Query 5: Customer Journey — Repeat Purchase Funnel
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- What percentage of customers come back for a second purchase?
-- How long does it take? Do they spend more on the second order?
-- How does the repeat rate vary by the time window (30 / 90 / 180 days)?

WITH ranked_orders AS (
  -- Number each customer's purchases chronologically using ROW_NUMBER
  -- This identifies which order was the 1st, 2nd, 3rd, etc. per customer
  SELECT
    o.customer_id,
    o.order_id,
    DATE(o.order_purchase_timestamp)   AS order_date,
    ROUND(SUM(p.payment_value), 2)     AS order_value,
    ROW_NUMBER() OVER (
      PARTITION BY o.customer_id
      ORDER BY o.order_purchase_timestamp ASC
    )                                  AS purchase_rank
  FROM `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.payments` p
    ON o.order_id = p.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY
    o.customer_id,
    o.order_id,
    o.order_purchase_timestamp
),

customer_journey AS (
  -- Pair each customer's 1st and 2nd purchase into a single row
  -- LEFT JOIN preserves customers who never returned (second.* will be NULL)
  SELECT
    first.customer_id,
    first.order_date                                        AS first_purchase_date,
    first.order_value                                       AS first_order_value,
    second.order_date                                       AS second_purchase_date,
    second.order_value                                      AS second_order_value,
    DATE_DIFF(second.order_date, first.order_date, DAY)     AS days_to_repeat
  FROM ranked_orders first
  LEFT JOIN ranked_orders second
    ON  first.customer_id   = second.customer_id
    AND second.purchase_rank = 2
  WHERE first.purchase_rank = 1
)

SELECT
  -- Funnel totals
  COUNT(*)                                                   AS total_customers,
  COUNTIF(second_purchase_date IS NOT NULL)                  AS repeat_customers,
  ROUND(
    COUNTIF(second_purchase_date IS NOT NULL) / COUNT(*) * 100,
    1
  )                                                          AS repeat_rate_pct,

  -- Time-to-repeat breakdown: what share repeated within each window?
  -- These three metrics together reveal the urgency of the re-engagement opportunity
  ROUND(COUNTIF(days_to_repeat <= 30)  / NULLIF(COUNTIF(second_purchase_date IS NOT NULL), 0) * 100, 1) AS pct_repeat_within_30d,
  ROUND(COUNTIF(days_to_repeat <= 90)  / NULLIF(COUNTIF(second_purchase_date IS NOT NULL), 0) * 100, 1) AS pct_repeat_within_90d,
  ROUND(COUNTIF(days_to_repeat <= 180) / NULLIF(COUNTIF(second_purchase_date IS NOT NULL), 0) * 100, 1) AS pct_repeat_within_180d,

  -- Average time to come back (only for customers who did return)
  ROUND(AVG(days_to_repeat), 0)                              AS avg_days_to_repeat,

  -- Order value comparison: does repeat purchase spend more or less?
  ROUND(AVG(first_order_value), 2)                           AS avg_first_order_value,
  ROUND(AVG(CASE WHEN second_purchase_date IS NOT NULL THEN second_order_value END), 2) AS avg_second_order_value,
  ROUND(
    AVG(CASE WHEN second_purchase_date IS NOT NULL THEN second_order_value - first_order_value END),
    2
  )                                                          AS avg_order_value_uplift

FROM customer_journey;
