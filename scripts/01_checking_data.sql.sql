/* ===================================================================
   Checking Data
   =================================================================== */
USE DataWarehouseAnalytics;


-- 1. Row counts
SELECT 'dim_customers' AS table_names, COUNT(*) AS rows_count FROM dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM fact_sales;
-- FOUND: 18,484 customers | 295 products | 60,398 sales line items


-- 2. Nulls / blanks in dates
SELECT COUNT(*) AS blank_order_dates FROM fact_sales WHERE order_date IS NULL;
SELECT COUNT(*) AS blank_birthdates  FROM dim_customers WHERE birthdate IS NULL;
-- FOUND: 0 rows with a blank order_date, 0 customers with a blank
-- birthdate. If there is only few blank dates , then you can leave it NULL and exclude via WHERE in
-- date-driven queries rather than guessing a fill value.


-- 3. Invalid measures (negative/zero price, quantity, sales_amount)
SELECT * FROM fact_sales
WHERE sales_amount <= 0 OR quantity <= 0 OR price <= 0;
-- FOUND: 0 rows — measures are clean, no negative-price cleanup needed.


-- 4. sales_amount consistency check (should equal quantity * price)
SELECT order_number, product_key, sales_amount, quantity, price,
       quantity * price AS expected_amount
FROM fact_sales
WHERE sales_amount <> quantity * price;
-- everything is fine as expected


-- 5. Non-standard categorical values
SELECT count(customer_id), gender FROM dim_customers group by gender;
-- FOUND: 'Male', 'Female', 'n/a' (14 customers) — keep 'n/a' as its own
-- bucket in reports rather than dropping those rows.

SELECT DISTINCT marital_status FROM dim_customers;
-- FOUND: clean — only 'Married' / 'Single'.

SELECT count(customer_id), country FROM dim_customers group by country;
-- FOUND: 6 real countries + 'n/a' (337 customers, ~2%).

SELECT DISTINCT category FROM dim_products;
-- FOUND: 'Bikes','Components','Clothing','Accessories' + 7 products with
-- a blank category — worth flagging to whoever owns the product master.


-- 6. Implausible birthdates (age outliers)
SELECT customer_key, first_name, last_name, birthdate,
    TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) AS age
FROM dim_customers
WHERE birthdate IS NOT NULL
  AND (TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) > 100
        OR birthdate > CURDATE());
-- FOUND: oldest customer birthdate is 1916-02-10 → ~110 yrs old today.
-- Not impossible, but old enough to flag/verify with the source system
-- rather than silently trust.


-- 7. Duplicate natural keys
SELECT customer_id, COUNT(*) FROM dim_customers GROUP BY customer_id HAVING COUNT(*) > 1;
SELECT product_id, COUNT(*) FROM dim_products  GROUP BY product_id  HAVING COUNT(*) > 1;
SELECT order_number, product_key, customer_key, COUNT(*)
FROM fact_sales GROUP BY order_number, product_key, customer_key HAVING COUNT(*) > 1;
-- FOUND: no duplicates on dim_customers and dim_products
-- Duplicate combinations exist in fact_sales; next, investigate whether 
-- they are true duplicate records or valid multiple sales line items before removing or defining a primary key