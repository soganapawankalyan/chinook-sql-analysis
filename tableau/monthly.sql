-- Monthly KPIs for the revenue line (month_start is a real date for Tableau)
SELECT
    ym || '-01'      AS month_start,
    orders,
    active_customers,
    revenue,
    avg_order_value
FROM v_monthly_kpis
ORDER BY ym;
