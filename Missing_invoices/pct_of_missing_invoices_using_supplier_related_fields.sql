WITH invoice_indicator AS (
    SELECT 
        B.shipping_term_id, 
        CASE 
            WHEN C.INVOICE__ IS NOT NULL THEN 'BOTH'
            ELSE 'COUPA ONLY'
        END AS missing_invoice_indicator,
        COUNT(1) AS count
    FROM 
        CLEANSED.COUPA.COUPA_INVOICE_HEADER_BCV A
    JOIN
        CLEANSED.COUPA.coupa_supplier_bcv B
        ON A.SUPPLIER_ID = B.ID
    LEFT JOIN _sandbox_working_capital.working_capital_uploads.wc_ap_zdp_december C
        ON A.INVOICE_NUMBER = C.INVOICE__
    WHERE DATE(A.PAYMENT_DATE) BETWEEN '2025-12-01' AND '2025-12-31'
    GROUP BY 1, 2
)

SELECT 
    shipping_term_id,
    COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'BOTH' THEN count END), 0) AS both_count,
    COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'COUPA ONLY' THEN count END), 0) AS coupa_only_count,
    SUM(count) AS total_count,
    ROUND(COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'BOTH' THEN count END), 0) * 100.0 / SUM(count), 2) AS both_pct,
    ROUND(COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'COUPA ONLY' THEN count END), 0) * 100.0 / SUM(count), 2) AS coupa_only_pct
FROM invoice_indicator
GROUP BY shipping_term_id
ORDER BY total_count DESC;
