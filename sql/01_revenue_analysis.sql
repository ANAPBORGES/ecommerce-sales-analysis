-- ============================================================
-- Query 1: Revenue Analysis — Monthly Trends + New vs Returning
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- How has revenue evolved month over month?
-- How much comes from new vs returning customers?
-- Is growth accelerating or decelerating?
--
-- Note: uses customer_unique_id (not customer_id) to correctly
-- identify returning customers across orders in the Olist dataset,
-- where customer_id is unique per order, not per person.

WITH customer_first_order AS (
  SELECT
    cu.customer_unique_id,
    DATE_TRUNC(MIN(DATE(o.order_purchase_timestamp)), MONTH) AS first_order_month
  FROM `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.customers` cu ON o.customer_id = cu.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY cu.customer_unique_id
),

monthly_base AS (
  SELECT
    FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp))    AS year_month,
    DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH)       AS period_date,
    COUNT(DISTINCT o.order_id)                                AS total_orders,
    COUNT(DISTINCT cu.customer_unique_id)                     AS unique_customers,
    ROUND(SUM(p.payment_value), 2)                            AS total_revenue,
    ROUND(AVG(p.payment_value), 2)                            AS avg_order_value,
    COUNTIF(DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) = cfo.first_order_month) AS new_customers,
    COUNTIF(DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) > cfo.first_order_month) AS returning_customers,
    ROUND(SUM(CASE
      WHEN DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) = cfo.first_order_month
      THEN p.payment_value END), 2)                           AS new_customer_revenue,
    ROUND(SUM(CASE
      WHEN DATE_TRUNC(DATE(o.order_purchase_timestamp), MONTH) > cfo.first_order_month
      THEN p.payment_value END), 2)                           AS returning_customer_revenue
  FROM `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.payments` p ON o.order_id = p.order_id
  JOIN `analytics-portfolio-496419.olist.customers` cu ON o.customer_id = cu.customer_id
  JOIN customer_first_order cfo ON cu.customer_unique_id = cfo.customer_unique_id
  WHERE o.order_status = 'delivered'
    AND DATE(o.order_purchase_timestamp) >= '2017-01-01'
  GROUP BY year_month, period_date
)

SELECT
  year_month,
  period_date,
  total_orders,
  unique_customers,
  total_revenue,
  avg_order_value,
  new_customers,
  returning_customers,
  new_customer_revenue,
  COALESCE(returning_customer_revenue, 0)                                               AS returning_customer_revenue,
  ROUND(new_customer_revenue / NULLIF(total_revenue, 0), 4)                            AS new_revenue_pct,
  ROUND(COALESCE(returning_customer_revenue, 0) / NULLIF(total_revenue, 0), 4)         AS returning_revenue_pct,
  LAG(total_revenue) OVER (ORDER BY year_month)                                         AS prev_month_revenue,
  ROUND(
    (total_revenue - LAG(total_revenue) OVER (ORDER BY year_month))
    / NULLIF(LAG(total_revenue) OVER (ORDER BY year_month), 0), 4
  )                                                                                      AS mom_growth_pct,
  ROUND(
    AVG(total_revenue) OVER (ORDER BY year_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
    2
  )                                                                                      AS rolling_3m_avg_revenue
FROM monthly_base
ORDER BY year_month;
