-- Long-format cohort activity. Only calendar years that exist in the data
-- appear, so unobservable cells are simply absent (blank in Tableau, not 0).
WITH first_year AS (
    SELECT CustomerId, CAST(MIN(STRFTIME('%Y', InvoiceDate)) AS INTEGER) AS cohort_year
    FROM Invoice GROUP BY CustomerId
),
sizes AS (
    SELECT cohort_year, COUNT(*) AS cohort_size FROM first_year GROUP BY cohort_year
),
activity AS (
    SELECT DISTINCT CustomerId, CAST(STRFTIME('%Y', InvoiceDate) AS INTEGER) AS active_year
    FROM Invoice
),
years AS (SELECT DISTINCT active_year AS yr FROM activity),
grid AS (
    SELECT s.cohort_year, s.cohort_size, y.yr AS calendar_year
    FROM sizes s JOIN years y ON y.yr >= s.cohort_year
)
SELECT
    g.cohort_year,
    g.calendar_year,
    g.calendar_year - g.cohort_year                             AS years_since_first_purchase,
    g.cohort_size,
    COUNT(DISTINCT a.CustomerId)                                AS active_customers,
    ROUND(100.0 * COUNT(DISTINCT a.CustomerId) / g.cohort_size, 1) AS activity_pct
FROM grid g
JOIN first_year f ON f.cohort_year = g.cohort_year
LEFT JOIN activity a ON a.CustomerId = f.CustomerId AND a.active_year = g.calendar_year
GROUP BY g.cohort_year, g.calendar_year
ORDER BY g.cohort_year, g.calendar_year;
