-- ============================================================
-- Query 4: Revenue Decomposition — New vs Returning Customers
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- How much of our monthly revenue comes from new customers vs returning ones?
-- Is our growth driven by acquisition or by retention?
-- What is the month-over-month growth rate, and is it accelerating?

WITH customer_first_order AS (
  -- Each customer's cohort month (first delivered purchase)
  SELECT
    customer_id,
    DATE_TRUNC(MIN(DATE(order_purchase_timestamp)), MONTH) AS first_order_month
  FROM `analytics-portfolio-496419.olist.orders`
  WHERE order_status = 'delivered'
  GROUP BY customer_id
),

monthly_segments AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp))   AS year_month,

    -- Customer counts split by new vs returning
    COUNTIF(
      DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) = cfo.first_order_month
    )                                                        AS new_customers,
    COUNTIF(
      DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) > cfo.first_order_month
    )                                                        AS returning_customers,

    -- Revenue split by new vs returning
    ROUND(SUM(CASE
      WHEN DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) = cfo.first_order_month
      THEN p.payment_value END), 2)                          AS new_customer_revenue,
    ROUND(SUM(CASE
      WHEN DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) > cfo.first_order_month
      THEN p.payment_value END), 2)                          AS returning_customer_revenue,
    ROUND(SUM(p.payment_value), 2)                           AS total_revenue

  FROM `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.payments` p
    ON o.order_id = p.order_id
  JOIN customer_first_order cfo
    ON o.customer_id = cfo.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY year_month
)

SELECT
  year_month,
  new_customers,
  returning_customers,
  new_customer_revenue,
  returning_customer_revenue,
  total_revenue,

  -- Revenue mix %
  ROUND(new_customer_revenue       / NULLIF(total_revenue, 0) * 100, 1) AS new_revenue_pct,
  ROUND(returning_customer_revenue / NULLIF(total_revenue, 0) * 100, 1) AS returning_revenue_pct,

  -- Month-over-month growth (LAG looks back 1 row in time order)
  LAG(total_revenue) OVER (ORDER BY year_month)                          AS prev_month_revenue,
  ROUND(
    (total_revenue - LAG(total_revenue) OVER (ORDER BY year_month))
    / NULLIF(LAG(total_revenue) OVER (ORDER BY year_month), 0) * 100,
    1
  )                                                                       AS mom_growth_pct,

  -- 3-month rolling average to smooth seasonal noise
  ROUND(
    AVG(total_revenue) OVER (
      ORDER BY year_month
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ),
    2
  )                                                                       AS rolling_3m_avg_revenue

FROM monthly_segments
ORDER BY year_month;
