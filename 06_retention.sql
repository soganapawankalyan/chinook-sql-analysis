-- ============================================================
-- 06_retention.sql  |  Chinook SQL Analysis (Project 2A)
-- Questions: How many customers buy again? How long between purchases?
--            Do customers acquired in one year behave differently?
-- Skills: LAG, JULIANDAY, PARTITION BY, cohort tables, CASE buckets
-- ============================================================

-- 6.1 Repeat purchase rate
WITH orders_per_customer AS (
    SELECT CustomerId, COUNT(*) AS orders
    FROM Invoice
    GROUP BY CustomerId
)
SELECT
    COUNT(*)                                                   AS customers,
    SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END)               AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct,
    ROUND(AVG(orders), 2)                                      AS avg_orders_per_customer
FROM orders_per_customer;

-- 6.2 Distribution of orders per customer
WITH orders_per_customer AS (
    SELECT CustomerId, COUNT(*) AS orders FROM Invoice GROUP BY CustomerId
)
SELECT orders, COUNT(*) AS customers
FROM orders_per_customer
GROUP BY orders
ORDER BY orders;

-- 6.3 Days between consecutive purchases (per customer)
WITH gaps AS (
    SELECT
        CustomerId,
        InvoiceDate,
        JULIANDAY(InvoiceDate)
          - JULIANDAY(LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)) AS days_since_prev
    FROM Invoice
)
SELECT
    COUNT(days_since_prev)              AS repeat_purchases,
    ROUND(AVG(days_since_prev), 1)      AS avg_days_between,
    MIN(days_since_prev)                AS min_days,
    MAX(days_since_prev)                AS max_days
FROM gaps
WHERE days_since_prev IS NOT NULL;

-- 6.4 Buckets of days between purchases (feeds a histogram)
WITH gaps AS (
    SELECT
        JULIANDAY(InvoiceDate)
          - JULIANDAY(LAG(InvoiceDate) OVER (PARTITION BY CustomerId ORDER BY InvoiceDate)) AS d
    FROM Invoice
)
SELECT
    CASE
        WHEN d <= 30  THEN '0-30 days'
        WHEN d <= 90  THEN '31-90 days'
        WHEN d <= 180 THEN '91-180 days'
        WHEN d <= 365 THEN '181-365 days'
        ELSE '365+ days'
    END AS gap_bucket,
    COUNT(*) AS purchases
FROM gaps
WHERE d IS NOT NULL
GROUP BY gap_bucket
ORDER BY MIN(d);

-- 6.5 Cohort table: customers by first-purchase year (rows) and active year (columns)
WITH first_year AS (
    SELECT CustomerId, MIN(STRFTIME('%Y', InvoiceDate)) AS cohort_year
    FROM Invoice
    GROUP BY CustomerId
),
activity AS (
    SELECT DISTINCT CustomerId, STRFTIME('%Y', InvoiceDate) AS active_year
    FROM Invoice
)
SELECT
    f.cohort_year,
    COUNT(DISTINCT CASE WHEN a.active_year = f.cohort_year THEN a.CustomerId END) AS y0_customers,
    SUM(CASE WHEN CAST(a.active_year AS INTEGER) = CAST(f.cohort_year AS INTEGER) + 1 THEN 1 ELSE 0 END) AS active_year_1,
    SUM(CASE WHEN CAST(a.active_year AS INTEGER) = CAST(f.cohort_year AS INTEGER) + 2 THEN 1 ELSE 0 END) AS active_year_2,
    SUM(CASE WHEN CAST(a.active_year AS INTEGER) = CAST(f.cohort_year AS INTEGER) + 3 THEN 1 ELSE 0 END) AS active_year_3,
    SUM(CASE WHEN CAST(a.active_year AS INTEGER) = CAST(f.cohort_year AS INTEGER) + 4 THEN 1 ELSE 0 END) AS active_year_4
FROM first_year f
JOIN activity a ON a.CustomerId = f.CustomerId
GROUP BY f.cohort_year
ORDER BY f.cohort_year;

-- 6.6 Customers who have not purchased in the last 365 days of the data
-- (a simple "at risk" list; the reference date is the last invoice in the data,
--  NOT today, because the sample data is historical)
WITH ref AS (SELECT MAX(InvoiceDate) AS ref_date FROM Invoice),
last_purchase AS (
    SELECT CustomerId, MAX(InvoiceDate) AS last_date, COUNT(*) AS orders,
           ROUND(SUM(Total), 2) AS lifetime_revenue
    FROM Invoice
    GROUP BY CustomerId
)
SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName AS customer,
    c.Country,
    lp.last_date,
    CAST(JULIANDAY(r.ref_date) - JULIANDAY(lp.last_date) AS INTEGER) AS days_inactive,
    lp.orders,
    lp.lifetime_revenue
FROM last_purchase lp
CROSS JOIN ref r
JOIN Customer c ON c.CustomerId = lp.CustomerId
WHERE JULIANDAY(r.ref_date) - JULIANDAY(lp.last_date) > 365
ORDER BY lp.lifetime_revenue DESC;
