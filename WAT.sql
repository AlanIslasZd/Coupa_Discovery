--WAT

SELECT
    -- Add supplier, region, or period if you want to group!
    SUM(
        COALESCE(cih.amount_due, 0) 
        * COALESCE(CAST(cpt.DAYS_FOR_NET_PAYMENT AS FLOAT), 0)
        * COALESCE(cer.RATE, 1)
    ) / NULLIF(SUM(
        COALESCE(cih.amount_due, 0) * COALESCE(cer.RATE, 1)
    ), 0) AS wat
FROM
    COUPA_INVOICE_HEADER_BCV cih
LEFT JOIN coupa_payment_term_bcv cpt
    ON cih.payment_term_id = cpt.id
LEFT JOIN coupa_exchange_rate_bcv cer
    ON cih.currency_id = cer.currency_id
WHERE
    cih.status = 'APPROVED'  -- Or your filter for valid/active invoices
    AND cih.amount_due > 0
;