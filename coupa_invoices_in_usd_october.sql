WITH october_rates_raw AS (
    SELECT
        ID,
        FROM_CURRENCY_ID,
        TO_CURRENCY_ID,
        RATE,
        CREATED_AT,
        ROW_NUMBER() OVER (
            PARTITION BY TO_CURRENCY_ID
            ORDER BY CREATED_AT DESC
        ) AS rn
    FROM COUPA_EXCHANGE_RATE_BCV
    WHERE FROM_CURRENCY_ID = 1
      AND DATE(CREATED_AT) BETWEEN '2025-10-01' AND '2025-10-31'
      
),
october_rates AS (
    SELECT
        ID,
        FROM_CURRENCY_ID,
        TO_CURRENCY_ID,
        RATE,
        CREATED_AT
    FROM october_rates_raw
    WHERE rn = 1
),
invoice_data_raw AS (
    SELECT
        CIH.INVOICE_NUMBER,
        CIH.PAYMENT_DATE,
        CIH.GROSS_TOTAL,
        CIH.CURRENCY_ID,
        ROW_NUMBER() OVER (
            PARTITION BY CIH.INVOICE_NUMBER
            ORDER BY CIH.GROSS_TOTAL DESC
        ) AS rn
    FROM COUPA_INVOICE_HEADER_BCV CIH
    --LEFT JOIN COUPA_INVOICE_LINE_BCV CIL
    --    ON CIL.INVOICE_HEADER_ID = CIH.ID
    WHERE CIH.PAYMENT_DATE BETWEEN '2025-10-01' AND '2025-10-31'
      AND CIH.STATUS != 'Voided'
      AND CIH.NET_DUE_DATE >= CIH.INVOICE_DATE
      AND DATEDIFF(day, CIH.INVOICE_DATE, CIH.NET_DUE_DATE) <= 365
      AND CIH.PAYMENT_DATE >= CIH.INVOICE_DATE
      AND DATEDIFF(day, CIH.INVOICE_DATE, CIH.PAYMENT_DATE) <= 365
      AND CIH.GROSS_TOTAL >= 0
      AND CIH.CURRENCY_ID != 144
      --AND CIH.INVOICE_NUMBER = '150'
),
invoice_data AS (
    SELECT 
        INVOICE_NUMBER,
        PAYMENT_DATE,
        GROSS_TOTAL,
        CURRENCY_ID
    FROM invoice_data_raw
    WHERE rn = 1
),
joined_data AS (
    SELECT 
        I.PAYMENT_DATE,
        I.INVOICE_NUMBER,
        I.GROSS_TOTAL,
        COALESCE(R.RATE, 1) AS RATE
    FROM invoice_data I
    LEFT JOIN october_rates R
        ON I.CURRENCY_ID = R.TO_CURRENCY_ID
)
SELECT 
    DATE(PAYMENT_DATE),
    COUNT(DISTINCT INVOICE_NUMBER) AS unique_invoice_numbers,
    COUNT(*) AS total_invoices,
    ROUND(SUM(GROSS_TOTAL / RATE))/1000000 AS amount_due_usd
FROM joined_data
GROUP BY 1
ORDER BY 1