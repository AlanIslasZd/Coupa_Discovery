WITH supplier_tier AS (
    SELECT 
        B.ID AS supplier_id,
        f.value:name::STRING AS supplier_tier_value
    FROM CLEANSED.COUPA.coupa_supplier_bcv B,
    LATERAL FLATTEN(input => B.custom_fields) f
    WHERE f.key = 'supplier-tier'
),

invoice_indicator AS (
    SELECT 
        st.supplier_tier_value,
        CASE 
            WHEN C.INVOICE__ IS NOT NULL THEN 'BOTH'
            ELSE 'COUPA ONLY'
        END AS missing_invoice_indicator,
        COUNT(1) AS count
    FROM CLEANSED.COUPA.COUPA_INVOICE_HEADER_BCV A
    JOIN CLEANSED.COUPA.coupa_supplier_bcv B
        ON A.SUPPLIER_ID = B.ID
    LEFT JOIN supplier_tier st
        ON B.ID = st.supplier_id
    LEFT JOIN _sandbox_working_capital.working_capital_uploads.wc_ap_zdp_december C
        ON A.INVOICE_NUMBER = C.INVOICE__
    WHERE DATE(A.PAYMENT_DATE) BETWEEN '2025-12-01' AND '2025-12-31'
    and a.supplier_id in (
        9774
        ,6465
        ,4867
        ,8946
        ,192
        ,3651
        ,1638
        ,110
    )
    GROUP BY 1, 2
)

SELECT 
    supplier_tier_value,
    COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'BOTH' THEN count END), 0) AS both_count,
    COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'COUPA ONLY' THEN count END), 0) AS coupa_only_count,
    SUM(count) AS total_count,
    ROUND(COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'BOTH' THEN count END), 0) * 100.0 / SUM(count), 2) AS both_pct,
    ROUND(COALESCE(SUM(CASE WHEN missing_invoice_indicator = 'COUPA ONLY' THEN count END), 0) * 100.0 / SUM(count), 2) AS coupa_only_pct
FROM invoice_indicator
GROUP BY supplier_tier_value
ORDER BY total_count DESC;
