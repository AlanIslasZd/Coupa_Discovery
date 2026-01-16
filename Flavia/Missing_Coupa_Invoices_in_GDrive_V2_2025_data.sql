WITH rates_raw AS (
    SELECT
        TO_CURRENCY_ID,
        RATE,
        DATE_TRUNC('month', DATE(CREATED_AT)) as RATE_MONTH,
        ROW_NUMBER() OVER (
            PARTITION BY TO_CURRENCY_ID, DATE_TRUNC('month', DATE(CREATED_AT))
            ORDER BY CREATED_AT DESC
        ) AS rn
    FROM CLEANSED.COUPA.COUPA_EXCHANGE_RATE_BCV
    WHERE FROM_CURRENCY_ID = 1 
      AND DATE(CREATED_AT) >= '2024-01-01' 
),

monthly_rates AS (
    SELECT
        TO_CURRENCY_ID,
        RATE,
        RATE_MONTH
    FROM rates_raw
    WHERE rn = 1
),

-- logic from 05_supplier_id_audit.sql.sql to safely deduplicate Sandbox data
deduped_sandbox AS (
    SELECT *
    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY INVOICE__, SUPPLIER, TOTAL_USD 
                ORDER BY (SELECT NULL) 
            ) as rn_sandbox
        FROM _sandbox_working_capital.working_capital.wc_ap_zdp
        WHERE payment_date > '2024-12-31'
    )
    WHERE rn_sandbox = 1
),

-- logic from wc_ap_coupa_v3.sql to safely deduplicate Coupa Header data
-- Modified to join with COUPA_CURRENCY_BCV to retrieve Code
deduped_coupa AS (
    SELECT h.*, curr.CODE
    FROM (
        SELECT 
            *,
            ROW_NUMBER() OVER (
                PARTITION BY INVOICE_NUMBER 
                ORDER BY GROSS_TOTAL DESC
            ) as rn_coupa
        FROM CLEANSED.COUPA.COUPA_INVOICE_HEADER_BCV
        WHERE PAYMENT_DATE BETWEEN '2025-01-01' AND '2025-12-31'
          AND document_type = 'Invoice'
          AND status != 'Voided'
    ) h
    LEFT JOIN CLEANSED.COUPA.COUPA_CURRENCY_BCV curr
        ON h.CURRENCY_ID = curr.ID
    WHERE h.rn_coupa = 1
)

SELECT 
    a.invoice_number as coupa_invoice_number,
    a.CODE as coupa_currency_code, -- Switched from currency_id to Code
    c.name as coupa_Vendor_name,
    c.number as coupa_supplier_number,
    date(a.payment_date) as coupa_payment_date,
    ROUND(a.GROSS_TOTAL / COALESCE(r.RATE, 1), 2) as coupa_total_usd,
    b.invoice__ as wc_sandbox_invoice_number,
    b.supplier as wc_sandbox_vendor_name,
    b.supplier__ as wc_sandbox_supplier_number,
    b.payment_date as wc_sandbox_payment_date,
    b.total_usd as wc_Sandbox_total_usd
FROM deduped_coupa a
LEFT JOIN deduped_sandbox b
    ON a.INVOICE_NUMBER = b.invoice__
LEFT JOIN cleansed.coupa.coupa_supplier_bcv c
    ON a.supplier_id = c.id
LEFT JOIN monthly_rates r
    ON a.CURRENCY_ID = r.TO_CURRENCY_ID
    AND DATE_TRUNC('month', DATE(a.PAYMENT_DATE)) = r.RATE_MONTH
ORDER BY a.payment_date ASC;
