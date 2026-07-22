-- ============================================================
-- Query 7: Product Category Performance with Pareto + Margin
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- Which product categories drive the most revenue and profit?
-- Does the 80/20 rule (Pareto) apply?
-- Which categories are growing fastest, and how healthy are their margins?
--
-- Source: bigquery-public-data.thelook_ecommerce. Profit uses products.cost
-- (margin = (sale_price - cost) / sale_price), which theLook exposes directly.

WITH category_yearly AS (
  SELECT
    COALESCE(p.category, 'Uncategorized')             AS category,
    EXTRACT(YEAR FROM oi.created_at)                  AS order_year,
    COUNT(DISTINCT oi.order_id)                       AS total_orders,
    COUNT(DISTINCT oi.product_id)                     AS unique_products,
    ROUND(SUM(oi.sale_price), 2)                      AS total_revenue,
    ROUND(SUM(oi.sale_price - p.cost), 2)             AS total_profit,
    ROUND(SUM(oi.sale_price - p.cost) / NULLIF(SUM(oi.sale_price), 0) * 100, 1) AS margin_pct,
    ROUND(AVG(oi.sale_price), 2)                      AS avg_item_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items` oi
  JOIN `bigquery-public-data.thelook_ecommerce.products` p ON oi.product_id = p.id
  WHERE oi.status NOT IN ('Cancelled', 'Returned')
  GROUP BY category, order_year
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
    LAG(total_revenue) OVER (PARTITION BY category ORDER BY order_year) AS prev_year_revenue
  FROM category_yearly
)

SELECT
  category,
  order_year,
  total_orders,
  unique_products,
  total_revenue,
  total_profit,
  margin_pct,
  avg_item_price,
  revenue_rank,
  revenue_share_pct,
  cumulative_revenue_share_pct,
  CASE WHEN cumulative_revenue_share_pct <= 80 THEN 'Top 80%' ELSE 'Long tail' END AS pareto_group,
  prev_year_revenue,
  ROUND((total_revenue - prev_year_revenue) / NULLIF(prev_year_revenue, 0) * 100, 1) AS yoy_growth_pct
FROM with_window_metrics
ORDER BY order_year ASC, revenue_rank ASC;
