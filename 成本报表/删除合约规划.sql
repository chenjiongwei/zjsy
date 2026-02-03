
-- 备份数据表
SELECT * INTO cb_BudgetWorking_del_bak20250417 
FROM cb_BudgetWorking 
WHERE ProjectGUID = 'ee00b522-bc34-4ec0-3645-08dbf50c1ef2';

SELECT * INTO cb_Budget_del_bak20250417 
FROM dbo.cb_Budget 
WHERE ProjGUID = 'ee00b522-bc34-4ec0-3645-08dbf50c1ef2';

SELECT * INTO cb_CostContractWorking_del_bak20250417
FROM cb_CostContractWorking 
WHERE ProjGUID = 'ee00b522-bc34-4ec0-3645-08dbf50c1ef2' 
  AND SourceGuid = '51AFB0C6-F9F9-4A56-555C-08DD5CF1F5BB';



-- 删除数据表
DELETE FROM cb_CostContractWorking 
WHERE ProjGUID = 'ee00b522-bc34-4ec0-3645-08dbf50c1ef2' 
  AND SourceGuid = '51AFB0C6-F9F9-4A56-555C-08DD5CF1F5BB';

DELETE FROM cb_BudgetWorking 
WHERE ProjectGUID = 'ee00b522-bc34-4ec0-3645-08dbf50c1ef2' 
  AND BudgetWorkingGUID = '51AFB0C6-F9F9-4A56-555C-08DD5CF1F5BB';

DELETE FROM dbo.cb_Budget 
WHERE ProjGUID = 'ee00b522-bc34-4ec0-3645-08dbf50c1ef2' 
  AND BudgetGUID = '51AFB0C6-F9F9-4A56-555C-08DD5CF1F5BB';

-- 删除合约规划审批
SELECT  * INTO cb_BudgetBill_del_bak20250417  
FROM  cb_BudgetBill WHERE  ProjectGUID ='ee00b522-bc34-4ec0-3645-08dbf50c1ef2'

DELETE
FROM　cb_BudgetBill 
WHERE   ProjectGUID ='ee00b522-bc34-4ec0-3645-08dbf50c1ef2'


-- https://project.gzprg.com:1979/std/02010204/92e43c8a-3468-e611-9be8-7427eac25eb4?mode=2&autoTitle=true&_mp=blank&_hid=02010204&_t=1744862567524&_tFields=BUGUID%2CPROJGUID&oid=51afb0c6-f9f9-4a56-555c-08dd5cf1f5bb&title=%E5%90%88%E7%BA%A6%E8%A7%84%E5%88%92&BUGUID=ea5cf66a-6d53-4b73-73d2-08dd1d4b85d4&ProjGUID=ee00b522-bc34-4ec0-3645-08dbf50c1ef2&__BUGUID__=ea5cf66a-6d53-4b73-73d2-08dd1d4b85d4