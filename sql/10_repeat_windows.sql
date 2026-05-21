-- ============================================================
-- Query 10: Repeat Purchase Windows
-- Project: E-commerce Sales Analysis (Olist)
-- Author: Ana Paula Borges | github.com/ANAPBORGES
-- ============================================================
-- Business question:
-- Of customers who returned, how quickly did they come back?
-- What % repeated within 30, 90 and 180 days?
-- Created to feed a bar chart in Looker Studio (requires rows, not columns).

SELECT '1 - Within 30 days'  AS repeat_window, pct_repeat_within_30d  AS repeat_pct
FROM `analytics-portfolio-496419.olist.vw_customer_journey`
UNION ALL
SELECT '2 - Within 90 days'  AS repeat_window, pct_repeat_within_90d  AS repeat_pct
FROM `analytics-portfolio-496419.olist.vw_customer_journey`
UNION ALL
SELECT '3 - Within 180 days' AS repeat_window, pct_repeat_within_180d AS repeat_pct
FROM `analytics-portfolio-496419.olist.vw_customer_journey`;
