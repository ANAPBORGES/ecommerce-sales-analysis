# E-commerce Sales Analysis 📊
> End-to-end analysis of a Brazilian e-commerce dataset, covering revenue trends, customer segmentation (RFM), and cohort retention.

[![SQL](https://img.shields.io/badge/SQL-BigQuery-4285F4?style=flat&logo=google-cloud)](https://cloud.google.com/bigquery)
[![Dashboard](https://img.shields.io/badge/Dashboard-Looker%20Studio-4285F4?style=flat&logo=google)](https://datastudio.google.com/s/un-nuhnGpV8)
[![Status](https://img.shields.io/badge/Status-Complete-success?style=flat)]()

---

## 📌 Business Context

**Industry:** E-commerce
**Stakeholders:** Marketing, Commercial, and Finance teams
**Business question:** *How has revenue evolved over time, and which customer segments drive the most value?*

This project analyzes 96,000+ real orders from Olist, Brazil's largest e-commerce marketplace, covering 2016–2018. The goal was to understand revenue growth patterns, identify high-value customer segments using RFM analysis, and measure customer retention through cohort analysis — delivering insights that support strategic decisions in acquisition, retention, and revenue planning.

---

## 🎯 Objectives

- [x] Analyze monthly revenue trends and identify growth patterns
- [x] Segment customers using RFM methodology (Recency, Frequency, Monetary)
- [x] Build a cohort retention analysis to measure customer loyalty
- [x] Deliver an executive dashboard with actionable KPIs

---

## 🗂 Dataset

| Field | Details |
|---|---|
| **Source** | [Kaggle — Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| **Size** | ~100K orders, 5 tables |
| **Period** | October 2016 – August 2018 |

**Tables used:**
- `orders` — order status and timestamps
- `order_items` — products and quantities per order
- `customers` — customer location and ID
- `payments` — payment method and value
- `products` — product category and attributes

---

## 🔧 Technical Approach

### Data Model

```
Kaggle Olist Dataset (5 CSVs)
        │
        ▼
BigQuery: analytics-portfolio-496419.olist.*   ← 5 raw tables (~96K orders)
        │
        ├── vw_revenue_trends    ← monthly revenue, orders, customers, avg ticket
        ├── vw_cohort_retention  ← monthly cohort × month_number retention table
        └── vw_customer_ltv_rfm ← one row per customer: RFM scores + segment
                │
                ▼
        Looker Studio (3 pages: Sales Overview · Customer Analysis · Cohort Retention)
```

### SQL Queries

| Query | Description |
|---|---|
| [`01_revenue_trends.sql`](./sql/01_revenue_trends.sql) | Monthly revenue, orders and avg ticket — feeds Sales Overview page |
| [`02_cohort_retention.sql`](./sql/02_cohort_retention.sql) | Cohort retention using a 3-CTE pipeline with self-join — feeds Cohort Retention page |
| [`03_customer_ltv_rfm.sql`](./sql/03_customer_ltv_rfm.sql) | RFM scoring with NTILE(4) quartiles and segment classification — feeds Customer Analysis page |

### Looker Studio Implementation

| Document | Description |
|---|---|
| [`looker_studio/calculated_fields.md`](./looker_studio/calculated_fields.md) | Calculated fields, aggregation rationale, and visual field mappings per page |
| [`looker_studio/data_model.md`](./looker_studio/data_model.md) | Raw table schemas, view columns, RFM scoring logic, and cohort boundary notes |

---

## 📈 Key Findings

1. **Strong revenue growth in 2017** — monthly revenue grew from R$46K (Oct 2016) to over R$1.2M (Nov 2017), a 26× increase in 13 months
2. **Champions drive disproportionate value** — the top customer segment (25% of customers) generates nearly 40% of total revenue
3. **Low repeat purchase rate** — cohort analysis reveals that most customers buy only once, which is consistent with marketplace behavior; this signals an opportunity for retention campaigns targeting the "Potential Loyalists" segment (25% of customers)
4. **Stable avg order value** — ticket size remained consistently between R$140–R$165 throughout the period, suggesting pricing stability

---

## 📊 Dashboard

**Tool:** Looker Studio
**Link:** [View live dashboard](https://datastudio.google.com/reporting/ccd24456-6f65-467c-a16c-c03b59bbb2c6)

The dashboard has 3 pages with a shared date filter:

| Page | Description |
|---|---|
| **Sales Overview** | Revenue, AVG Order Value, Orders KPIs · Monthly revenue bar chart · Donut by year |
| **Customer Analysis** | RFM segment distribution · Pivot table of f_score × segment · Donut and bar chart |
| **Cohort Retention** | Heat-map table of 23 monthly cohorts showing retained vs acquired customers |

**Previews:**

| Sales Overview | Customer Analysis |
|---|---|
| ![Sales Overview](./assets/Dashboard_Preview_p1_Looker_Studio.png) | ![Customer Analysis](./assets/Dashboard_Preview_p2_Looker_Studio.png) |

![Cohort Retention](./assets/Dashboard_Preview_p3_Looker_Studio.png)

---

## 📁 Repository Structure

```
ecommerce-sales-analysis/
│
├── sql/
│   ├── 01_revenue_trends.sql           ← Monthly revenue, orders, avg ticket
│   ├── 02_cohort_retention.sql         ← Cohort retention (3-CTE pipeline, self-join)
│   └── 03_customer_ltv_rfm.sql         ← RFM scoring with NTILE(4) + segment rules
│
├── looker_studio/
│   ├── calculated_fields.md            ← Calculated fields + visual field mappings per page
│   └── data_model.md                   ← Raw table schemas, view columns, RFM & cohort notes
│
├── assets/
│   ├── Dashboard_Preview_p1_Looker_Studio.png
│   ├── Dashboard_Preview_p2_Looker_Studio.png
│   └── Dashboard_Preview_p3_Looker_Studio.png
│
└── README.md
```

---

## 🚀 How to Reproduce

1. Download the dataset from [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Upload the 5 CSV files to BigQuery (dataset name: `olist`)
3. Run the SQL queries in order to create the views
4. Connect the views to Looker Studio and build the dashboard

---

## 👩‍💻 About

Built by **Ana Paula Borges** · [LinkedIn](https://linkedin.com/in/ana-paula-d-araújo-borges) · [GitHub](https://github.com/ANAPBORGES)

*Senior Data Analyst & Team Leader with 10+ years in BI, DataViz, and Marketing Analytics.*

