WITH invoice_match AS (
    SELECT 
        a.invoice_number, 
        a.supplier_id,
        b.invoice__,
        CASE WHEN b.invoice__ IS NULL AND a.invoice_number IS NOT NULL THEN 1 ELSE 0 END AS missing_invoice_indicator
    FROM cleansed.coupa.coupa_invoice_header_bcv a
    LEFT JOIN _sandbox_working_capital.working_capital.wc_ap_zdp b
        ON a.invoice_number = b.invoice__
    WHERE 1=1
      and date(a.payment_date) between '2025-09-01' and '2025-12-31'
      AND a.PAID = true
),
supplier_summary as (
SELECT 
    supplier_id,
    COUNT(*) AS total_invoices,
    SUM(missing_invoice_indicator) AS missing_invoices,
    COUNT(*) - SUM(missing_invoice_indicator) AS matched_invoices,
    ROUND(SUM(missing_invoice_indicator) * 100.0 / COUNT(*), 2) AS missing_rate_pct,
    ROUND((COUNT(*) - SUM(missing_invoice_indicator)) * 100.0 / COUNT(*), 2) AS match_rate_pct
FROM invoice_match
GROUP BY supplier_id
HAVING COUNT(*) >= 10  -- Filter to users with at least 10 invoices for meaningful comparison
--ORDER BY missing_rate_pct DESC
)
SELECT 
    supplier_id,
    total_invoices,
    missing_invoices,
    matched_invoices,
    missing_rate_pct,
    match_rate_pct,
    -- Total summary row
    SUM(total_invoices) OVER () AS grand_total_invoices,
    SUM(missing_invoices) OVER () AS grand_total_missing,
    SUM(matched_invoices) OVER () AS grand_total_matched,
    ROUND(SUM(missing_invoices) OVER () * 100.0 / SUM(total_invoices) OVER (), 2) AS overall_missing_rate_pct
FROM supplier_summary
ORDER BY missing_rate_pct DESC;
