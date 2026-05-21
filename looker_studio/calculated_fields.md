# Looker Studio â€” Calculated Fields

This document describes the calculated fields created in Looker Studio for the E-commerce Sales Analysis dashboard, and the field mappings for each visual across the 3 report pages.

The dashboard connects to three BigQuery views: `vw_revenue_trends`, `vw_cohort_retention`, and `vw_customer_ltv_rfm`. Most visuals use view columns directly. The fields below are either calculated in Looker Studio or are clarifications of how view columns are aggregated per visual.

---

## Calculated Fields

### AVG Order Value (Sales Overview page)

```
SUM(total_revenue) / SUM(total_orders)
```

**Why not use `avg_order_value` directly?**
The view pre-computes `avg_order_value` at the month grain. When a date filter is applied and multiple months are selected, averaging the pre-computed averages would produce an incorrect result (average of averages). Recalculating from `SUM(revenue) / SUM(orders)` ensures the KPI card and trend chart always reflect the true average across the selected period.

---

### RFM Total (Customer Analysis page)

```
SUM(rfm_total)
```

Displays the sum of all individual RFM composite scores (r_score + f_score + m_score) across customers in view. Used in the "RFM" KPI card as a proxy for aggregate customer value weight across the base.

---

### AVG Score (Customer Analysis page)

```
SUM(monetary)
```

Displays total monetary value across the filtered customer base. Despite the "AVG Score" label in the dashboard, this reflects cumulative revenue contribution â€” the name refers to the monetary dimension of the RFM score, not a statistical average.

---

## Page 1 â€” Sales Overview

**Data source:** `vw_revenue_trends`

| Visual | Type | Fields | Notes |
|---|---|---|---|
| Revenue | KPI card | `SUM(total_revenue)` | R$ 15.422.461,77 total |
| AVG Order Value | KPI card | `SUM(total_revenue) / SUM(total_orders)` | Calculated field |
| Orders | KPI card | `SUM(total_orders)` | 96,477 total orders |
| Revenue over time | Bar chart | `SUM(total_revenue)` by `year_month` | Monthly granularity, Oct 2016â€“Aug 2018 |
| AVG Order Value over time | Line chart | `SUM(total_revenue) / SUM(total_orders)` by `year_month` | Upward trend showing stable ticket growth |
| Orders by year | Donut chart | `SUM(total_orders)` by year | 2016 â‰ˆ 1%, 2017 â‰ˆ 45%, 2018 â‰ˆ 54% |
| Period filter | Date range control | `order_purchase_date` | Applies to all visuals on this page |

---

## Page 2 â€” Customer Analysis

**Data source:** `vw_customer_ltv_rfm`

| Visual | Type | Fields | Notes |
|---|---|---|---|
| Frequency | KPI card | `COUNT(customer_id)` | 96,477 distinct customers |
| AVG Score | KPI card | `SUM(monetary)` | Total monetary value of customer base |
| RFM | KPI card | `SUM(rfm_total)` | Sum of all composite RFM scores |
| Customer Segment pivot | Pivot table | Rows: `customer_segment` Â· Cols: `f_score` Â· Values: `Record Count` | Shows distribution of frequency score within each segment |
| Customers by segment | Horizontal bar | `COUNT(customer_id)` by `customer_segment` | Champions and Potential Loyalists each â‰ˆ 25K customers |
| Segment share | Donut chart | `COUNT(customer_id)` by `customer_segment` | Champions 25.2% Â· Potential Loyalists 25% Â· Loyal Customers 24.8% Â· At Risk 18.5% Â· Lost 6.5% |
| Period filter | Date range control | `last_purchase_date` | Filters by customer recency window |

**RFM segmentation logic** (applied in SQL, surfaced in Looker Studio as `customer_segment`):

| Segment | RFM Total Score | Business meaning |
|---|---|---|
| Champions | â‰¥ 10 | Bought recently, buy often, spend the most |
| Loyal Customers | â‰¥ 8 | Regular buyers with high spend |
| Potential Loyalists | â‰¥ 6 | Recent buyers with moderate frequency |
| At Risk | â‰¥ 4 | Haven't bought recently but were valuable |
| Lost | < 4 | Low recency, frequency, and monetary |

---

## Page 3 â€” Cohort Retention

**Data source:** `vw_cohort_retention`

| Visual | Type | Fields | Notes |
|---|---|---|---|
| Retention by Cohort | Table with heatmap | `cohort_month` Â· `retained_customers` Â· `cohort_customers` | Heat map coloring: blue = retained volume, orange = cohort size. Shows 23 monthly cohorts from Sep 2016 to Jun 2018 |
| Period filter | Date range control | `cohort_month` | Narrows visible cohort window |

**Cohort logic** (from SQL): each row represents a cohort defined by the customer's first purchase month. `retained_customers` counts how many from that cohort placed at least one additional order. Because the Olist dataset ends in August 2018, later cohorts (2018) show retention close to 100% â€” they haven't had enough time to churn yet. This is the same boundary-effect observed in the churn analysis of the SaaS project.

