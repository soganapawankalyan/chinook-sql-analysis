-- ============================================================
-- 03_revenue_trends.sql  |  Chinook SQL Analysis (Project 2A)
-- Question: How has revenue trended over time?
-- Skills: STRFTIME, CTEs, LAG, moving averages (window frames)
-- ============================================================

-- 3.1 Yearly revenue, orders, and year-over-year growth
WITH yearly AS (
    SELECT
        STRFTIME('%Y', InvoiceDate)  AS yr,
        COUNT(*)                     AS orders,
        COUNT(DISTINCT CustomerId)   AS active_customers,
        ROUND(SUM(Total), 2)         AS revenue
    FROM Invoice
    GROUP BY yr
)
SELECT
    yr,
    orders,
    active_customers,
    revenue,
    ROUND(revenue / orders, 2)                                         AS avg_order_value,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY yr))
          / LAG(revenue) OVER (ORDER BY yr), 1)                        AS yoy_growth_pct
FROM yearly
ORDER BY yr;

-- 3.2 Monthly revenue with a 3-month moving average
-- Note: the moving average is by row, so it assumes no missing months
-- (check with 3.3 first).
WITH monthly AS (
    SELECT
        STRFTIME('%Y-%m', InvoiceDate) AS ym,
        COUNT(*)                       AS orders,
        ROUND(SUM(Total), 2)           AS revenue
    FROM Invoice
    GROUP BY ym
)
SELECT
    ym,
    orders,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY ym ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS revenue_3mo_avg
FROM monthly
ORDER BY ym;

-- 3.3 Gap check: months with no invoices between first and last invoice
WITH RECURSIVE bounds AS (
    SELECT DATE(MIN(InvoiceDate), 'start of month') AS m,
           DATE(MAX(InvoiceDate), 'start of month') AS last_m
    FROM Invoice
),
months AS (
    SELECT m, last_m FROM bounds
    UNION ALL
    SELECT DATE(m, '+1 month'), last_m FROM months WHERE m < last_m
)
SELECT STRFTIME('%Y-%m', m) AS missing_month
FROM months
WHERE STRFTIME('%Y-%m', m) NOT IN (SELECT STRFTIME('%Y-%m', InvoiceDate) FROM Invoice)
ORDER BY missing_month;

-- 3.4 Same month, previous year (year-over-year by month)
WITH monthly AS (
    SELECT
        STRFTIME('%Y-%m', InvoiceDate) AS ym,
        STRFTIME('%Y', InvoiceDate)    AS yr,
        STRFTIME('%m', InvoiceDate)    AS mon,
        SUM(Total)                     AS revenue
    FROM Invoice
    GROUP BY ym
)
SELECT
    cur.ym,
    ROUND(cur.revenue, 2)                                   AS revenue,
    ROUND(prev.revenue, 2)                                  AS revenue_prev_year,
    ROUND(100.0 * (cur.revenue - prev.revenue) / prev.revenue, 1) AS yoy_pct
FROM monthly cur
LEFT JOIN monthly prev
       ON prev.mon = cur.mon
      AND CAST(prev.yr AS INTEGER) = CAST(cur.yr AS INTEGER) - 1
ORDER BY cur.ym;

-- 3.5 Seasonality: average revenue by calendar month across all years
SELECT
    STRFTIME('%m', InvoiceDate)   AS month_num,
    ROUND(SUM(Total) / COUNT(DISTINCT STRFTIME('%Y', InvoiceDate)), 2) AS avg_revenue_per_year
FROM Invoice
GROUP BY month_num
ORDER BY month_num;
