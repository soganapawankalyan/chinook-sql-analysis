-- ============================================================
-- 02_data_quality.sql  |  Chinook SQL Analysis (Project 2A)
-- Goal: prove the data can be trusted BEFORE analysing it.
-- Every check below should return 0 rows (or matching totals).
-- If one does not, log it in your README data-quality log
-- instead of silently fixing it.
-- ============================================================

-- 2.1 Invoice total vs sum of its lines (should return 0 rows)
SELECT
    i.InvoiceId,
    i.Total                                        AS invoice_total,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2)      AS line_total
FROM Invoice i
JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
GROUP BY i.InvoiceId, i.Total
HAVING ABS(i.Total - SUM(il.UnitPrice * il.Quantity)) > 0.01;

-- 2.2 Invoices with no lines (should return 0 rows)
SELECT i.InvoiceId
FROM Invoice i
LEFT JOIN InvoiceLine il ON il.InvoiceId = i.InvoiceId
WHERE il.InvoiceLineId IS NULL;

-- 2.3 Invoice lines pointing to a missing track (should return 0 rows)
SELECT il.InvoiceLineId, il.TrackId
FROM InvoiceLine il
LEFT JOIN Track t ON t.TrackId = il.TrackId
WHERE t.TrackId IS NULL;

-- 2.4 Invoices pointing to a missing customer (should return 0 rows)
SELECT i.InvoiceId, i.CustomerId
FROM Invoice i
LEFT JOIN Customer c ON c.CustomerId = i.CustomerId
WHERE c.CustomerId IS NULL;

-- 2.5 Tracks with no genre (informational; handle with COALESCE later)
SELECT COUNT(*) AS tracks_without_genre
FROM Track
WHERE GenreId IS NULL;

-- 2.6 Possible duplicate customers (same name + email)
SELECT FirstName, LastName, Email, COUNT(*) AS copies
FROM Customer
GROUP BY FirstName, LastName, Email
HAVING COUNT(*) > 1;

-- 2.7 Non-positive prices or quantities (should return 0 rows)
SELECT InvoiceLineId, UnitPrice, Quantity
FROM InvoiceLine
WHERE UnitPrice <= 0 OR Quantity <= 0;

-- 2.8 Country spelling check: billing vs customer country mismatches
-- (a mismatch is not an error, but decide which country to report on)
SELECT
    COUNT(*) AS invoices_with_mismatch
FROM Invoice i
JOIN Customer c ON c.CustomerId = i.CustomerId
WHERE i.BillingCountry <> c.Country;

-- 2.9 Three-way revenue reconciliation (all three numbers must match)
SELECT
    (SELECT ROUND(SUM(Total), 2)                   FROM Invoice)                     AS from_invoice,
    (SELECT ROUND(SUM(UnitPrice * Quantity), 2)    FROM InvoiceLine)                 AS from_invoice_line,
    (SELECT ROUND(SUM(rev), 2) FROM (
        SELECT SUM(Total) AS rev FROM Invoice GROUP BY BillingCountry))              AS from_country_rollup;

-- 2.10 Date sanity: invoices outside the expected range, or in the future
SELECT InvoiceId, InvoiceDate
FROM Invoice
WHERE InvoiceDate IS NULL
   OR InvoiceDate > DATE('now');
