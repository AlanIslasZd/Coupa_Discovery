
WITH t1 AS (
    SELECT 
        *,
        -- RN for the 2-column partition (returns 510 rows where RN > 1)
        ROW_NUMBER() OVER (
            PARTITION BY INVOICE__, SUPPLIER
            ORDER BY (SELECT NULL)
        ) as rn_broad,
        
        -- RN for the 6-column partition (returns 410 rows where RN > 1)
        ROW_NUMBER() OVER (
            PARTITION BY INVOICE__, SUPPLIER, PAYMENT_DATE, REQUESTER, TOTAL_USD, INVOICE_DATE
            ORDER BY (SELECT NULL)
        ) as rn_strict
    FROM _sandbox_working_capital.working_capital.wc_ap_zdp
)
SELECT * FROM t1 
WHERE rn_broad > 1   -- It is a duplicate in the 510-row set
  AND rn_strict = 1  -- It is NOT a duplicate in the 410-row set
ORDER BY INVOICE__, SUPPLIER, PAYMENT_DATE, REQUESTER, TOTAL_USD;
