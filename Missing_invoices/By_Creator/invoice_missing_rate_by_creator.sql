WITH invoice_match AS (
    SELECT 
        a.invoice_number, 
        a.created_by_id,
        b.invoice__,
        CASE WHEN b.invoice__ IS NULL AND a.invoice_number IS NOT NULL THEN 1 ELSE 0 END AS missing_invoice_indicator
    FROM cleansed.coupa.coupa_invoice_header_bcv a
    LEFT JOIN _sandbox_working_capital.working_capital.wc_ap_zdp b
        ON a.invoice_number = b.invoice__
    WHERE 1=1
      and date(a.payment_date) between '2025-09-01' and '2025-12-31'
      AND a.PAID = true
)

SELECT 
    created_by_id,
    COUNT(*) AS total_invoices,
    SUM(missing_invoice_indicator) AS missing_invoices,
    COUNT(*) - SUM(missing_invoice_indicator) AS matched_invoices,
    ROUND(SUM(missing_invoice_indicator) * 100.0 / COUNT(*), 2) AS missing_rate_pct,
    ROUND((COUNT(*) - SUM(missing_invoice_indicator)) * 100.0 / COUNT(*), 2) AS match_rate_pct
FROM invoice_match
GROUP BY created_by_id
HAVING COUNT(*) >= 10  -- Filter to users with at least 10 invoices for meaningful comparison
ORDER BY missing_rate_pct DESC;
