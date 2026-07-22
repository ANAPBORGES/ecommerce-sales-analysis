# Data Model & Report Architecture

## Architecture

```
bigquery-public-data.thelook_ecommerce   (live Google public dataset — never expires)
        │
        ├── order_items   ← sales facts: sale_price, status, timestamps  (grain: product × order)
        ├── orders        ← order header
        ├── users         ← customer demographics + country
        └── products      ← category, brand, cost, retail_price
                │
                ▼   9 analytical queries (BigQuery Standard SQL)
        │
        ├── 01_revenue_analysis      → monthly revenue, new/returning, MoM, 3M rolling avg
        ├── 02_cohort_retention      → cohort × month_number retention (long format)
        ├── 03_customer_ltv_rfm      → one row per user with RFM scores + segment
        ├── 05_customer_journey      → repeat-purchase funnel (single summary row)
        ├── 06_geographic_analysis   → revenue/profit by country + Pareto + YoY
        ├── 07_category_performance  → category Pareto + margin + YoY
        ├── 08_cohort_matrix         → pre-pivoted cohort matrix (months 0–12)
        ├── 09_new_vs_returning      → 2-row revenue split (donut)
        └── 10_repeat_windows        → 3-row repeat rate by window (bar)
                │
                ▼
        Looker Studio (5 pages) — each chart backed by a BigQuery **custom query**
```

> **No persisted views.** In a BigQuery sandbox any table/view you create expires after 60 days. To keep the dashboard permanently reproducible, Looker Studio connects to each query as a **custom query** rather than to a stored `vw_*` view. The `.sql` files are the single source of truth.

---

## Source Tables

| Table | Key fields | Role in analysis |
|---|---|---|
| `order_items` | `order_id`, `user_id`, `product_id`, `status`, `created_at`, `sale_price` | Sales facts; filtered to `status NOT IN ('Cancelled','Returned')` |
| `orders` | `order_id`, `user_id`, `status` | Order header (available for extension) |
| `users` | `id`, `country`, `state`, `age`, `gender`, `traffic_source` | Customer identity & geography (`user_id = users.id`) |
| `products` | `id`, `category`, `cost`, `retail_price` | Category dimension **and cost** for margin analysis |

**Revenue recognition:** an item counts only when `status` is not `Cancelled`/`Returned`.
**Customer identity:** `user_id` — one per person (no per-order-id ambiguity).
**Profit / margin:** `sale_price − products.cost`.

---

## Query Outputs

### 01_revenue_analysis → Sales Overview
Monthly grain. Columns: `year_month`, `total_orders`, `unique_customers`, `total_revenue`, `avg_order_value`, `new_customers`, `returning_customers`, `new_customer_revenue`, `returning_customer_revenue`, `new_revenue_pct`, `returning_revenue_pct`, `prev_month_revenue`, `mom_growth_pct`, `rolling_3m_avg_revenue`.

### 03_customer_ltv_rfm → Customer Analysis
One row per `user_id`: `recency_days`, `frequency`, `monetary`, `r_score`, `f_score`, `m_score`, `rfm_total`, `customer_segment`.

**Scoring:**

| Dimension | Method |
|---|---|
| Recency (R) | `NTILE(4) OVER (ORDER BY recency_days DESC)` — continuous, quartiles work well |
| Frequency (F) | `LEAST(frequency, 4)` — **direct mapping**: frequency is discrete (1–4 orders/customer here), so NTILE would split the large "1 order" group arbitrarily. Direct mapping is meaningful and reproducible |
| Monetary (M) | `NTILE(4) OVER (ORDER BY monetary ASC)` — continuous, quartiles work well |

**Segment thresholds** (on `rfm_total` = R+F+M):

| Segment | rfm_total | Real distribution |
|---|---|---|
| Champions | ≥ 10 | 8.6% of customers · 21.3% of revenue |
| Loyal Customers | ≥ 8 | 21.0% · 33.8% |
| Potential Loyalists | ≥ 6 | 34.5% · 31.3% |
| At Risk | ≥ 4 | 28.6% · 12.2% |
| Lost | < 4 | 7.4% · 1.4% |

### 08_cohort_matrix → Cohort Retention
`cohort_month`, `cohort_size`, `month_number`, `active_customers`, `retention_rate_pct`, plus pre-pivoted `m00_pct`…`m12_pct` for a heatmap.

> **Boundary note:** the most recent cohorts have not had time to mature, so their later-month cells are empty (not zero). Read retention along cohorts that are at least *N* months old.

### 06_geographic_analysis / 07_category_performance
Country- and category-level yearly aggregates with `revenue_rank`, `revenue_share_pct`, `cumulative_revenue_share_pct` (Pareto), `yoy_growth_pct`, and — for categories — `margin_pct` from product cost.

---

## Reproducibility

Every query reads directly from `bigquery-public-data.thelook_ecommerce`, hosted by Google. No upload, no credentials, no expiry — copy a query from [`/sql`](../sql) into BigQuery and run.
