-- ============================================================
-- Query 3: Customer LTV & Segmentation (RFM)
-- Project: E-commerce Sales Analysis (theLook)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- What is the lifetime value of our customers?
-- Which customer segments drive the most revenue?
-- RFM = Recency, Frequency, Monetary
--
-- Source: bigquery-public-data.thelook_ecommerce.
-- Recency reference date is derived dynamically from the data
-- (the dataset is live), so the analysis stays valid over time.

WITH valid_items AS (
  SELECT order_id, user_id, DATE(created_at) AS order_date, sale_price
  FROM `bigquery-public-data.thelook_ecommerce.order_items`
  WHERE status NOT IN ('Cancelled', 'Returned')
),

customer_metrics AS (
  SELECT
    user_id,
    COUNT(DISTINCT order_id)                              AS frequency,
    ROUND(SUM(sale_price), 2)                             AS monetary,
    MAX(order_date)                                       AS last_purchase_date,
    DATE_DIFF(
      (SELECT MAX(order_date) FROM valid_items),          -- dynamic reference date
      MAX(order_date),
      DAY
    )                                                     AS recency_days
  FROM valid_items
  GROUP BY user_id
),

rfm_scores AS (
  SELECT
    user_id,
    frequency,
    monetary,
    last_purchase_date,
    recency_days,
    -- Scores 1 (worst) to 4 (best).
    -- R and M are continuous, so quartiles via NTILE(4) work well.
    NTILE(4) OVER (ORDER BY recency_days DESC)  AS r_score,  -- fewer days = better
    -- Frequency is discrete and ranges only 1–4 orders per customer in
    -- this dataset (most buy once). A raw NTILE would split the large
    -- "1 order" group arbitrarily across quartiles, so we map frequency
    -- directly to its score — meaningful and reproducible.
    LEAST(frequency, 4)                         AS f_score,
    NTILE(4) OVER (ORDER BY monetary ASC)       AS m_score
  FROM customer_metrics
)

SELECT
  user_id,
  recency_days,
  frequency,
  monetary,
  r_score,
  f_score,
  m_score,
  (r_score + f_score + m_score)  AS rfm_total,
  CASE
    WHEN (r_score + f_score + m_score) >= 10 THEN 'Champions'
    WHEN (r_score + f_score + m_score) >= 8  THEN 'Loyal Customers'
    WHEN (r_score + f_score + m_score) >= 6  THEN 'Potential Loyalists'
    WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk'
    ELSE                                          'Lost'
  END AS customer_segment
FROM rfm_scores
ORDER BY rfm_total DESC;
