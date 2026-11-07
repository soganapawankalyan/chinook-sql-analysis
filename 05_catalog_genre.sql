-- ============================================================
-- 05_catalog_genre.sql  |  Chinook SQL Analysis (Project 2A)
-- Questions: Which genres, artists and tracks sell? What never sells?
-- Skills: multi-table joins, LEFT JOIN anti-join, COALESCE, RANK
-- ============================================================

-- 5.1 Revenue by genre
SELECT
    COALESCE(g.Name, 'Unknown')                              AS genre,
    COUNT(DISTINCT t.TrackId)                                AS tracks_sold,
    SUM(il.Quantity)                                         AS units,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2)                AS revenue,
    ROUND(100.0 * SUM(il.UnitPrice * il.Quantity)
          / (SELECT SUM(UnitPrice * Quantity) FROM InvoiceLine), 1) AS pct_of_revenue
FROM InvoiceLine il
JOIN Track t       ON t.TrackId = il.TrackId
LEFT JOIN Genre g  ON g.GenreId = t.GenreId
GROUP BY genre
ORDER BY revenue DESC;

-- 5.2 Top 10 artists by revenue
SELECT
    RANK() OVER (ORDER BY SUM(il.UnitPrice * il.Quantity) DESC) AS rnk,
    ar.Name                                   AS artist,
    COUNT(DISTINCT al.AlbumId)                AS albums_sold,
    SUM(il.Quantity)                          AS units,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track  t  ON t.TrackId  = il.TrackId
JOIN Album  al ON al.AlbumId = t.AlbumId
JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY ar.ArtistId
ORDER BY revenue DESC
LIMIT 10;

-- 5.3 Top 3 artists inside each of the top genres (window function by partition)
WITH artist_genre AS (
    SELECT
        COALESCE(g.Name, 'Unknown')               AS genre,
        ar.Name                                   AS artist,
        SUM(il.UnitPrice * il.Quantity)           AS revenue
    FROM InvoiceLine il
    JOIN Track  t  ON t.TrackId   = il.TrackId
    JOIN Album  al ON al.AlbumId  = t.AlbumId
    JOIN Artist ar ON ar.ArtistId = al.ArtistId
    LEFT JOIN Genre g ON g.GenreId = t.GenreId
    GROUP BY genre, artist
),
ranked AS (
    SELECT genre, artist, revenue,
           RANK() OVER (PARTITION BY genre ORDER BY revenue DESC) AS rnk
    FROM artist_genre
)
SELECT genre, rnk, artist, ROUND(revenue, 2) AS revenue
FROM ranked
WHERE rnk <= 3
  AND genre IN (
      SELECT genre FROM artist_genre GROUP BY genre ORDER BY SUM(revenue) DESC LIMIT 5)
ORDER BY genre, rnk;

-- 5.4 Tracks that have never been purchased (anti-join)
SELECT COUNT(*) AS never_sold_tracks,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM Track), 1) AS pct_of_catalog
FROM Track t
LEFT JOIN InvoiceLine il ON il.TrackId = t.TrackId
WHERE il.InvoiceLineId IS NULL;

-- 5.5 Never-sold tracks by genre (where is the dead weight?)
SELECT
    COALESCE(g.Name, 'Unknown')   AS genre,
    COUNT(*)                      AS never_sold_tracks,
    (SELECT COUNT(*) FROM Track t2
     WHERE COALESCE(t2.GenreId, -1) = COALESCE(t.GenreId, -1)) AS tracks_in_genre
FROM Track t
LEFT JOIN InvoiceLine il ON il.TrackId = t.TrackId
LEFT JOIN Genre g        ON g.GenreId  = t.GenreId
WHERE il.InvoiceLineId IS NULL
GROUP BY genre
ORDER BY never_sold_tracks DESC;

-- 5.6 Media type split (format mix)
SELECT
    m.Name                                    AS media_type,
    SUM(il.Quantity)                          AS units,
    ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t      ON t.TrackId = il.TrackId
JOIN MediaType m  ON m.MediaTypeId = t.MediaTypeId
GROUP BY m.MediaTypeId
ORDER BY revenue DESC;

-- 5.7 Average track price and length of best-selling tracks (top 10 by units)
SELECT
    t.Name                                     AS track,
    ar.Name                                    AS artist,
    SUM(il.Quantity)                           AS units,
    ROUND(t.Milliseconds / 60000.0, 1)         AS minutes
FROM InvoiceLine il
JOIN Track  t  ON t.TrackId   = il.TrackId
JOIN Album  al ON al.AlbumId  = t.AlbumId
JOIN Artist ar ON ar.ArtistId = al.ArtistId
GROUP BY t.TrackId
ORDER BY units DESC, track
LIMIT 10;
