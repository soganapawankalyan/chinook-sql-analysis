-- ============================================================
-- 01_profiling.sql  |  Chinook SQL Analysis (Project 2A)
-- Goal: understand the schema, row counts, date range, and nulls
-- Dialect: SQLite (names follow Chinook v1.4 CamelCase; adjust if
--          your version uses snake_case or lowercase)
-- Run each block separately and paste the results into your README.
-- ============================================================

-- 1.1 List all tables
SELECT name AS table_name
FROM sqlite_master
WHERE type = 'table'
ORDER BY name;

-- 1.2 Row counts for every table (one result set)
SELECT 'Artist'       AS table_name, COUNT(*) AS row_count FROM Artist
UNION ALL SELECT 'Album',        COUNT(*) FROM Album
UNION ALL SELECT 'Track',        COUNT(*) FROM Track
UNION ALL SELECT 'Genre',        COUNT(*) FROM Genre
UNION ALL SELECT 'MediaType',    COUNT(*) FROM MediaType
UNION ALL SELECT 'Customer',     COUNT(*) FROM Customer
UNION ALL SELECT 'Employee',     COUNT(*) FROM Employee
UNION ALL SELECT 'Invoice',      COUNT(*) FROM Invoice
UNION ALL SELECT 'InvoiceLine',  COUNT(*) FROM InvoiceLine
UNION ALL SELECT 'Playlist',     COUNT(*) FROM Playlist
UNION ALL SELECT 'PlaylistTrack',COUNT(*) FROM PlaylistTrack;

-- 1.3 Column details for the tables you will use most
PRAGMA table_info(Invoice);
PRAGMA table_info(InvoiceLine);
PRAGMA table_info(Customer);
PRAGMA table_info(Track);

-- 1.4 Date range and volume of sales
SELECT
    MIN(InvoiceDate)              AS first_invoice,
    MAX(InvoiceDate)              AS last_invoice,
    COUNT(*)                      AS invoices,
    COUNT(DISTINCT CustomerId)    AS customers_who_bought,
    ROUND(SUM(Total), 2)          AS total_revenue,
    ROUND(AVG(Total), 2)          AS avg_order_value
FROM Invoice;

-- 1.5 Invoices per year (is every year fully covered?)
SELECT
    STRFTIME('%Y', InvoiceDate)   AS yr,
    COUNT(*)                      AS invoices,
    ROUND(SUM(Total), 2)          AS revenue
FROM Invoice
GROUP BY yr
ORDER BY yr;

-- 1.6 Null profile for Customer columns
SELECT
    COUNT(*)                                         AS customers,
    SUM(CASE WHEN Company  IS NULL THEN 1 ELSE 0 END) AS null_company,
    SUM(CASE WHEN State    IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN PostalCode IS NULL THEN 1 ELSE 0 END) AS null_postal,
    SUM(CASE WHEN Phone    IS NULL THEN 1 ELSE 0 END) AS null_phone,
    SUM(CASE WHEN Fax      IS NULL THEN 1 ELSE 0 END) AS null_fax,
    SUM(CASE WHEN SupportRepId IS NULL THEN 1 ELSE 0 END) AS null_support_rep
FROM Customer;

-- 1.7 Null profile for Track columns
SELECT
    COUNT(*)                                          AS tracks,
    SUM(CASE WHEN GenreId   IS NULL THEN 1 ELSE 0 END) AS null_genre,
    SUM(CASE WHEN AlbumId   IS NULL THEN 1 ELSE 0 END) AS null_album,
    SUM(CASE WHEN Composer  IS NULL THEN 1 ELSE 0 END) AS null_composer
FROM Track;

-- 1.8 Customers by country (quick look at geography)
SELECT Country, COUNT(*) AS customers
FROM Customer
GROUP BY Country
ORDER BY customers DESC, Country;
