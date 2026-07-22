# E-commerce Sales Analysis
> End-to-end analysis of a global e-commerce dataset covering revenue trends, customer segmentation (RFM), cohort retention, geographic performance, and category & margin analysis — built entirely on a **live, public BigQuery dataset** so every query is reproducible with zero setup.

[![SQL](https://img.shields.io/badge/SQL-BigQuery-4285F4?style=flat&logo=google-cloud)](https://cloud.google.com/bigquery)
[![Dataset](https://img.shields.io/badge/Dataset-thelook__ecommerce%20(public)-34A853?style=flat&logo=google-cloud)](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce)
[![Dashboard](https://img.shields.io/badge/Dashboard-Looker%20Studio-4285F4?style=flat&logo=google)](#dashboard)
[![Status](https://img.shields.io/badge/Status-SQL%20complete%20·%20dashboard%20in%20rebuild-yellow?style=flat)]()

---

## Business Context

**Industry:** E-commerce (global apparel marketplace)
**Stakeholders:** Marketing, Commercial, and Finance teams
**Business question:** *How has revenue evolved over time, which customer segments and markets drive the most value, and where are the opportunities for growth and margin?*

This project analyzes **94K+ orders** from `theLook`, a fictitious global fashion retailer whose data Google publishes and keeps live in BigQuery. The goal was to understand revenue growth, decompose it into new vs returning customers, identify high-value segments with RFM, measure cohort retention, and deliver geographic and category-level insights — including **profit margin**, which the dataset supports through product cost.

> **Why a public dataset?** Everything here runs against `bigquery-public-data.thelook_ecommerce`, hosted by Google and always available. No data upload, no credentials, no expiry — anyone can copy a query and run it. That makes the analysis fully **reproducible**.

---

## Dataset

| Field | Details |
|---|---|
| **Source** | [`bigquery-public-data.thelook_ecommerce`](https://console.cloud.google.com/marketplace/product/bigquery-public-data/thelook-ecommerce) |
| **Grain** | Order line item (`order_items`), one row per product per order |
| **Volume** | ~94K valid orders · 66K customers · US$8.1M revenue |
| **Period** | January 2019 – present (dataset is continuously updated) |

**Tables used:** `order_items` (sales, status, timestamps), `orders`, `users` (demographics, country), `products` (category, cost, retail price).

**Revenue recognition:** an item is counted as revenue only when its `status` is **not** `Cancelled` or `Returned`. Customer identity uses `user_id` (one per person), so new-vs-returning and cohort logic is measured cleanly at the person level.

---

## Technical Approach

### Data Model

```
bigquery-public-data.thelook_ecommerce   (live Google public dataset)
   order_items ── products (cost → margin)
        │            users (country, demographics)
        ▼
   9 analytical queries (BigQuery Standard SQL, window functions)
        │
        ├── 01 revenue_analysis      → monthly revenue, new/returning split, MoM, 3M rolling avg
        ├── 02 cohort_retention      → long-format cohort retention
        ├── 03 customer_ltv_rfm      → RFM scoring + segments (per user_id)
        ├── 05 customer_journey      → repeat-purchase funnel, time-to-repeat, uplift
        ├── 06 geographic_analysis   → revenue/profit by country, RANK, Pareto, YoY
        ├── 07 category_performance  → category Pareto + margin + YoY
        ├── 08 cohort_matrix         → pre-pivoted cohort matrix (months 0–12)
        ├── 09 new_vs_returning      → 2-row split for a donut chart
        └── 10 repeat_windows        → 3-row repeat rate by 30/90/180 days
        ▼
   Looker Studio (5 pages) — connected via BigQuery custom queries
```

### SQL Queries

| Query | Description |
|---|---|
| [`01_revenue_analysis.sql`](./sql/01_revenue_analysis.sql) | Monthly revenue + new vs returning split + MoM growth (LAG) + 3M rolling average |
| [`02_cohort_retention.sql`](./sql/02_cohort_retention.sql) | Cohort retention (long format) — CTE pipeline keyed on `user_id` |
| [`03_customer_ltv_rfm.sql`](./sql/03_customer_ltv_rfm.sql) | RFM scoring — NTILE(4) for R/M, direct mapping for the discrete Frequency |
| [`05_customer_journey.sql`](./sql/05_customer_journey.sql) | Repeat-purchase funnel — ROW_NUMBER to pair 1st/2nd order, time-to-repeat, uplift |
| [`06_geographic_analysis.sql`](./sql/06_geographic_analysis.sql) | Revenue & profit by country with RANK, cumulative share (Pareto), YoY (LAG) |
| [`07_category_performance.sql`](./sql/07_category_performance.sql) | Category Pareto + profit margin (uses product cost) + YoY growth |
| [`08_cohort_matrix.sql`](./sql/08_cohort_matrix.sql) | Full cohort matrix — pre-pivoted columns for months 0–12 (heatmap-ready) |
| [`09_new_vs_returning.sql`](./sql/09_new_vs_returning.sql) | Aggregated new vs returning revenue (2 rows, self-contained) |
| [`10_repeat_windows.sql`](./sql/10_repeat_windows.sql) | Repeat rate by 30 / 90 / 180-day window (3 rows, self-contained) |

### Looker Studio Implementation

| Document | Description |
|---|---|
| [`looker_studio/data_model.md`](./looker_studio/data_model.md) | Source schema, query outputs, RFM scoring logic, and cohort notes |
| [`looker_studio/calculated_fields.md`](./looker_studio/calculated_fields.md) | Calculated fields and per-page visual field mappings |

---

## Key Findings

1. **Strong, accelerating growth** — recognized revenue grew from **US$73K (2019) to US$2.1M (2025)**, a ~29× increase, with **+54% YoY in 2025**; the 3-month rolling average confirms sustained upward momentum.
2. **Healthy repeat business** — **30.8% of customers place a second order** (20,445 of 66,397), and returning customers already account for **28.5% of total revenue** — a real retention engine, not a pure-acquisition marketplace.
3. **Value concentrated in the top segments** — *Champions* (8.6% of customers) drive **21.3% of revenue**; together *Champions + Loyal Customers* (~30% of customers) generate **55% of revenue**.
4. **Retention has a long tail** — cohort retention drops from 100% (month 0) to ~5% (month 1), then stabilizes around **1.6–2%** through month 12, meaning a small but durable base keeps returning across the year.
5. **Geographically concentrated** — **China (~34%)**, the United States (~23%), and **Brazil (~14%)** lead; the top 3 markets account for roughly **70%** of revenue.
6. **Classic category Pareto with strong margins** — the top ~8 of 26 categories (led by *Outerwear & Coats* and *Jeans*) generate **~60% of revenue**, at healthy **46–60% gross margins**; overall blended margin is **51.9%**.

*All figures produced by the queries in [`/sql`](./sql), run live against the public dataset.*

---

## Dashboard

**Tool:** Looker Studio · connected to BigQuery via **custom queries** (no persisted tables, so nothing expires).

> **Status: in rebuild.** The analysis was re-based onto the live `thelook_ecommerce` public dataset, and the 5-page Looker Studio dashboard is being rebuilt on top of it. The planned pages:

| Page | Content |
|---|---|
| **Sales Overview** | Revenue KPIs · monthly revenue + 3M rolling avg · new vs returning donut · AOV trend |
| **Customer Analysis** | RFM segment revenue · segment distribution · repeat-purchase funnel by window |
| **Cohort Retention** | Cohort retention matrix (heatmap), months 0–12 |
| **Geographic Analysis** | World map · top countries ranking · revenue concentration KPIs |
| **Category Performance** | Pareto chart (bar + cumulative line) · category table with margin % |

---

## How to Reproduce

No setup, no data upload — the dataset is public and live:

1. Open the [BigQuery console](https://console.cloud.google.com/bigquery) (a free sandbox account is enough).
2. Copy any query from [`/sql`](./sql) and run it — it reads directly from `bigquery-public-data.thelook_ecommerce`.
3. To build the dashboard, add a BigQuery data source in Looker Studio using the query as a **custom query**.

---

## Repository Structure

```
ecommerce-sales-analysis/
├── sql/                          ← 9 BigQuery analytical queries (window functions, CTEs)
├── looker_studio/
│   ├── data_model.md             ← source schema, query outputs, RFM & cohort notes
│   └── calculated_fields.md      ← calculated fields + per-page field mappings
├── assets/                       ← dashboard previews (being regenerated for theLook)
└── README.md
```

---

## About

Built by **Ana Paula Borges** · [LinkedIn](https://linkedin.com/in/ana-paula-d-araújo-borges) · [GitHub](https://github.com/ANAPBORGES)

*Senior Data Analyst & Team Leader with 10+ years in BI, DataViz, and Marketing Analytics.*
