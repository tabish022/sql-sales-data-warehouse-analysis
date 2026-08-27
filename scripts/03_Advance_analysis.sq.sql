/* ===================================================================
   ADVANCED_ANALYTICS: Answering business questions
   =================================================================== */
USE DataWarehouseAnalytics;


-- ============ 1. CHANGE-OVER-TIME / TREND ANALYSIS ============
SELECT
    YEAR(order_date)  AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS monthly_revenue,
    COUNT(DISTINCT order_number) AS monthly_orders
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY order_year, order_month;
-- FOUND: 2010 (14 orders) and 2014 (Jan only, 871 orders) are partial
-- years — do not compare them to full years like 2013 without
-- annualizing, or the "trend" will look like a cliff that isn't real.
-- Within 2013, revenue climbs from $858K (Jan) to $1.87M (Dec) with a
-- dip in Feb — a real seasonal ramp into the holidays, not noise.


-- ============ 2. CUMULATIVE ANALYSIS (running total + moving avg) ============
SELECT order_year, monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY order_year, order_month
                                ROWS UNBOUNDED PRECEDING) AS running_total_revenue,
    AVG(monthly_revenue) OVER (ORDER BY order_year, order_month
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3mo
FROM (
    SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month,
           SUM(sales_amount) AS monthly_revenue
    FROM fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date), MONTH(order_date)
) monthly
ORDER BY order_year, order_month;


-- ============ 3. PART-TO-WHOLE ANALYSIS ============
SELECT
    p.category,
    SUM(f.sales_amount) AS category_revenue,
    SUM(SUM(f.sales_amount)) OVER () AS total_revenue,
    CAST(SUM(f.sales_amount) AS FLOAT) / SUM(SUM(f.sales_amount)) OVER () * 100 AS pct_of_total
FROM fact_sales f
JOIN dim_products p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY category_revenue DESC;
-- FOUND: Bikes = 96.46% of total revenue, Accessories = 2.39%,
-- Clothing = 1.16%. This company's growth story lives almost entirely
-- in bikes; accessories/clothing are rounding errors by comparison —
-- worth knowing before recommending a "grow accessories" initiative.

-- ============ 4. DATA SEGMENTATION ============
-- Customers by spend tier + tenure
WITH customer_agg AS (
    SELECT customer_key,
           SUM(sales_amount) AS total_spend,
           timestampdiff(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months
    FROM fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY customer_key
)
SELECT
    CASE WHEN lifespan_months >= 12 AND total_spend > 5000 THEN 'VIP'
         WHEN lifespan_months >= 12 AND total_spend <= 5000 THEN 'Regular'
         ELSE 'New' END AS customer_segment,
    COUNT(*) AS num_customers
FROM customer_agg
GROUP BY CASE WHEN lifespan_months >= 12 AND total_spend > 5000 THEN 'VIP'
              WHEN lifespan_months >= 12 AND total_spend <= 5000 THEN 'Regular'
              ELSE 'New' END
ORDER BY num_customers DESC;
-- FOUND: New = 14,629 (~79%), Regular = 2,200 (~12%), VIP = 1,653
-- (~9%). A very "long tail of one-time or short-tenure buyers" shape —
-- retention/repeat-purchase is probably the highest-leverage lever
-- here, not acquisition.

-- Products by cost tier
SELECT
    CASE WHEN cost < 100 THEN 'Below 100'
         WHEN cost BETWEEN 100 AND 500 THEN '100-500'
         WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
         ELSE 'Above 1000' END AS cost_range,
    COUNT(*) AS num_products
FROM dim_products
GROUP BY CASE WHEN cost < 100 THEN 'Below 100'
              WHEN cost BETWEEN 100 AND 500 THEN '100-500'
              WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
              ELSE 'Above 1000' END
ORDER BY num_products DESC;

-- ============ 5. ROLLUP: subtotal + grand total revenue by category/subcategory ============
SELECT
    p.category,
    p.subcategory,
    SUM(f.sales_amount) AS revenue
FROM fact_sales f
JOIN dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category, p.subcategory WITH ROLLUP
ORDER BY p.category, p.subcategory;