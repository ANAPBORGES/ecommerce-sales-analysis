E-commerce Sales Analysis 📊
> End-to-end analysis of a Brazilian e-commerce dataset, covering revenue trends, customer segmentation (RFM), and cohort retention.
![SQL](https://img.shields.io/badge/SQL-BigQuery-4285F4?style=flat&logo=google-cloud)
![Dashboard](https://img.shields.io/badge/Dashboard-Looker%20Studio-4285F4?style=flat&logo=google)
[![Status](https://img.shields.io/badge/Status-Complete-success?style=flat)]()
---
📌 Business Context
Industry: E-commerce
Stakeholders: Marketing, Commercial, and Finance teams
Business question: How has revenue evolved over time, and which customer segments drive the most value?
This project analyzes 96,000+ real orders from Olist, Brazil's largest e-commerce marketplace, covering 2016–2018. The goal was to understand revenue growth patterns, identify high-value customer segments using RFM analysis, and measure customer retention through cohort analysis — delivering insights that support strategic decisions in acquisition, retention, and revenue planning.
---
🎯 Objectives
[x] Analyze monthly revenue trends and identify growth patterns
[x] Segment customers using RFM methodology (Recency, Frequency, Monetary)
[x] Build a cohort retention analysis to measure customer loyalty
[x] Deliver an executive dashboard with actionable KPIs
---
🗂 Dataset
Field	Details
Source	Kaggle — Brazilian E-Commerce Public Dataset by Olist
Size	~100K orders, 5 tables
Period	October 2016 – August 2018
Tables used:
`orders` — order status and timestamps
`order_items` — products and quantities per order
`customers` — customer location and ID
`payments` — payment method and value
`products` — product category and attributes
---
🔧 Technical Approach
Data Model
```
olist.orders
    └── olist.payments        -- payment value per order
    └── olist.order_items     -- items per order
    └── olist.customers       -- customer attributes
    └── olist.products        -- product details
```
Views created in BigQuery for dashboard consumption:
`vw_revenue_trends` — monthly revenue, orders, and avg order value
`vw_cohort_retention` — cohort-based retention rates
`vw_customer_ltv_rfm` — RFM scores and customer segments
SQL Queries
Query	Description
`01_revenue_trends.sql`	Monthly revenue, orders and avg ticket
`02_cohort_retention.sql`	Cohort retention by acquisition month
`03_customer_ltv_rfm.sql`	RFM scoring and customer segmentation
---
📈 Key Findings
Strong revenue growth in 2017 — monthly revenue grew from R$46K (Oct 2016) to over R$1.2M (Nov 2017), a 26× increase in 13 months
Champions drive disproportionate value — the top customer segment (25% of customers) generates nearly 40% of total revenue
Low repeat purchase rate — cohort analysis reveals that most customers buy only once, which is consistent with marketplace behavior; this signals an opportunity for retention campaigns targeting the "Potential Loyalists" segment (25% of customers)
Stable avg order value — ticket size remained consistently between R$140–R$165 throughout the period, suggesting pricing stability
---
📊 Dashboard
Tool: Looker Studio
Link: View live dashboard
Dashboard includes:
KPI scorecards: Total Revenue, Total Orders, Avg Order Value
Monthly revenue trend (line chart)
Customer segment distribution (donut chart)
Revenue by customer segment (bar chart)
Cohort retention table
---
📁 Repository Structure
```
ecommerce-sales-analysis/
│
├── sql/
│   ├── 01_revenue_trends.sql
│   ├── 02_cohort_retention.sql
│   └── 03_customer_ltv_rfm.sql
│
├── assets/
│   └── dashboard_preview.png
│
└── README.md
```
---
🚀 How to Reproduce
Download the dataset from Kaggle
Upload the 5 CSV files to BigQuery (dataset name: `olist`)
Run the SQL queries in order to create the views
Connect the views to Looker Studio and build the dashboard
---
👩‍💻 About
Built by Ana Paula Borges · LinkedIn · GitHub
Senior Data Analyst & Team Leader with 10+ years in BI, DataViz, and Marketing Analytics.
