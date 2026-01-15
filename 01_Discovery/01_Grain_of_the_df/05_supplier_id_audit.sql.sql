WITH t1 as (
SELECT 
        *,
        -- We partition by the 5 values you identified to catch exact duplicates
        ROW_NUMBER() OVER (
            PARTITION BY INVOICE__, SUPPLIER, PAYMENT_DATE, REQUESTER, TOTAL_USD 
            ORDER BY (SELECT NULL) -- Keep any of the identical rows
        ) as rn
    FROM _sandbox_working_capital.working_capital.wc_ap_zdp
)
SELECT * 
FROM t1 
where RN > 1
ORDER BY 
INVOICE__, SUPPLIER, PAYMENT_DATE, REQUESTER, TOTAL_USD
