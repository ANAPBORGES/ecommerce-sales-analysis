-- ============================================
-- Query 3: Customer LTV & Segmentation (RFM)
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================
-- Business question:
-- What is the lifetime value of our customers?
-- Which customer segments drive the most revenue?
-- RFM = Recency, Frequency, Monetary

WITH customer_metrics AS (
  SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id)                                        AS frequency,
    ROUND(SUM(p.payment_value), 2)                                    AS monetary,
    MAX(DATE(o.order_purchase_timestamp))                             AS last_purchase_date,
    DATE_DIFF(
      DATE('2018-10-01'),  -- reference date (last month in dataset)
      MAX(DATE(o.order_purchase_timestamp)),
      DAY
    )                                                                 AS recency_days
  FROM
    `analytics-portfolio-496419.olist.orders` o
    JOIN `analytics-portfolio-496419.olist.payments` p
      ON o.order_id = p.order_id
  WHERE
    o.order_status = 'delivered'
  GROUP BY
    o.customer_id
),

rfm_scores AS (
  SELECT
    customer_id,
    frequency,
    monetary,
    last_purchase_date,
    recency_days,
    -- Score 1 (worst) to 4 (best)
    NTILE(4) OVER (ORDER BY recency_days DESC)  AS r_score,  -- lower recency = better
    NTILE(4) OVER (ORDER BY frequency ASC)      AS f_score,
    NTILE(4) OVER (ORDER BY monetary ASC)       AS m_score
  FROM
    customer_metrics
)

SELECT
  customer_id,
  recency_days,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score + f_score + m_score)  AS rfm_total,

  -- Segment customers based on RFM total score
  CASE
    WHEN (r_score + f_score + m_score) >= 10 THEN 'Champions'
    WHEN (r_score + f_score + m_score) >= 8  THEN 'Loyal Customers'
    WHEN (r_score + f_score + m_score) >= 6  THEN 'Potential Loyalists'
    WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk'
    ELSE                                          'Lost'
  END AS customer_segment

FROM
  rfm_scores
ORDER BY
  rfm_total DESC;
