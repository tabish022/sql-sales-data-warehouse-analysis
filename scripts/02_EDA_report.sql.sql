/* ===================================================================
   EDA: Exploratory Data Analysis
   =================================================================== */
USE DataWarehouseAnalytics;


-- ============ 1. DATABASE EXPLORATION ============
SELECT * FROM INFORMATION_SCHEMA.columns
WHERE TABLE_NAME = 'dim_customers';

SELECT * FROM INFORMATION_SCHEMA.columns
WHERE TABLE_NAME = 'dim_products';

SELECT * FROM INFORMATION_SCHEMA.columns
WHERE TABLE_NAME = 'fact_sales';


-- ============ 2. DIMENSIONS EXPLORATION ============
SELECT DISTINCT country FROM dim_customers ORDER BY country;
SELECT DISTINCT gender, marital_status FROM dim_customers;
SELECT DISTINCT category, subcategory, product_name
FROM dim_products ORDER BY category, subcategory, product_name;


-- ============ 3. DATE EXPLORATION ============
-- Order date range + span in years/months
SELECT
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS months_of_data,
    TIMESTAMPDIFF(YEAR, MIN(order_date), MAX(order_date)) AS years_of_data
FROM fact_sales
WHERE order_date IS NOT NULL;
-- FOUND: data runs 2010-12-29 → 2014-01-28 (~36 months), but 2010 and
-- 2010 and 2014 are nearly-empty year 

-- Youngest / oldest customer by birthdate
SELECT
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate,
    TIMESTAMPDIFF(YEAR, MIN(birthdate), CURDATE()) AS oldest_age,
    TIMESTAMPDIFF(YEAR, MAX(birthdate), CURDATE()) AS youngest_age
FROM dim_customers
WHERE birthdate IS NOT NULL;
-- FOUND: ages range ~40 to ~110 (as of 2014, the last order year) —
-- a wide, plausible adult customer base.


-- ============ 4. MEASURES EXPLORATION ============
SELECT
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
    ROUND(AVG(price), 2) AS avg_price,
    COUNT(DISTINCT order_number) AS total_orders,
    COUNT(DISTINCT customer_key) AS total_customers_with_orders,
    COUNT(DISTINCT product_key) AS total_products_sold
FROM fact_sales;
-- FOUND: $29,356,250 total revenue | 60,423 units | avg unit price
-- ~$486 | 27,659 distinct orders | 18,482 customers (every customer in
-- the dimension has at least one order — this table was built as a
-- "customers who purchased" mart) | 130 of the 295 products in the
-- catalog actually sold.


-- ============ 5. MAGNITUDE ANALYSIS (measures BY dimension) ============
-- Revenue & customer count by country
SELECT c.country,
       SUM(f.sales_amount) AS total_revenue,
       COUNT(DISTINCT c.customer_key) AS customers
FROM fact_sales f
JOIN dim_customers c ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;
-- FOUND: US ($9.16M) and Australia ($9.06M) are almost tied for #1,
-- together ~62% of revenue. UK/Germany/France cluster $2.6-3.4M each.
-- Canada is smallest real market at ~$2.0M. 'n/a' country is only
-- ~1.8% of revenue but still 337 customers worth cleaning upstream.

-- Revenue by product category
SELECT p.category, SUM(f.sales_amount) AS total_revenue
FROM fact_sales f
JOIN dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
-- FOUND: Bikes = $28.3M (96.5% of ALL revenue). Accessories $700K,
-- Clothing $340K. This is a bikes company that happens to also sell
-- accessories/clothing — any category-level strategy work should
-- treat those as a distinct, much smaller business line.

-- Total customers by gender
SELECT gender, COUNT(*) AS customers
FROM dim_customers
GROUP BY gender
ORDER BY customers DESC;
-- 9.3k male, 9.1k female, 14 n/a
-- this shows that company have almost same number of customers from both genders


-- ============ 6. RANKING ANALYSIS ============
-- Top 5 products by revenue
SELECT p.product_name, SUM(f.sales_amount) AS revenue
FROM fact_sales f
JOIN dim_products p ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 5;
-- FOUND: the top 5 are all Mountain-200 variants (Black/Silver, sizes
-- 38-46), each earning $1.29M-$1.37M — one product line dominates.

-- Bottom 5 customers by number of orders (using window function)
SELECT customer_key, order_count FROM (
    SELECT customer_key, COUNT(DISTINCT order_number) AS order_count,
           RANK() OVER (ORDER BY COUNT(DISTINCT order_number) ASC) AS rnk
    FROM fact_sales
    GROUP BY customer_key
) ranked
ORDER BY order_count ASC
LIMIT 5;
-- FOUND: the bottom 5 all have 1 order_count

-- Top 5 products by revenue using window functions (alternative to TOP N)
SELECT * FROM (
    SELECT p.product_name, SUM(f.sales_amount) AS revenue,
           ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rn
    FROM fact_sales f
    JOIN dim_products p ON f.product_key = p.product_key
    GROUP BY p.product_name
) t
WHERE rn <= 5;


-- ============ 7. CONSOLIDATED KEY METRICS REPORT ============
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM fact_sales
UNION ALL
SELECT 'Average Price', ROUND(AVG(price), 2) FROM fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM fact_sales
UNION ALL
SELECT 'Total Products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'Total Customers', COUNT(*) FROM dim_customers
UNION ALL
SELECT 'Customers With Orders', COUNT(DISTINCT customer_key) FROM fact_sales;