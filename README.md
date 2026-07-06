BrightCart Cloud — E-Commerce Retention Analysis
> **Data Analyst Intern Capstone Project**
---
 Business Question
> *"Why are repeat purchases declining among previously high-value customers,
> and which products, countries, and customer segments should the company
> prioritize to improve long-term revenue retention?"*
---
 Project Overview
This is a full end-to-end Data Analyst Intern Capstone Project for
BrightCart Cloud, a B2B e-commerce SaaS platform. The project analyses
13 months of transactional data to identify the root cause of declining
repeat purchases and delivers three actionable business recommendations
backed by data evidence.
Item	Detail
Dataset	UCI Online Retail — UK non-store online retailer
Period	01 December 2010 to 09 December 2011
Raw rows	541,909 transactions
Clean rows	397,884 transactions (after cleaning)
Unique customers	4,338
Unique countries	37
Unique products	3,665
Total revenue	£8,911,408 GBP
---
 Key Findings
Finding	Value
M1 Retention — Dec 2010 cohort (best)	36.6%
M1 Retention — Nov 2011 cohort (worst)	11.2%
M1 Retention drop across 12 months	25.4 percentage points
Average M1 retention across all cohorts	20.6%
Champions segment revenue	£4,417,016 (49.6% of total)
High-value at-risk customers	564 customers
Revenue at risk	£1,187,012
UK revenue concentration	82% of total revenue
---
 Three Strategic Recommendations
#	Recommendation	Owner	Timeline	Target KPI
1	Fix onboarding drop — automated email and in-app sequence before Month-1 churn	Product + Marketing	4 weeks	M1 retention rises from 11.2% to 25%+
2	Shift budget to high-retention countries — pause weak campaigns	Marketing + Finance	6 weeks	Non-UK revenue grows from 18% to 25%+
3	Win-back at-risk customers + Champions loyalty programme	CRM + Marketing	2 weeks	20% reactivation rate within 60 days
---
 Tools Used
Tool	Purpose
MySQL (XAMPP)	Data import, cleaning, and analysis tables
Python 3 (Jupyter Notebook)	Cohort analysis, RFM segmentation, visualisations
Power BI Desktop	3-page interactive dashboard
Microsoft Word	Strategy recommendation report
Python Libraries
```
pandas                 — data manipulation and analysis
numpy                  — numerical calculations
matplotlib             — chart generation
seaborn                — heatmap and statistical charts
mysql-connector-python — MySQL database connection
```
---
 Repository Structure
```
brightcart-retention-analysis/
│
├── README.md                        ← This file
├── requirements.txt                 ← Python library list
│
├── sql/
│   ├── 01_create_database.sql       ← Create brightcart_db + orders_raw table
│   ├── 02_data_cleaning.sql         ← Apply 4 cleaning rules → orders_clean
│   ├── 03_analysis_tables.sql       ← customer_first_purchase, monthly_customer_revenue
│   ├── 04_cohort_retention.sql      ← cohort_size, cohort_retention, cohort_heatmap
│   ├── 05_rfm_segments.sql          ← rfm_scores, customer_segments
│   └── 06_export_queries.sql        ← Export 6 CSVs for Power BI
│
├── python/
│   └── brightcart_analysis.ipynb   ← Full analysis notebook (21 cells)
│
├── dashboard/
│   ├── page1_overview.png           ← Revenue & Retention Overview
│   ├── page2_cohort_retention.png   ← Cohort Retention Analysis
│   └── page3_segments_risk.png      ← Customer Segments & Revenue Risk
│
└── report/
    └── BrightCart_Cloud_Strategy_Report.pdf  ← Full strategy report
```
---
 How to Run — Step by Step
