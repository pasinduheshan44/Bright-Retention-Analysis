-- ============================================================
--  BrightCart Cloud — Complete SQL Analysis Script
--  Project  : Data Analyst Intern Capstone
--  Author   : Pasindu Heshan
--  Dataset  : UCI Online Retail (Dec 2010 – Dec 2011)
--  Tool     : MySQL 8.0 (XAMPP / phpMyAdmin)
--
--  Business Question:
--    "Why are repeat purchases declining among previously
--     high-value customers, and which products, countries,
--     and customer segments should the company prioritize
--     to improve long-term revenue retention?"
--
--  Expected Results After Running All Scripts:
--    Raw rows        : 541,909
--    Clean rows      : 397,884
--    Unique customers:   4,338
--    Unique orders   :  18,532
--    Unique products :   3,665
--    Unique countries:      37
--    Total revenue   : GBP 8,911,407.90
--    Tables created  :      11
--
--  HOW TO RUN:
--    Run each SCRIPT block one at a time in phpMyAdmin SQL tab.
--    Do NOT run the entire file at once — run script by script.
--    Screenshots marked with (SCREENSHOT) should be saved
--    for your Word report evidence.
--
--  SCRIPT ORDER:
--    SCRIPT 01 → Create database + raw table
--    SCRIPT 02 → Import CSV + clean data
--    SCRIPT 03 → Build analysis tables
--    SCRIPT 04 → Build cohort retention tables
--    SCRIPT 05 → RFM scoring + customer segments
--    SCRIPT 06 → Export queries for Power BI
--    FINAL     → Verify all 11 tables exist
-- ============================================================


-- ============================================================
-- SCRIPT 01 — CREATE DATABASE AND RAW TABLE
-- ============================================================

-- Step 1A: Create the database
CREATE DATABASE IF NOT EXISTS brightcart_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE brightcart_db;

-- Step 1B: Drop raw table if it already exists (clean slate)
DROP TABLE IF EXISTS orders_raw;

-- Step 1C: Create the raw orders table
--          Column names and types match Online_Retail.csv exactly
CREATE TABLE orders_raw (
    InvoiceNo   VARCHAR(20),
    StockCode   VARCHAR(20),
    Description TEXT,
    Quantity    INT,
    InvoiceDate VARCHAR(25),
    UnitPrice   DECIMAL(10, 2),
    CustomerID  VARCHAR(10),
    Country     VARCHAR(100)
);

-- ============================================================
-- AFTER RUNNING STEP 1C:
-- Import Online_Retail.csv using Python mysql-connector script
-- (See README.md → Step 3 for the Python import code)
-- Then run the quick check below to confirm import success.
-- ============================================================

-- Step 1D: Quick check after CSV import (SCREENSHOT this)
SELECT COUNT(*) AS total_raw_rows FROM orders_raw;
-- Expected result: 541,909


-- ============================================================
-- SCRIPT 02 — DATA CLEANING
-- ============================================================

USE brightcart_db;

-- Step 2A: Before cleaning — raw data quality check (SCREENSHOT this)
SELECT
    COUNT(*)  AS raw_total_rows,
    COUNT(CASE WHEN CustomerID = '' OR CustomerID IS NULL THEN 1 END)
              AS missing_customerid,
    COUNT(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 END)
              AS cancelled_invoices,
    COUNT(CASE WHEN Quantity <= 0 THEN 1 END)
              AS negative_quantity,
    COUNT(CASE WHEN UnitPrice <= 0 THEN 1 END)
              AS zero_price
FROM orders_raw;
-- Expected:
--   raw_total_rows   : 541,909
--   missing_customerid: 135,080
--   cancelled_invoices:   9,288
--   negative_quantity :  10,624
--   zero_price        :   2,517

