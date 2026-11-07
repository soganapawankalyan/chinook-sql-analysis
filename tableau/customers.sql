-- One row per customer: spend distribution, cohort and lapsed status
-- Reference date is the last invoice in the data (not today).
SELECT
    cs.CustomerId                                         AS customer_id,
    cs.customer,
    cs.Country                                            AS country,
    cs.orders,
    cs.lifetime_revenue,
    DATE(cs.first_purchase)                               AS first_purchase,
    DATE(cs.last_purchase)                                AS last_purchase,
    CAST(STRFTIME('%Y', cs.first_purchase) AS INTEGER)    AS cohort_year,
    CAST(JULIANDAY((SELECT MAX(InvoiceDate) FROM Invoice))
         - JULIANDAY(cs.last_purchase) AS INTEGER)        AS days_inactive,
    CASE WHEN JULIANDAY((SELECT MAX(InvoiceDate) FROM Invoice))
              - JULIANDAY(cs.last_purchase) > 365
         THEN 'Lapsed (365+ days)' ELSE 'Active' END      AS status
FROM v_customer_summary cs
ORDER BY cs.CustomerId;
