-- ============================================================
-- Query 6: Geographic Performance by State
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- Which Brazilian states generate the most revenue?
-- How concentrated is the business geographically?
-- Which states are growing and which are declining year over year?

WITH state_yearly AS (
  SELECT
    cu.customer_state,
    EXTRACT(YEAR FROM DATE(o.order_purchase_timestamp))  AS order_year,
    COUNT(DISTINCT o.order_id)                           AS total_orders,
    COUNT(DISTINCT o.customer_id)                        AS unique_customers,
    ROUND(SUM(p.payment_value), 2)                       AS total_revenue,
    ROUND(AVG(p.payment_value), 2)                       AS avg_order_value
  FROM `analytics-portfolio-496419.olist.orders` o
  JOIN `analytics-portfolio-496419.olist.payments` p
    ON o.order_id = p.order_id
  JOIN `analytics-portfolio-496419.olist.customers` cu
    ON o.customer_id = cu.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY cu.customer_state, order_year
),

with_window_metrics AS (
  SELECT
    *,

    -- Revenue rank within each year (1 = top state that year)
    RANK() OVER (
      PARTITION BY order_year
      ORDER BY total_revenue DESC
    )                                                    AS revenue_rank,

    -- Each state's revenue share of the national total that year
    ROUND(
      total_revenue / SUM(total_revenue) OVER (PARTITION BY order_year) * 100,
      1
    )                                                    AS revenue_share_pct,

    -- Cumulative revenue share ordered by rank — enables Pareto analysis
    -- (e.g., "top 3 states account for X% of revenue")
    ROUND(
      SUM(total_revenue) OVER (
        PARTITION BY order_year
        ORDER BY total_revenue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) / SUM(total_revenue) OVER (PARTITION BY order_year) * 100,
      1
    )                                                    AS cumulative_revenue_share_pct,

    -- Prior year revenue for YoY growth calculation
    LAG(total_revenue) OVER (
      PARTITION BY customer_state
      ORDER BY order_year
    )                                                    AS prev_year_revenue,

  FROM state_yearly
)

SELECT
  customer_state,
  order_year,
  total_orders,
  unique_customers,
  total_revenue,
  avg_order_value,
  revenue_rank,
  revenue_share_pct,
  cumulative_revenue_share_pct,
  prev_year_revenue,
  -- YoY calculado apenas quando receita anterior >= 5000 (evita distorcao do ano parcial 2016)
  CASE
    WHEN prev_year_revenue IS NULL THEN NULL
    WHEN prev_year_revenue < 5000  THEN NULL
    ELSE ROUND((total_revenue - prev_year_revenue) / prev_year_revenue * 100, 1)
  END                                                    AS yoy_growth_pct

FROM with_window_metrics
ORDER BY order_year ASC, revenue_rank ASC;
