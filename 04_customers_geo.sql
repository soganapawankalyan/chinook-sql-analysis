-- ============================================================
-- 04_customers_geo.sql  |  Chinook SQL Analysis (Project 2A)
-- Questions: Who are the top customers? How concentrated is revenue?
--            Which countries matter, per customer and in total?
--            How do support reps compare?
-- Skills: RANK, cumulative SUM OVER, CTEs, joins, ratios
-- ============================================================

-- 4.1 Top 10 customers by lifetime revenue
SELECT
    RANK() OVER (ORDER BY SUM(i.Total) DESC) AS rnk,
    c.CustomerId,
    c.FirstName || ' ' || c.LastName         AS customer,
    c.Country,
    COUNT(i.InvoiceId)                       AS orders,
    ROUND(SUM(i.Total), 2)                   AS lifetime_revenue
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- 4.2 Pareto: cumulative revenue share by customer (top 20% rule test)
WITH cust AS (
    SELECT CustomerId, SUM(Total) AS rev
    FROM Invoice
    GROUP BY CustomerId
),
ranked AS (
    SELECT
        CustomerId,
        rev,
        ROW_NUMBER() OVER (ORDER BY rev DESC, CustomerId)            AS pos,
        COUNT(*)     OVER ()                                         AS n_customers,
        SUM(rev)     OVER (ORDER BY rev DESC, CustomerId
                           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_rev,
        SUM(rev)     OVER ()                                         AS total_rev
    FROM cust
)
SELECT
    pos,
    CustomerId,
    ROUND(rev, 2)                               AS revenue,
    ROUND(100.0 * pos / n_customers, 1)         AS pct_of_customers,
    ROUND(100.0 * cum_rev / total_rev, 1)       AS cum_pct_of_revenue
FROM ranked
ORDER BY pos;

-- 4.3 Direct answer: what share of revenue comes from the top 20% of customers?
WITH cust AS (
    SELECT CustomerId, SUM(Total) AS rev FROM Invoice GROUP BY CustomerId
),
ranked AS (
    SELECT rev,
           ROW_NUMBER() OVER (ORDER BY rev DESC, CustomerId) AS pos,
           COUNT(*) OVER () AS n
    FROM cust
)
SELECT
    ROUND(100.0 * SUM(CASE WHEN pos <= CEIL_N THEN rev END) / SUM(rev), 1) AS top20pct_revenue_share
FROM (
    SELECT rev, pos, n, (n * 20 + 99) / 100 AS CEIL_N FROM ranked
);

-- 4.4 Country performance: total revenue, customers, revenue per customer
SELECT
    c.Country,
    COUNT(DISTINCT c.CustomerId)                          AS customers,
    COUNT(i.InvoiceId)                                    AS orders,
    ROUND(SUM(i.Total), 2)                                AS revenue,
    ROUND(SUM(i.Total) / COUNT(DISTINCT c.CustomerId), 2) AS revenue_per_customer,
    ROUND(100.0 * SUM(i.Total) / (SELECT SUM(Total) FROM Invoice), 1) AS pct_of_revenue
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.Country
ORDER BY revenue DESC;

-- 4.5 Countries ranked within region of interest: top 5 by revenue per customer
-- (only countries with 2+ customers, so one big spender does not dominate)
SELECT
    c.Country,
    COUNT(DISTINCT c.CustomerId)                          AS customers,
    ROUND(SUM(i.Total) / COUNT(DISTINCT c.CustomerId), 2) AS revenue_per_customer
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.Country
HAVING COUNT(DISTINCT c.CustomerId) >= 2
ORDER BY revenue_per_customer DESC
LIMIT 5;

-- 4.6 Support rep view: revenue and customers per rep
SELECT
    e.EmployeeId,
    e.FirstName || ' ' || e.LastName                       AS support_rep,
    COUNT(DISTINCT c.CustomerId)                           AS customers,
    ROUND(SUM(i.Total), 2)                                 AS revenue,
    ROUND(SUM(i.Total) / COUNT(DISTINCT c.CustomerId), 2)  AS revenue_per_customer
FROM Employee e
JOIN Customer c ON c.SupportRepId = e.EmployeeId
JOIN Invoice  i ON i.CustomerId   = c.CustomerId
GROUP BY e.EmployeeId
ORDER BY revenue DESC;
