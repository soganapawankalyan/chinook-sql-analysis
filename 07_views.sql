-- ============================================================
-- 07_views.sql  |  Chinook SQL Analysis (Project 2A)
-- Goal: turn your best queries into reusable views, so a BI tool
--       (Excel, Power BI, Tableau) can connect to clean tables.
-- Safe to re-run: each view is dropped first.
-- ============================================================

DROP VIEW IF EXISTS v_sales_lines;
CREATE VIEW v_sales_lines AS
SELECT
    il.InvoiceLineId,
    i.InvoiceId,
    i.InvoiceDate,
    DATE(i.InvoiceDate, 'start of month')       AS invoice_month,
    STRFTIME('%Y', i.InvoiceDate)               AS invoice_year,
    c.CustomerId,
    c.FirstName || ' ' || c.LastName            AS customer,
    c.Country                                   AS customer_country,
    e.FirstName || ' ' || e.LastName            AS support_rep,
    t.TrackId,
    t.Name                                      AS track,
    COALESCE(g.Name, 'Unknown')                 AS genre,
    m.Name                                      AS media_type,
    al.Title                                    AS album,
    ar.Name                                     AS artist,
    il.Quantity,
    il.UnitPrice,
    il.UnitPrice * il.Quantity                  AS line_revenue
FROM InvoiceLine il
JOIN Invoice   i  ON i.InvoiceId   = il.InvoiceId
JOIN Customer  c  ON c.CustomerId  = i.CustomerId
LEFT JOIN Employee e ON e.EmployeeId = c.SupportRepId
JOIN Track     t  ON t.TrackId     = il.TrackId
LEFT JOIN Genre g ON g.GenreId     = t.GenreId
JOIN MediaType m  ON m.MediaTypeId = t.MediaTypeId
LEFT JOIN Album  al ON al.AlbumId  = t.AlbumId
LEFT JOIN Artist ar ON ar.ArtistId = al.ArtistId;

DROP VIEW IF EXISTS v_monthly_kpis;
CREATE VIEW v_monthly_kpis AS
SELECT
    STRFTIME('%Y-%m', InvoiceDate)  AS ym,
    COUNT(*)                        AS orders,
    COUNT(DISTINCT CustomerId)      AS active_customers,
    ROUND(SUM(Total), 2)            AS revenue,
    ROUND(AVG(Total), 2)            AS avg_order_value
FROM Invoice
GROUP BY ym;

DROP VIEW IF EXISTS v_customer_summary;
CREATE VIEW v_customer_summary AS
SELECT
    c.CustomerId,
    c.FirstName || ' ' || c.LastName      AS customer,
    c.Country,
    COUNT(i.InvoiceId)                    AS orders,
    ROUND(SUM(i.Total), 2)                AS lifetime_revenue,
    MIN(i.InvoiceDate)                    AS first_purchase,
    MAX(i.InvoiceDate)                    AS last_purchase,
    CASE WHEN COUNT(i.InvoiceId) >= 2 THEN 1 ELSE 0 END AS is_repeat_customer
FROM Customer c
LEFT JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId;

DROP VIEW IF EXISTS v_country_summary;
CREATE VIEW v_country_summary AS
SELECT
    Country,
    COUNT(*)                                  AS customers,
    SUM(orders)                               AS orders,
    ROUND(SUM(lifetime_revenue), 2)           AS revenue,
    ROUND(SUM(lifetime_revenue) / COUNT(*), 2) AS revenue_per_customer
FROM v_customer_summary
GROUP BY Country;

DROP VIEW IF EXISTS v_genre_summary;
CREATE VIEW v_genre_summary AS
SELECT
    genre,
    SUM(Quantity)                    AS units,
    ROUND(SUM(line_revenue), 2)      AS revenue
FROM v_sales_lines
GROUP BY genre;

-- Smoke test: every view should return rows
SELECT 'v_sales_lines'      AS view_name, COUNT(*) AS row_count FROM v_sales_lines
UNION ALL SELECT 'v_monthly_kpis',     COUNT(*) FROM v_monthly_kpis
UNION ALL SELECT 'v_customer_summary', COUNT(*) FROM v_customer_summary
UNION ALL SELECT 'v_country_summary',  COUNT(*) FROM v_country_summary
UNION ALL SELECT 'v_genre_summary',    COUNT(*) FROM v_genre_summary;

-- Reconciliation: the view total must equal the invoice total
SELECT
    (SELECT ROUND(SUM(line_revenue), 2) FROM v_sales_lines) AS view_total,
    (SELECT ROUND(SUM(Total), 2)        FROM Invoice)       AS invoice_total;
