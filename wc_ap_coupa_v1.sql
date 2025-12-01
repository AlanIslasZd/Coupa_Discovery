USE DATABASE CLEANSED;
USE SCHEMA COUPA;
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
        CIH.ID,
        CIH.INVOICE_NUMBER,
        CIH.PAYMENT_DATE,
        CIH.GROSS_TOTAL,
        CIH.CURRENCY_ID,
        CIH.SUPPLIER_ID,
        CIH.PAYMENT_TERM_ID,
        CIH.ACCOUNT_TYPE_ID,
        DATE(CIH.INVOICE_DATE) AS INVOICE_DATE,
        DATE(CIH.NET_DUE_DATE) AS NET_DUE_DATE, 
        DATE(CIH.DATE_RECEIVED)  AS INVOICE_RECEIVED_DATE,
        DATE(CIH.CREATED_AT)  AS CREATED_DATE,
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
),
invoice_data AS (
    SELECT 
        ID,
        INVOICE_NUMBER,
        PAYMENT_DATE,
        GROSS_TOTAL,
        CURRENCY_ID,
        SUPPLIER_ID,
        PAYMENT_TERM_ID,
        ACCOUNT_TYPE_ID,
        INVOICE_DATE,
        NET_DUE_DATE,
        INVOICE_RECEIVED_DATE,
        CREATED_DATE
    FROM invoice_data_raw
    WHERE rn = 1
    and SUPPLIER_ID IS NOT NULL
),
supplier_data as (
    SELECT
        ID,
        NAME AS VENDOR_NAME
        --COA is missing
        --- vendor payment term should come from paymet term id... is not this redundant with payment terms including on invoices?
    FROM COUPA_SUPPLIER_INFORMATION_BCV
),
Supplier_Location AS (
    SELECT 
        csia.ID,
        ccb.NAME AS COUNTRY
    FROM COUPA_SUPPLIER_INFORMATION_ADDRESS_BCV csia
    LEFT JOIN COUPA_COUNTRY_BCV ccb ON csia.COUNTRY_ID = ccb.ID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY csia.ID ORDER BY csia.ID) = 1
),
payment_terms_data as (
    SELECT
        ID,
        CODE AS PAYMENT_TERMS
    FROM COUPA_PAYMENT_TERM_BCV
),
account_type_data as (
    SELECT
        ID,
        NAME AS ACCOUNT_TYPE_NAME
    FROM COUPA_ACCOUNT_TYPE_BCV
),
po_data AS (
    SELECT
        il.invoice_header_id,
        LISTAGG(DISTINCT oh.po_number, ', ') WITHIN GROUP (ORDER BY oh.po_number) AS PO_NUMBER
    FROM COUPA_INVOICE_LINE_BCV il
    LEFT JOIN COUPA_ORDER_LINE_BCV ol ON ol.id = il.order_line_id
    LEFT JOIN COUPA_ORDER_HEADER_BCV oh ON oh.id = ol.order_header_id
    WHERE oh.po_number IS NOT NULL
    GROUP BY il.invoice_header_id
),
joined_data AS (
    SELECT 
        I.PAYMENT_DATE,
        I.INVOICE_NUMBER,
        I.GROSS_TOTAL,
        I.INVOICE_DATE,
        I.NET_DUE_DATE,
        I.INVOICE_RECEIVED_DATE,
        I.CREATED_DATE,
        COALESCE(R.RATE, 1) AS RATE,
        C.CODE,
        supp.VENDOR_NAME,
        sl.COUNTRY,
        pt.PAYMENT_TERMS,
        at.ACCOUNT_TYPE_NAME,
        pd.PO_NUMBER
    FROM invoice_data I
    LEFT JOIN october_rates R
        ON I.CURRENCY_ID = R.TO_CURRENCY_ID
    LEFT JOIN COUPA_CURRENCY_BCV AS c ON I.CURRENCY_ID = c.ID
    LEFT JOIN supplier_data supp ON I.SUPPLIER_ID = supp.ID
    LEFT JOIN Supplier_Location sl ON I.SUPPLIER_ID = sl.ID
    LEFT JOIN payment_terms_data pt ON I.payment_term_id = pt.ID
    LEFT JOIN account_type_data at ON I.ACCOUNT_TYPE_ID = at.ID
    LEFT JOIN po_data pd ON I.ID = pd.invoice_header_id

), final_data AS (
SELECT 
    PAYMENT_DATE,
    INVOICE_NUMBER,
    PO_NUMBER,
    GROSS_TOTAL,
    INVOICE_DATE,
    NET_DUE_DATE,
    INVOICE_RECEIVED_DATE,
    CREATED_DATE,
    RATE,
    CODE,
    VENDOR_NAME,
    COUNTRY,
    PAYMENT_TERMS,
    ACCOUNT_TYPE_NAME,
    CASE 
        WHEN ACCOUNT_TYPE_NAME IN ('Zendesk United States', 'Zendesk Canada', 'Zendesk Foundation') THEN 'AMER'
        WHEN ACCOUNT_TYPE_NAME IN ('Zendesk Denmark (MB)', 'Zendesk Ireland (MB)', 'Zendesk United Kingdom (MB)', 'Zendesk France (USD)', 'Zendesk Germany (MB)', 'Base Poland', 'Zendesk Portugal', 'Zendesk Spain', 'Zendesk Netherlands (MB)') THEN 'EMEA'
        WHEN ACCOUNT_TYPE_NAME IN ('Zendesk Philippines (MB)', 'Zendesk Australia (MB)', 'Zendesk Singapore (MB)', 'Zendesk India (MB)', 'Zendesk Japan (MB)', 'Zendesk Korea') THEN 'APAC'
        WHEN ACCOUNT_TYPE_NAME IN ('Zendesk Brazil (MB)', 'Zendesk Mexico') THEN 'LATAM'
        ELSE ''
    END AS REGION,
    CASE 
        WHEN PAYMENT_TERMS IN ('Due Upon Receipt', 'Coupa PAY') THEN 0 
        ELSE TRY_TO_NUMBER(RIGHT(PAYMENT_TERMS, 2)) 
    END AS PAYMENT_TERM_DAYS,
    ROUND(GROSS_TOTAL / RATE) AS TOTAL_USD,
    DATEDIFF(day, INVOICE_DATE, NET_DUE_DATE) * (GROSS_TOTAL / RATE) AS WAT,
    DATEDIFF(day, INVOICE_DATE, PAYMENT_DATE) * (GROSS_TOTAL / RATE) AS WADTP,
    CASE WHEN NET_DUE_DATE = PAYMENT_DATE THEN ROUND(GROSS_TOTAL / RATE) ELSE 0 END AS AMOUNT_PAID_ON_NET_DUE_DATE,
    CASE WHEN NET_DUE_DATE < PAYMENT_DATE THEN ROUND(GROSS_TOTAL / RATE) ELSE 0 END AS AMOUNT_PAID_AFTER_NET_DUE_DATE,
    CASE WHEN NET_DUE_DATE > PAYMENT_DATE THEN ROUND(GROSS_TOTAL / RATE) ELSE 0 END AS AMOUNT_PAID_BEFORE_NET_DUE_DATE,
    CASE WHEN DATEDIFF(day, NET_DUE_DATE, PAYMENT_DATE) BETWEEN -7 AND 7 THEN ROUND(GROSS_TOTAL / RATE) ELSE 0 END AS AMOUNT_PAID_ON_TIME,
    CASE WHEN DATEDIFF(day, NET_DUE_DATE, PAYMENT_DATE) > 7 THEN ROUND(GROSS_TOTAL / RATE) ELSE 0 END AS AMOUNT_PAID_LATE,
    CASE WHEN DATEDIFF(day, NET_DUE_DATE, PAYMENT_DATE) < -7 THEN ROUND(GROSS_TOTAL / RATE) ELSE 0 END AS AMOUNT_PAID_7_PLUS_DAYS_EARLY
FROM joined_data
WHERE INVOICE_NUMBER IS NOT NULL
)
select 
sum(TOTAL_USD)/1000000 as amount_due_usd_october
from final_data
--WHERE VENDOR_NAME IS NOT NULL;