WITH t1 as (
SELECT 
        *,
        -- We partition by the 5 values you identified to catch exact duplicates
        ROW_NUMBER() OVER (
            PARTITION BY INVOICE__, SUPPLIER-- PAYMENT_DATE, REQUESTER, TOTAL_USD, INVOICE_DATE
            ORDER BY (SELECT NULL) -- Keep any of the identical rows
        ) as rn
    FROM _sandbox_working_capital.working_capital.wc_ap_zdp
    where 1=1 
    and payment_date > '2024-12-31'
)
SELECT * 
FROM _sandbox_working_capital.working_capital.wc_ap_zdp 
where INVOICE__ IN (
select distinct INVOICE__ from t1 where rn >1
) 
ORDER BY 
INVOICE__, SUPPLIER, PAYMENT_DATE, REQUESTER, TOTAL_USD
