

SELECT 
    fi.FeeItemName AS 款项名称,
    SUM(ti.Amount) AS 本周发票金额
FROM TaxInvoice ti
INNER JOIN FeeItem fi ON ti.FeeItemGUID = fi.FeeItemGUID
--WHERE ti.CreateTime >= DATEADD(wk, DATEDIFF(wk, 0, GETDATE()), 0)  -- 本周一
--AND ti.CreateTime < DATEADD(wk, DATEDIFF(wk, 0, GETDATE()) + 1, 0) -- 下周一
GROUP BY fi.FeeItemName
ORDER BY SUM(ti.Amount) DESC