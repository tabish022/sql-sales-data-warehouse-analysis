# 🚲 SQL Data Warehouse & Sales Analytics Project
A beginner-to-advanced SQL project that takes raw sales data, checks it for quality issues, explores it, and answers real business questions using window functions, CTEs, and segmentation logic.

![Status](https://img.shields.io/badge/status-complete-brightgreen) ![Tool](https://img.shields.io/badge/tool-SQL%20Server-blue) ![Data](https://img.shields.io/badge/data-CSV%20%2F%20Star%20Schema-orange)

---

## 📌 What is this project?

You're handed raw sales data and asked *"tell us what's going on with our customers, products, and revenue."*

I worked with three tables — customers, products, and sales transactions — and used pure SQL to:
1. **Build the database** (create the schema and load raw data)
2. **Check the data can be trusted** (data quality checks)
3. **Explore what's in it** (exploratory data analysis / EDA)
4. **Answer real business questions** (advanced analytics: trends, segmentation, rankings)

No dashboards, no external tools — every insight below came from a `SELECT` statement.

---

## 🗂️ Dataset

A sales dataset for a bike company, structured as three tables:

| Table | What it holds |
|---|---|
| `dim_customers` | 18,484 customers — name, country, gender, marital status, birthdate |
| `dim_products` | 295 products — name, category, subcategory, cost |
| `fact_sales` | 60,398 sales line items — order number, product, customer, dates, revenue |

This is a **star schema**: `fact_sales` sits in the middle and connects out to the two "dimension" tables (see star schema diagram).

---

## 🛠️ Skills & SQL Concepts Used

- Database & table design (DDL)
- Data quality auditing (nulls, duplicates, invalid values, outlier detection)
- Joins across fact and dimension tables
- Aggregate functions (`SUM`, `AVG`, `COUNT DISTINCT`)
- Window functions (`RANK()`, `ROW_NUMBER()`, running totals, moving averages)
- CTEs (`WITH` clauses) for multi-step logic
- `CASE WHEN` for customer/product segmentation
- `ROLLUP` for subtotal + grand total reporting
- `UNION ALL` for building a single consolidated metrics report

---

## 📁 Project Structure

```
├── raw_data/
│   ├── dim_customers.csv
│   ├── dim_products.csv
│   └── fact_sales.csv
├── scripts/
│   ├── 00_create_database.sql     → creates the database, tables, and schema
│   ├── 01_checking_data.sql       → data quality checks
│   ├── 02_EDA_report.sql          → exploratory data analysis
│   └── 03_Advance_analysis.sql    → trends, segmentation, rankings
├── star_schema_diagram.drawio     → editable schema diagram (open in draw.io)
└── README.md
```

---

## 🏗️ Step 1: Create the Database (`00_create_database.sql`)

Sets up the `DataWarehouseAnalytics` database and creates the three tables (`dim_customers`, `dim_products`, `fact_sales`) that the raw CSVs get loaded into — this is the foundation everything else runs on.

---

## 🔍 Step 2: Data Quality Checks (`checking_data.sql`)

Before trusting any analysis, I checked whether the data was clean:

- ✅ No blank order dates or birthdates
- ✅ No negative or zero prices/quantities
- ✅ `sales_amount` always matches `quantity × price` — no calculation errors
- ✅ No duplicate customer or product records
- ⚠️ 14 customers have `gender = 'n/a'`
- ⚠️ 337 customers (~2%) have `country = 'n/a'`
- ⚠️ 7 products have a blank category
- ⚠️ Oldest customer's birthdate is 1916 (~110 years old) — flagged as worth double-checking with the source system
- ⚠️ Found duplicate combinations in `fact_sales` (same order + product + customer) — flagged for further investigation rather than assuming they're errors, since one order can legitimately have repeat line items

**Why this matters:** a real analyst never trusts data blindly — this step decides what needs cleaning before any conclusion is drawn.

---

## 🔎 Step 3: Exploratory Data Analysis (`EDA_report.sql`)

**The big numbers:**
| Metric | Value |
|---|---|
| Total Revenue | $29,356,250 |
| Total Units Sold | 60,423 |
| Average Price | ~$486 |
| Total Orders | 27,659 |
| Customers Who Purchased | 18,482 |
| Products That Sold | 130 out of 295 |

**Revenue by country:** US ($9.16M) and Australia ($9.06M) are almost tied for #1, together making up ~62% of all revenue. UK, Germany, and France each bring in $2.6M–$3.4M, and Canada is the smallest real market at ~$2.0M.

**Revenue by category:** Bikes generate $28.3M — about **96.5% of all revenue**. Accessories ($700K) and Clothing ($340K) are small by comparison.

**Gender split:** ~9.3K male, ~9.1K female, 14 unlabeled — a nearly even split between genders.

**Top products:** the 5 best-selling products are all Mountain-200 bike variants, each earning $1.29M–$1.37M.

**Least active customers:** the bottom 5 customers by order count have placed just 1 order each.

---

## 📊 Step 4: Advanced Analytics (`Advance_analysis.sql`)

**Trend over time:** 2010 and 2014 are partial years (barely any data), so the real story is 2011–2013. Within 2013, monthly revenue climbed from $858K in January to $1.87M in December — a genuine seasonal ramp-up toward the holidays, not random noise.

**Revenue share (part-to-whole):** confirms Bikes = 96.46%, Accessories = 2.39%, Clothing = 1.16% of total revenue.

**Customer segmentation** (based on how long they've been buying + how much they've spent):

| Segment | Customers | % |
|---|---|---|
| New | 14,629 | ~79% |
| Regular | 2,200 | ~12% |
| VIP | 1,653 | ~9% |

Most customers fall into the "New" bucket — short buying history, lower spend. This points to **retention** (getting existing customers to come back) as a bigger opportunity than **acquisition** (finding new customers).

---

## 💡 Key Takeaways (Business Summary)

1. **This is a bikes company first.** 96%+ of revenue comes from bikes — accessories and clothing are minor side lines.
2. **Two markets carry the business.** US and Australia together drive ~62% of revenue.
3. **Customer retention is the biggest opportunity.** ~79% of customers are still in the "New" segment — a small shift toward repeat purchases could meaningfully grow revenue without spending more on acquisition.
4. **One product line dominates sales.** All top 5 products are Mountain-200 variants — worth understanding why, and whether that success can be repeated elsewhere in the catalog.

---

## 🗺️ Star Schema Diagram

See `star_schema_diagram.drawio` — open it for free at [app.diagrams.net](https://app.diagrams.net) (draw.io). It shows how `fact_sales` connects to `dim_customers` and `dim_products` through their key columns.

---

## 🚀 How to Run This Project

1. Run `00_create_database.sql` to create the database and the three tables.
2. Load the CSVs from `raw_data/` into their matching tables.
3. Run the scripts in order: `01_checking_data.sql` → `02_EDA_report.sql` → `03_Advance_analysis.sql`.

---

## 🙋 About Me

Built by **Tabish Afzal** as a hands-on SQL project to practice the real workflow of a Data Analyst end to end: designing a star-schema database, auditing raw data for quality issues, exploring it, and writing advanced queries to turn 60K+ raw sales records into business insights.

· 🔗 [LinkedIn](https://www.linkedin.com/in/tabish-afzal/) · 💼 [Portfolio](https://github.com/tabish022)

---

⭐ If you found this useful, consider starring the repo!
