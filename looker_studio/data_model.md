# Data Model & Report Architecture

## Architecture

```
Kaggle — Olist Brazilian E-Commerce Dataset
        │
        ▼
BigQuery: analytics-portfolio-496419.olist.*   ← 5 raw tables (~96K orders)
        │
        ├── olist.orders       ─┐
        ├── olist.payments      ├── JOINed in SQL queries below
        ├── olist.customers     │
        ├── olist.order_items   │
        └── olist.products     ─┘
                │
                ├── vw_revenue_trends    ← monthly revenue, orders, customers, ticket
                ├── vw_cohort_retention  ← monthly cohort × month_number retention table
                └── vw_customer_ltv_rfm ← one row per customer with RFM scores and segment
                        │
                        ▼
                Looker Studio (3 pages, 1 date filter per page)
                        │
                        ├── Page 1: Sales Overview      ← revenue trends
                        ├── Page 2: Customer Analysis   ← RFM segmentation
                        └── Page 3: Cohort Retention    ← monthly cohort table
```

---

## BigQuery Raw Tables

| Table | Key fields | Role in analysis |
|---|---|---|
| `olist.orders` | `order_id`, `customer_id`, `order_purchase_timestamp`, `order_status` | Base join table; filtered to `status = 'delivered'` |
| `olist.payments` | `order_id`, `payment_value` | Revenue source; joined to orders on `order_id` |
| `olist.customers` | `customer_id` | Customer identity; used for DISTINCT counts |
| `olist.order_items` | `order_id`, `product_id` | Used for product-level analysis (available for extension) |
| `olist.products` | `product_id`, `product_category_name` | Category dimension (available for extension) |

---

## BigQuery Views

### vw_revenue_trends
Built from [`01_revenue_trends.sql`](../sql/01_revenue_trends.sql)

Joins `orders` and `payments`. Filtered to `order_status = 'delivered'`.

| Column | Type | Description |
|---|---|---|
| `year_month` | STRING | Month in `YYYY-MM` format (e.g., `"2017-11"`) |
| `total_orders` | INT | Distinct delivered orders per month |
| `unique_customers` | INT | Distinct customers who ordered that month |
| `total_revenue` | FLOAT | SUM of payment_value |
| `avg_order_value` | FLOAT | AVG payment_value per order |

---

### vw_cohort_retention
Built from [`02_cohort_retention.sql`](../sql/02_cohort_retention.sql)

Uses two CTEs:
- `first_purchase` — finds the first purchase month (cohort assignment) per customer
- `orders_with_cohort` — joins all subsequent orders back to the cohort, computing `month_number` (months since first purchase)
- `cohort_size` — counts customers at month 0 (acquisition) per cohort

| Column | Type | Description |
|---|---|---|
| `cohort_month` | DATE | First purchase month — defines the cohort |
| `cohort_customers` | INT | Customers acquired in this cohort (month 0 count) |
| `month_number` | INT | Months elapsed since first purchase (0 = acquisition month) |
| `retained_customers` | INT | Customers from this cohort who bought in this month_number |
| `retention_rate_pct` | FLOAT | retained_customers ÷ cohort_customers × 100 |

**Note on late cohorts:** Cohorts from 2018 show retention close to 100% because the dataset ends in August 2018 — recent buyers haven't had time to churn. This is a data boundary artifact, not a real improvement in retention.

---

### vw_customer_ltv_rfm
Built from [`03_customer_ltv_rfm.sql`](../sql/03_customer_ltv_rfm.sql)

Uses two CTEs:
- `customer_metrics` — aggregates frequency, monetary value, and last purchase date per customer, then computes `recency_days` from a fixed reference date (`2018-10-01`)
- `rfm_scores` — applies `NTILE(4)` to assign scores 1–4 for each RFM dimension independently

One row per customer.

| Column | Type | Description |
|---|---|---|
| `customer_id` | STRING | Customer identifier |
| `recency_days` | INT | Days since last purchase (lower = more recent) |
| `frequency` | INT | Number of distinct orders |
| `monetary` | FLOAT | Total spend |
| `r_score` | INT | Recency score 1–4 (4 = most recent) |
| `f_score` | INT | Frequency score 1–4 (4 = highest frequency) |
| `m_score` | INT | Monetary score 1–4 (4 = highest spend) |
| `rfm_total` | INT | r_score + f_score + m_score (range: 3–12) |
| `customer_segment` | STRING | Champions / Loyal Customers / Potential Loyalists / At Risk / Lost |

**Scoring thresholds:**

| Segment | rfm_total |
|---|---|
| Champions | ≥ 10 |
| Loyal Customers | ≥ 8 |
| Potential Loyalists | ≥ 6 |
| At Risk | ≥ 4 |
| Lost | < 4 |

**Why NTILE(4) instead of fixed thresholds for individual scores?**
NTILE distributes customers into equal-sized quartiles based on the actual data distribution. This avoids the problem of fixed thresholds (e.g., "frequency > 3 = score 4") that break when the dataset has a skewed distribution — which is common in e-commerce where most customers buy once. Each quartile always contains exactly 25% of the customer base regardless of the distribution shape.
