-- ============================================================
-- Query 6: Geographic Performance by Country
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- Which countries generate the most revenue?
-- How concentrated is the business geographically?
-- Which markets are growing and which are declining year over year?
--
-- Source: bigquery-public-data.thelook_ecommerce. theLook is a global
-- marketplace, so geography is analysed at country level (customer country).

WITH country_yearly AS (
  SELECT
    u.country,
    EXTRACT(YEAR FROM oi.created_at)     AS order_year,
    COUNT(DISTINCT oi.order_id)          AS total_orders,
    COUNT(DISTINCT oi.user_id)           AS unique_customers,
    ROUND(SUM(oi.sale_price), 2)         AS total_revenue,
    ROUND(SUM(oi.sale_price - p.cost), 2) AS total_profit,
    ROUND(SUM(oi.sale_price) / COUNT(DISTINCT oi.order_id), 2) AS avg_order_value
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.users` u ON oi.user_id = u.id
  JOIN `bigquery-public-data.thelook_ecommerce.products` p ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY u.country, order_year
),

with_window_metrics AS (
  SELECT
    *,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank,
    ROUND(total_revenue / SUM(total_revenue) OVER (PARTITION BY order_year) * 100, 1) AS revenue_share_pct,
    ROUND(
      SUM(total_revenue) OVER (
        PARTITION BY order_year ORDER BY total_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) / SUM(total_revenue) OVER (PARTITION BY order_year) * 100, 1
    )                                                                 AS cumulative_revenue_share_pct,
    LAG(total_revenue) OVER (PARTITION BY country ORDER BY order_year) AS prev_year_revenue
  FROM country_yearly
)

SELECT
  country,
  order_year,
  total_orders,
  unique_customers,
  total_revenue,
  total_profit,
  avg_order_value,
  revenue_rank,
  revenue_share_pct,
  cumulative_revenue_share_pct,
  prev_year_revenue,
  ROUND((total_revenue - prev_year_revenue) / NULLIF(prev_year_revenue, 0) * 100, 1) AS yoy_growth_pct
FROM with_window_metrics
ORDER BY order_year ASC, revenue_rank ASC;