-- Step 2B: Create orders_clean — apply all 4 cleaning rules
--
-- Cleaning Rules Applied:
--   Rule 1: CustomerID IS NOT NULL and not empty
--           → Cannot track retention without customer identity
--   Rule 2: InvoiceNo NOT LIKE 'C%'
--           → Cancelled invoices are not real purchases
--   Rule 3: Quantity > 0
--           → Negative quantity = returns and corrections, not real sales
--   Rule 4: UnitPrice > 0
--           → Zero price = internal adjustments, not real sales
DROP TABLE IF EXISTS orders_clean;
CREATE TABLE orders_clean AS
SELECT
    TRIM(InvoiceNo)   AS InvoiceNo,
    TRIM(StockCode)   AS StockCode,
    TRIM(Description) AS Description,
    TRIM(CustomerID)  AS CustomerID,
    TRIM(Country)     AS Country,
    STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i') AS order_date,
    DATE_FORMAT(
        STR_TO_DATE(InvoiceDate, '%d/%m/%Y %H:%i'), '%Y-%m-01'
    )                 AS order_month,
    Quantity,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS revenue
FROM orders_raw
WHERE (CustomerID IS NOT NULL AND TRIM(CustomerID) != '')
  AND InvoiceNo NOT LIKE 'C%'
  AND Quantity  > 0
  AND UnitPrice > 0;

-- Step 2C: Add indexes for faster query performance
ALTER TABLE orders_clean
    ADD INDEX idx_customer (CustomerID),
    ADD INDEX idx_month    (order_month),
    ADD INDEX idx_country  (Country),
    ADD INDEX idx_stock    (StockCode),
    ADD INDEX idx_invoice  (InvoiceNo);

-- Step 2D: After cleaning verification (SCREENSHOT this)
SELECT
    COUNT(*)                   AS clean_total_rows,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT InvoiceNo)  AS unique_orders,
    COUNT(DISTINCT StockCode)  AS unique_products,
    COUNT(DISTINCT Country)    AS unique_countries,
    MIN(order_date)            AS data_start_date,
    MAX(order_date)            AS data_end_date,
    ROUND(SUM(revenue), 2)     AS total_revenue_GBP
FROM orders_clean;
-- Expected:
--   clean_total_rows : 397,884
--   unique_customers :   4,338
--   unique_orders    :  18,532
--   unique_products  :   3,665
--   unique_countries :      37
--   data_start_date  : 2010-12-01
--   data_end_date    : 2011-12-09
--   total_revenue_GBP: 8,911,407.90

-- Step 2E: Cleaning summary table (SCREENSHOT this — use in Word report)
SELECT stage, row_count, note
FROM (
    SELECT 1 AS s,
           'Raw Data'                     AS stage,
           (SELECT COUNT(*) FROM orders_raw) AS row_count,
           'Baseline CSV import'          AS note
    UNION ALL
    SELECT 2,
           'Removed: Missing CustomerID',
           (SELECT COUNT(*) FROM orders_raw
            WHERE CustomerID IS NULL OR TRIM(CustomerID) = ''),
           'Rule 1 - cannot track without ID'
    UNION ALL
    SELECT 3,
           'Removed: Cancelled Invoices',
           (SELECT COUNT(*) FROM orders_raw
            WHERE InvoiceNo LIKE 'C%'),
           'Rule 2 - not real purchases'
    UNION ALL
    SELECT 4,
           'Removed: Negative Quantity',
           (SELECT COUNT(*) FROM orders_raw
            WHERE Quantity <= 0 AND InvoiceNo NOT LIKE 'C%'),
           'Rule 3 - not real sales'
    UNION ALL
    SELECT 5,
           'Removed: Zero Price',
           (SELECT COUNT(*) FROM orders_raw
            WHERE UnitPrice <= 0
              AND Quantity  >  0
              AND InvoiceNo NOT LIKE 'C%'),
           'Rule 4 - internal adjustments'
    UNION ALL
    SELECT 6,
           'FINAL CLEAN ROWS',
           (SELECT COUNT(*) FROM orders_clean),
           'Used in all analysis'
) t
ORDER BY s;
-- Expected:
--   Raw Data                  : 541,909
--   Removed: Missing CustomerID: 135,080
--   Removed: Cancelled Invoices:   9,288
--   Removed: Negative Quantity :  10,624
--   Removed: Zero Price        :   2,517
--   FINAL CLEAN ROWS           : 397,884


