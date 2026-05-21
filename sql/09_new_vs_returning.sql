-- ============================================================
-- Query 9: New vs Returning Revenue — Aggregated Split
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- What share of total revenue comes from new vs returning customers?
-- Created to feed a donut chart in Looker Studio (requires rows, not columns).

SELECT 'New Customers'      AS customer_type, SUM(new_customer_revenue)      AS revenue
FROM `analytics-portfolio-496419.olist.vw_revenue_analysis`
UNION ALL
SELECT 'Returning Customers' AS customer_type, SUM(returning_customer_revenue) AS revenue
FROM `analytics-portfolio-496419.olist.vw_revenue_analysis`;