Step 1 — Clone the Repository
```bash
git clone https://github.com/pasinduheshan/brightcart-retention-analysis.git
cd brightcart-retention-analysis
```
> Replace `pasinduheshan` with your actual GitHub username.
---
Step 2 — Install Python Libraries
```bash
pip install -r requirements.txt
```
---
Step 3 — Download the Dataset
The raw CSV file is not included in this repository because it exceeds
GitHub's 25 MB file limit. Download it directly from the UCI repository:
UCI Machine Learning Repository:
https://archive.ics.uci.edu/ml/datasets/Online+Retail
After downloading, save the file to your local project folder and
update the `FILE_PATH` variable in Cell 01 of the notebook to match
your local path before running.
---
Step 4 — Run SQL Scripts in XAMPP MySQL
Open phpMyAdmin at `http://localhost/phpmyadmin` and run each script
in this exact order:
```
1. sql/01_create_database.sql    → Creates brightcart_db and orders_raw table
2. Import CSV via Python Cell 00 → Loads 541,909 rows into orders_raw
3. sql/02_data_cleaning.sql      → Creates orders_clean (397,884 rows)
4. sql/03_analysis_tables.sql    → Creates customer_first_purchase, monthly tables
5. sql/04_cohort_retention.sql   → Creates cohort_size, cohort_retention, cohort_heatmap
6. sql/05_rfm_segments.sql       → Creates rfm_scores, customer_segments
7. sql/06_export_queries.sql     → Export 6 CSV files for Power BI
```
Verify all tables were created:
```sql
USE brightcart_db;
SHOW TABLES;

-- Expected result — 11 tables:
-- cohort_heatmap
-- cohort_retention
-- cohort_size
-- country_summary
-- customer_first_purchase
-- customer_segments
-- monthly_customer_revenue
-- orders_clean
-- orders_raw
-- product_summary
-- rfm_scores
```
---
Step 5 — Run the Python Notebook
```bash
jupyter notebook python/brightcart_analysis.ipynb
```
Run all cells top to bottom using `Shift + Enter` or click
Kernel → Restart & Run All.
Cell	Section
00	Import libraries
01	Load raw CSV dataset
02	Dataset overview
03	Missing value analysis
04	Duplicate row check
05	Apply 4 data cleaning rules
06	Cleaning summary table and chart
07	Feature engineering (Revenue, CohortMonth, MonthsSinceFirst, CustomerType)
08	Cohort retention analysis
09	Cohort retention heatmap chart
10	Monthly revenue trend chart
11	New vs Repeat customer revenue chart
12	RFM scoring (Recency, Frequency, Monetary — quartile 1 to 4)
13	Customer segmentation (8 segments)
14	Segment charts
15	At-risk high-value customer identification
16	Product analysis
17	Country analysis
18	Save 5 CSV exports for Power BI
19	Key findings summary
Outputs:
9 charts saved to `charts/` folder
5 CSV files saved for Power BI import
---
Step 6 — View the Power BI Dashboard
Dashboard screenshots are available in the `dashboard/` folder:
File	Page
`page1_overview.png`	Revenue & Retention Overview
`page2_cohort_retention.png`	Cohort Retention Analysis
`page3_segments_risk.png`	Customer Segments & Revenue Risk
> The `.pbix` file is not included due to GitHub file size limits.
> Screenshots show all three dashboard pages with full visual detail.
---
 Data Cleaning Summary
All cleaning was applied as a combined WHERE clause in SQL so that
overlapping records (e.g. a cancelled invoice that also has a missing
CustomerID) are only counted once in the final removed total.
Cleaning Step	Rows Removed	Reason
Raw data (baseline)	—	541,909 rows
Remove missing CustomerID	135,080	Cannot track retention without customer identity
Remove cancelled invoices (C%)	9,288	Not real purchases — returns or voids
Remove negative or zero quantity	~1,800	Refund entries and test records
Remove zero or negative price	~52	Internal system adjustments
Overlapping rows (counted in multiple rules)	~2,195	Removed once only
Final clean dataset	144,025 removed total	397,884 rows used in all analysis
> Verification: 541,909 − 144,025 = **397,884** ✅
---
 Database Schema
```
brightcart_db
│
├── orders_raw                  ← Raw CSV import (541,909 rows)
├── orders_clean                ← After 4 cleaning rules (397,884 rows)
│
├── customer_first_purchase     ← First purchase month per customer (cohort base)
├── monthly_customer_revenue    ← Revenue per customer per month
│
├── cohort_size                 ← Customer count per cohort month
├── cohort_retention            ← Active customers per cohort per period
├── cohort_heatmap              ← Retention % matrix M0 to M12
│
├── rfm_scores                  ← R, F, M scores per customer (1 to 4)
├── customer_segments           ← 8 segment labels + recommended actions
│
├── product_summary             ← Revenue and repeat buyer rate per product
└── country_summary             ← Revenue and repeat rate per country
```
---
 Results Summary
Cohort Retention
M1 retention fell from 36.6% (Dec 2010) to 11.2% (Nov 2011)
Average M1 retention across all cohorts: 20.6%
Biggest drop occurs between M0 and M1 for every cohort
The first 30 days after purchase is the highest-risk churn window
Revenue Trend
Total revenue: £8,911,408 over 13 months
Repeat revenue share grew from 0% to 88.2% of monthly total
Business is over-reliant on a shrinking loyal base
November 2011 peak: £1,162,000 (pre-Christmas seasonal spike)
RFM Customer Segments
Champions (483 customers) generate £4,417,016 = 49.6% of all revenue
At-risk customers (564) hold £1,187,012 in lifetime revenue
Dormant or Lost (1,421 customers) = 32.8% of customer base
Country Analysis
UK generates 82% of total revenue — single market concentration risk
Australia (88.9% repeat rate), Germany (69.1%), France (64.4%)
are priority international expansion markets
Product Analysis
PAPER CRAFT, LITTLE BIRDIE — highest revenue product (~£163,000)
REGENCY CAKESTAND 3 TIER — £142,593, 881 unique buyers
WHITE HANGING HEART T-LIGHT HOLDER — £100,448, 856 unique buyers
PICNIC BASKET WICKER 60 PIECES — highest repeat buyer rate
---
 Dataset Citation
> Daqing Chen, Sai Liang Sain, and Kun Guo.
> *Data mining for the online retail industry: A case study of RFM
> model-based customer segmentation using data mining.*
> Journal of Database Marketing and Customer Strategy Management, 2012.
>
> UCI Machine Learning Repository — Online Retail Dataset.
> https://archive.ics.uci.edu/ml/datasets/Online+Retail
---
 Author
Field	Detail
Name	Pasindu Heshan
Role	Data Analyst Intern
Project	BrightCart Cloud Capstone — Data Analyst Intern Assessment
Tools	MySQL · Python · Power BI · GitHub