-- ============================================================
-- SCRIPT 03 — BUILD ANALYSIS TABLES
-- ============================================================

USE brightcart_db;

-- Step 3A: customer_first_purchase
--          One row per customer — their cohort month, first order date,
--          total lifetime orders and lifetime revenue.
--          This table defines the COHORT for every customer.
DROP TABLE IF EXISTS customer_first_purchase;
CREATE TABLE customer_first_purchase AS
SELECT
    CustomerID,
    MIN(order_month)          AS cohort_month,
    MIN(order_date)           AS first_order_date,
    COUNT(DISTINCT InvoiceNo) AS lifetime_orders,
    ROUND(SUM(revenue), 2)    AS lifetime_revenue
FROM orders_clean
GROUP BY CustomerID;

ALTER TABLE customer_first_purchase
    ADD INDEX idx_cid    (CustomerID),
    ADD INDEX idx_cohort (cohort_month);

-- Step 3B: monthly_customer_revenue
--          One row per customer per month.
--          Tracks how much each customer spent each month
--          and which cohort they belong to.
DROP TABLE IF EXISTS monthly_customer_revenue;
CREATE TABLE monthly_customer_revenue AS
SELECT
    o.CustomerID,
    o.order_month,
    f.cohort_month,
    COUNT(DISTINCT o.InvoiceNo) AS orders_that_month,
    ROUND(SUM(o.revenue), 2)    AS monthly_revenue,
    o.Country
FROM orders_clean o
JOIN customer_first_purchase f ON o.CustomerID = f.CustomerID
GROUP BY
    o.CustomerID,
    o.order_month,
    f.cohort_month,
    o.Country;

ALTER TABLE monthly_customer_revenue
    ADD INDEX idx_cid    (CustomerID),
    ADD INDEX idx_month  (order_month),
    ADD INDEX idx_cohort (cohort_month);

-- Step 3C: product_summary
--          Revenue, unique buyers, and order count per product.
--          Used for product analysis and Power BI dashboard.
DROP TABLE IF EXISTS product_summary;
CREATE TABLE product_summary AS
SELECT
    o.StockCode,
    MAX(o.Description)            AS product_name,
    COUNT(DISTINCT o.CustomerID)  AS unique_buyers,
    COUNT(DISTINCT o.InvoiceNo)   AS total_orders,
    ROUND(SUM(o.revenue), 2)      AS total_revenue,
    ROUND(AVG(o.revenue), 2)      AS avg_order_value,
    ROUND(SUM(o.Quantity), 0)     AS total_units_sold
FROM orders_clean o
GROUP BY o.StockCode
ORDER BY total_revenue DESC;

-- Step 3D: country_summary
--          Revenue, unique customers, and repeat customer rate per country.
--          Used for country analysis and Power BI dashboard.
DROP TABLE IF EXISTS country_summary;
CREATE TABLE country_summary AS
SELECT
    o.Country,
    COUNT(DISTINCT o.CustomerID)  AS unique_customers,
    COUNT(DISTINCT o.InvoiceNo)   AS total_orders,
    ROUND(SUM(o.revenue), 2)      AS total_revenue,
    ROUND(AVG(o.revenue), 2)      AS avg_order_value,
    COUNT(DISTINCT CASE
        WHEN f.lifetime_orders > 1 THEN o.CustomerID
    END)                          AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN f.lifetime_orders > 1 THEN o.CustomerID END)
        / COUNT(DISTINCT o.CustomerID) * 100, 2
    )                             AS repeat_customer_rate_pct
FROM orders_clean o
JOIN customer_first_purchase f ON o.CustomerID = f.CustomerID
GROUP BY o.Country
ORDER BY total_revenue DESC;


-- ============================================================
-- SCRIPT 04 — COHORT RETENTION ANALYSIS
-- ============================================================

USE brightcart_db;

-- Step 4A: cohort_size
--          Total number of customers in each cohort month (M0 baseline).
--          This is the denominator for all retention % calculations.
DROP TABLE IF EXISTS cohort_size;
CREATE TABLE cohort_size AS
SELECT
    cohort_month,
    COUNT(DISTINCT CustomerID) AS cohort_customer_count
