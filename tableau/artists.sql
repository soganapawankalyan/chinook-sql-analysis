-- Revenue by artist (filter to Top 10 inside Tableau)
SELECT
    ar.Name                                   AS artist,
    COUNT(DISTINCT al.AlbumId)                AS albums_sold,
    SUM(il.Quantity)                          AS units,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue,
    ROUND(100.0 * SUM(il.UnitPrice * il.Quantity)
          / (SELECT SUM(UnitPrice * Quantity) FROM InvoiceLine), 1) AS pct_of_revenue
FROM InvoiceLine il
JOIN Track  t  ON t.TrackId   = il.TrackId
JOIN Album  al ON al.AlbumId  = t.AlbumId
JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY ar.ArtistId
ORDER BY revenue DESC;
