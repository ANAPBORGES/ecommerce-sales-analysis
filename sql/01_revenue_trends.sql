-- ============================================
-- Query 1: Monthly Revenue Trends
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================
-- Business question:
-- How has revenue evolved month over month?
-- Which months had the highest order volume and ticket size?

SELECT
  FORMAT_DATE('%Y-%m', DATE(o.order_purchase_timestamp)) AS year_month,
  COUNT(DISTINCT o.order_id)                             AS total_orders,
  COUNT(DISTINCT o.customer_id)                          AS unique_customers,
  ROUND(SUM(p.payment_value), 2)                         AS total_revenue,
  ROUND(AVG(p.payment_value), 2)                         AS avg_order_value
FROM
  `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.payments` p
    ON o.order_id = p.order_id
WHERE
  o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
GROUP BY
  year_month
ORDER BY
  year_month ASC;