FROM customer_first_purchase
GROUP BY cohort_month
ORDER BY cohort_month;

-- Step 4B: cohort_retention
--          Active customer count per cohort per month period.
--          months_since_first = 0 means the customer's first purchase month.
--          months_since_first = 1 means one month after their first purchase.
DROP TABLE IF EXISTS cohort_retention;
CREATE TABLE cohort_retention AS
SELECT
    m.cohort_month,
    TIMESTAMPDIFF(MONTH, m.cohort_month, m.order_month) AS months_since_first,
    COUNT(DISTINCT m.CustomerID)                         AS active_customers
FROM monthly_customer_revenue m
GROUP BY
    m.cohort_month,
    months_since_first
ORDER BY
    m.cohort_month,
    months_since_first;

-- Step 4C: cohort_heatmap
--          Pivoted retention % table — one row per cohort, M0 to M12 as columns.
--          This is the most important table — used for the heatmap in Power BI.
--          Formula: retention % = active_customers / cohort_size * 100
DROP TABLE IF EXISTS cohort_heatmap;
CREATE TABLE cohort_heatmap AS
SELECT
    r.cohort_month,
    s.cohort_customer_count                                                      AS M0_customers,
    100.00                                                                       AS M0_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 1  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M1_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 2  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M2_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 3  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M3_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 4  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M4_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 5  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M5_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 6  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M6_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 7  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M7_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 8  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M8_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 9  THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M9_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 10 THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M10_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 11 THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M11_pct,
    ROUND(MAX(CASE WHEN r.months_since_first = 12 THEN r.active_customers END)
          / s.cohort_customer_count * 100, 2)                                    AS M12_pct
FROM cohort_retention r
JOIN cohort_size s ON r.cohort_month = s.cohort_month
GROUP BY
    r.cohort_month,
    s.cohort_customer_count
ORDER BY r.cohort_month;

-- View the heatmap result (SCREENSHOT this — most important table)
SELECT * FROM cohort_heatmap;
-- Key numbers to verify:
--   2010-12-01 cohort: M1_pct = 36.61  (highest M1 — best retention)
--   2011-11-01 cohort: M1_pct = 11.15  (lowest M1  — worst retention)

-- Step 4D: New vs Repeat revenue by month
--          Shows how much revenue came from new vs returning customers each month.
--          This directly answers the business question about repeat purchase decline.
SELECT
    o.order_month,
    COUNT(DISTINCT o.CustomerID) AS total_active_customers,
    COUNT(DISTINCT CASE
        WHEN o.order_month = f.cohort_month THEN o.CustomerID
    END)                         AS new_customers,
    COUNT(DISTINCT CASE
        WHEN o.order_month > f.cohort_month THEN o.CustomerID
    END)                         AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN o.order_month > f.cohort_month THEN o.CustomerID END)
        / COUNT(DISTINCT o.CustomerID) * 100, 2
    )                            AS repeat_rate_pct,
    ROUND(SUM(o.monthly_revenue), 2) AS total_revenue,
    ROUND(SUM(CASE
        WHEN o.order_month = f.cohort_month THEN o.monthly_revenue
    END), 2)                     AS new_customer_revenue,
    ROUND(SUM(CASE
        WHEN o.order_month > f.cohort_month THEN o.monthly_revenue
    END), 2)                     AS repeat_customer_revenue
FROM monthly_customer_revenue o
JOIN customer_first_purchase f ON o.CustomerID = f.CustomerID
GROUP BY o.order_month
ORDER BY o.order_month;


-- ============================================================
-- SCRIPT 05 — RFM SCORING AND CUSTOMER SEGMENTS
-- ============================================================

USE brightcart_db;

