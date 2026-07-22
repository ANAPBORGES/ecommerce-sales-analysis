# Looker Studio — Calculated Fields & Visual Mapping

This document describes the calculated fields and per-page visual mapping for the 5-page E-commerce Sales Analysis dashboard. Each page is backed by a BigQuery **custom query** (the corresponding file in [`/sql`](../sql)); most visuals use query columns directly, and the fields below are either computed in Looker Studio or clarify how a column is aggregated.

---

## Calculated Fields

### AVG Order Value (Sales Overview)
```
SUM(total_revenue) / SUM(total_orders)
```
**Why not use `avg_order_value` directly?** The query pre-computes AOV at the month grain. When several months are selected, averaging pre-computed averages gives an "average of averages" (wrong). Recomputing from `SUM(revenue) / SUM(orders)` always reflects the true average across the selected period.

### Returning revenue share (Sales Overview)
```
SUM(returning_customer_revenue) / SUM(total_revenue)
```
Share of revenue from customers buying beyond their acquisition month.

### Gross margin % (Category Performance)
```
SUM(total_profit) / SUM(total_revenue)
```
Recomputed at the selected grain rather than averaging the per-row `margin_pct`.

---

## Page 1 — Sales Overview  · source: `01_revenue_analysis`

| Visual | Type | Fields |
|---|---|---|
| Revenue | KPI | `SUM(total_revenue)` — US$8.1M total |
| AVG Order Value | KPI | `SUM(total_revenue)/SUM(total_orders)` — ≈ US$86 |
| Orders | KPI | `SUM(total_orders)` — 94K+ |
| Revenue over time | Bar | `SUM(total_revenue)` by `year_month` (+ `rolling_3m_avg_revenue` line) |
| New vs Returning | Donut | `09_new_vs_returning`: revenue by `customer_type` (≈ 71% / 29%) |
| AOV over time | Line | `SUM(total_revenue)/SUM(total_orders)` by `year_month` |
| Period filter | Date range | `order_month` |

## Page 2 — Customer Analysis  · source: `03_customer_ltv_rfm`

| Visual | Type | Fields |
|---|---|---|
| Customers | KPI | `COUNT(user_id)` — 66K |
| Revenue by segment | Bar | `SUM(monetary)` by `customer_segment` |
| Segment share | Donut | `COUNT(user_id)` by `customer_segment` |
| Repeat funnel | Bar | `10_repeat_windows`: `repeat_pct` by `repeat_window` (30/90/180d) |
| Period filter | Date range | `last_purchase_date` |

**Segments:** Champions (≥10) · Loyal Customers (≥8) · Potential Loyalists (≥6) · At Risk (≥4) · Lost (<4). Real revenue split: Loyal 33.8% · Potential 31.3% · Champions 21.3% · At Risk 12.2% · Lost 1.4%.

## Page 3 — Cohort Retention  · source: `08_cohort_matrix`

| Visual | Type | Fields |
|---|---|---|
| Retention matrix | Pivot / heatmap | Rows `cohort_month` · Cols `month_number` · Value `retention_rate_pct` (or the `m00_pct…m12_pct` columns) |
| Period filter | Date range | `cohort_month` |

Retention pattern: 100% (M0) → ~5% (M1) → stabilizes ~1.6–2% (M12). The newest cohorts are still maturing, so later cells are blank (not zero).

## Page 4 — Geographic Analysis  · source: `06_geographic_analysis`

| Visual | Type | Fields |
|---|---|---|
| World map | Geo map | `SUM(total_revenue)` by `country` |
| Top countries | Bar / table | `total_revenue`, `revenue_share_pct` by `country` |
| Concentration KPIs | KPI | `cumulative_revenue_share_pct` for top 3 (≈ 70%) |

Leaders: China ≈ 34% · United States ≈ 23% · Brazil ≈ 14%.

## Page 5 — Category Performance  · source: `07_category_performance`

| Visual | Type | Fields |
|---|---|---|
| Pareto chart | Combo | Bars `total_revenue` + line `cumulative_revenue_share_pct` by `category` |
| Category table | Table | `total_revenue`, `margin_pct`, `yoy_growth_pct`, `pareto_group` |
| Margin KPI | KPI | `SUM(total_profit)/SUM(total_revenue)` — ≈ 52% |

Top ~8 of 26 categories ≈ 60% of revenue; margins 46–60% (led by Outerwear & Coats, Jeans).
