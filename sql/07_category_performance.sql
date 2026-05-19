-- ============================================================
-- Query 7: Product Category Performance with Pareto Analysis
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- Which product categories drive the most revenue?
-- Does the 80/20 rule (Pareto) apply — do 20% of categories generate 80% of revenue?
-- Which categories are growing fastest and which are in decline?

WITH category_yearly AS (
  SELECT
    COALESCE(pr.product_category_name, 'uncategorized')  AS category,
    EXTRACT(YEAR FROM DATE(o.order_purchase_timestamp))   AS order_year,
    COUNT(DISTINCT o.order_id)                            AS total_orders,
    COUNT(DISTINCT oi.product_id)                         AS unique_products,
    ROUND(SUM(oi.price), 2)                               AS product_revenue,
    ROUND(SUM(oi.freight_value), 2)                       AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2)            AS total_revenue,
    ROUND(AVG(oi.price), 2)                               AS avg_unit_price,
    ROUND(SUM(oi.freight_value) / NULLIF(SUM(oi.price + oi.freight_value), 0) * 100, 1) AS freight_pct
  FROM `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.order_items` oi
    ON o.order_id = oi.order_id
  JOIN `analytics-portfolio-496419.olist.products` pr
    ON oi.product_id = pr.product_id
  WHERE o.order_status = 'delivered'
  GROUP BY category, order_year
),

with_window_metrics AS (
  SELECT
    *,

    -- Revenue rank within year (1 = top category)
    RANK() OVER (
      PARTITION BY order_year
      ORDER BY total_revenue DESC
    )                                                     AS revenue_rank,

    -- Each category's share of total revenue that year
    ROUND(
      total_revenue / SUM(total_revenue) OVER (PARTITION BY order_year) * 100,
      1
    )                                                     AS revenue_share_pct,

    -- Cumulative revenue share sorted by rank — reveals the Pareto point
    -- At what category rank does cumulative share cross 80%?
    ROUND(
      SUM(total_revenue) OVER (
        PARTITION BY order_year
        ORDER BY total_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) / SUM(total_revenue) OVER (PARTITION BY order_year) * 100,
      1
    )                                                     AS cumulative_revenue_share_pct,

    -- Prior year revenue for YoY growth
    LAG(total_revenue) OVER (
      PARTITION BY category
      ORDER BY order_year
    )                                                     AS prev_year_revenue

  FROM category_yearly
)

SELECT
  category,
  order_year,
  total_orders,
  unique_products,
  product_revenue,
  freight_revenue,
  total_revenue,
  avg_unit_price,
  freight_pct,
  revenue_rank,
  revenue_share_pct,
  cumulative_revenue_share_pct,

  -- Flag categories in the Pareto 80% group
  CASE
    WHEN cumulative_revenue_share_pct <= 80 THEN 'Top 80%'
    ELSE 'Long tail'
  END                                                     AS pareto_group,

  prev_year_revenue,
  ROUND(
    (total_revenue - prev_year_revenue) / NULLIF(prev_year_revenue, 0) * 100,
    1
  )                                                       AS yoy_growth_pct

FROM with_window_metrics
ORDER BY order_year ASC, revenue_rank ASC;