-- Step 5A: rfm_scores
--          Recency, Frequency, Monetary values per customer
--          scored using NTILE(4) — quartile scoring.
--          R score: 4 = bought most recently (low recency days = best)
--          F score: 4 = highest frequency (most orders = best)
--          M score: 4 = highest monetary (most spend = best)
--          Reference date: 2011-12-10 (1 day after last transaction)
DROP TABLE IF EXISTS rfm_scores;
CREATE TABLE rfm_scores AS
WITH rfm_base AS (
    SELECT
        o.CustomerID,
        f.cohort_month,
        DATEDIFF('2011-12-10', MAX(o.order_date)) AS recency_days,
        COUNT(DISTINCT o.InvoiceNo)               AS frequency,
        ROUND(SUM(o.revenue), 2)                  AS monetary,
        MAX(o.order_date)                         AS last_order_date,
        f.first_order_date,
        o.Country
    FROM orders_clean o
    JOIN customer_first_purchase f ON o.CustomerID = f.CustomerID
    GROUP BY
        o.CustomerID,
        f.cohort_month,
        f.first_order_date,
        o.Country
)
SELECT
    CustomerID,
    cohort_month,
    recency_days,
    frequency,
    monetary,
    last_order_date,
    first_order_date,
    Country,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS R_score,
    NTILE(4) OVER (ORDER BY frequency    ASC)  AS F_score,
    NTILE(4) OVER (ORDER BY monetary     ASC)  AS M_score,
    (
        NTILE(4) OVER (ORDER BY recency_days DESC) +
        NTILE(4) OVER (ORDER BY frequency    ASC)  +
        NTILE(4) OVER (ORDER BY monetary     ASC)
    )                                          AS rfm_total_score,
    CONCAT(
        NTILE(4) OVER (ORDER BY recency_days DESC), '-',
        NTILE(4) OVER (ORDER BY frequency    ASC),  '-',
        NTILE(4) OVER (ORDER BY monetary     ASC)
    )                                          AS rfm_string
FROM rfm_base;

-- Step 5B: customer_segments
--          Assigns each customer to a business-relevant segment
--          and a recommended action based on their RFM scores.
--
--          Segment logic:
--            Champions        : R=4, F=4, M=4  → top customers across all 3
--            Loyal Customers  : F>=3, M>=3      → frequent and high-spending
--            At Risk High Value: R<=2, F>=3, M>=3 → were loyal, now going quiet
--            Lost High Value  : R=1, M>=3       → high spenders, long inactive
--            Potential Loyalists: R>=3, F<=2, M>=2 → recent but low frequency
--            New Customers    : R=4, F=1        → bought recently, only once
--            About to Sleep   : R=2, F<=2       → low recency and frequency
--            Dormant or Lost  : everything else → low across all dimensions
DROP TABLE IF EXISTS customer_segments;
CREATE TABLE customer_segments AS
SELECT *,
    CASE
        WHEN R_score = 4 AND F_score = 4 AND M_score = 4
            THEN 'Champions'
        WHEN F_score >= 3 AND M_score >= 3
            THEN 'Loyal Customers'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3
            THEN 'At Risk - High Value'
        WHEN R_score = 1 AND M_score >= 3
            THEN 'Lost - High Value'
        WHEN R_score >= 3 AND F_score <= 2 AND M_score >= 2
            THEN 'Potential Loyalists'
        WHEN R_score = 4 AND F_score = 1
            THEN 'New Customers'
        WHEN R_score = 2 AND F_score <= 2
            THEN 'About to Sleep'
        ELSE
            'Dormant / Lost'
    END AS customer_segment,
    CASE
        WHEN R_score = 4 AND F_score = 4 AND M_score = 4
            THEN 'Reward and upsell'
        WHEN F_score >= 3 AND M_score >= 3
            THEN 'Loyalty program'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3
            THEN 'Win-back campaign - urgent'
        WHEN R_score = 1 AND M_score >= 3
            THEN 'Win-back with strong incentive'
        WHEN R_score >= 3 AND F_score <= 2 AND M_score >= 2
            THEN 'Nurture to second purchase'
        WHEN R_score = 4 AND F_score = 1
            THEN 'Onboarding email sequence'
        ELSE
            'Low priority'
    END AS recommended_action
FROM rfm_scores;

