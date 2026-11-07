-- Genre revenue and sell-through (share of tracks that sold at least once)
WITH track_sales AS (
    SELECT TrackId,
           SUM(Quantity)                AS units,
           SUM(UnitPrice * Quantity)    AS revenue
    FROM InvoiceLine
    GROUP BY TrackId
)
SELECT
    COALESCE(g.Name, 'Unknown')                                   AS genre,
    COUNT(*)                                                      AS tracks_in_genre,
    SUM(CASE WHEN ts.TrackId IS NOT NULL THEN 1 ELSE 0 END)      AS tracks_sold,
    SUM(CASE WHEN ts.TrackId IS NULL THEN 1 ELSE 0 END)          AS tracks_never_sold,
    COALESCE(SUM(ts.units), 0)                                    AS units,
    ROUND(COALESCE(SUM(ts.revenue), 0), 2)                        AS revenue,
    ROUND(100.0 * SUM(CASE WHEN ts.TrackId IS NOT NULL THEN 1 ELSE 0 END)
          / COUNT(*), 1)                                          AS sell_through_pct
FROM Track t
LEFT JOIN Genre g        ON g.GenreId = t.GenreId
LEFT JOIN track_sales ts ON ts.TrackId = t.TrackId
GROUP BY genre
ORDER BY revenue DESC;