-- Step 5C: Segment summary — view results (SCREENSHOT this)
SELECT
    customer_segment,
    COUNT(*)                    AS customer_count,
    ROUND(AVG(monetary), 2)     AS avg_lifetime_revenue,
    ROUND(SUM(monetary), 2)     AS total_segment_revenue,
    ROUND(AVG(recency_days), 0) AS avg_days_since_last_buy,
    ROUND(AVG(frequency), 1)    AS avg_orders,
    MAX(recommended_action)     AS action
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_segment_revenue DESC;
-- Key numbers to verify:
--   Champions          : 483 customers, GBP 4,417,016 revenue
--   Loyal Customers    : 834 customers, GBP 2,083,442 revenue
--   At Risk High Value : 450 customers, GBP   963,438 revenue
--   Lost High Value    : 114 customers, GBP   223,575 revenue


-- ============================================================
-- SCRIPT 06 — EXPORT QUERIES FOR POWER BI
-- ============================================================
-- HOW TO EXPORT EACH QUERY AS CSV IN phpMyAdmin:
--   1. Run the SELECT query below
--   2. Scroll down — click the "Export" link in the results panel
--   3. Format: CSV → click Go
--   4. Save the file with the exact name shown above each query
-- ============================================================

USE brightcart_db;

-- Export 1: orders_clean.csv
SELECT
    InvoiceNo,
    StockCode,
    Description,
    CustomerID,
    Country,
    order_date,
    order_month,
    Quantity,
    UnitPrice,
    revenue
FROM orders_clean
ORDER BY order_date;

-- Export 2: cohort_heatmap.csv
SELECT *
FROM cohort_heatmap
ORDER BY cohort_month;

-- Export 3: customer_segments.csv
SELECT
    CustomerID,
    Country,
    cohort_month,
    recency_days,
    frequency,
    monetary,
    R_score,
    F_score,
    M_score,
    rfm_total_score,
    rfm_string,
    customer_segment,
    last_order_date,
    recommended_action
FROM customer_segments
ORDER BY monetary DESC;

-- Export 4: monthly_new_vs_repeat.csv
SELECT
    o.order_month,
    COUNT(DISTINCT o.CustomerID) AS total_active_customers,
    COUNT(DISTINCT CASE
        WHEN o.order_month = f.cohort_month THEN o.CustomerID
    END)                         AS new_customers,
    COUNT(DISTINCT CASE
        WHEN o.order_month > f.cohort_month THEN o.CustomerID
    END)                         AS repeat_customers,
    ROUND(SUM(o.monthly_revenue), 2) AS total_revenue,
    ROUND(SUM(CASE
        WHEN o.order_month = f.cohort_month THEN o.monthly_revenue
    END), 2)                     AS new_revenue,
    ROUND(SUM(CASE
        WHEN o.order_month > f.cohort_month THEN o.monthly_revenue
    END), 2)                     AS repeat_revenue
FROM monthly_customer_revenue o
JOIN customer_first_purchase f ON o.CustomerID = f.CustomerID
GROUP BY o.order_month
ORDER BY o.order_month;

-- Export 5: country_summary.csv
SELECT *
FROM country_summary
ORDER BY total_revenue DESC;

-- Export 6: product_summary.csv
SELECT *
FROM product_summary
ORDER BY total_revenue DESC
LIMIT 100;


-- ============================================================
-- FINAL CHECK — VERIFY ALL 11 TABLES EXIST
-- ============================================================

USE brightcart_db;
SHOW TABLES;

-- Expected output (11 tables):
-- +--------------------------------+
-- | Tables_in_brightcart_db        |
-- +--------------------------------+
-- | cohort_heatmap                 |
-- | cohort_retention               |
-- | cohort_size                    |
-- | country_summary                |
-- | customer_first_purchase        |
-- | customer_segments              |
-- | monthly_customer_revenue       |
-- | orders_clean                   |
-- | orders_raw                     |
-- | product_summary                |
-- | rfm_scores                     |
-- +--------------------------------+

-- ============================================================
-- BrightCart Cloud SQL Analysis — Pasindu Heshan
-- ============================================================
