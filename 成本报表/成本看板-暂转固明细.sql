SELECT  a.BuGuid AS BUGUID ,
        bu.BUName AS BUName ,
        p.p_projectId ,
        p.ProjName ,
        ContractName ,
		JbrName,
        ActualZzgDate ,
        PlanZzgDate ,
		a.HtAmount AS 合同金额,
		a.BcContractAmount AS 补充合同金额, 
		a.BcContractzzgHtAmount AS 暂转固补充合同金额,
        CASE WHEN ActualZzgDate IS NOT NULL THEN '是' ELSE '否' END AS 是否已转固 ,
        CASE WHEN ISNULL(ActualZzgDate, GETDATE()) > PlanZzgDate THEN '是' ELSE '否' END AS 是否延期 ,
        CASE WHEN ISNULL(ActualZzgDate, GETDATE()) > PlanZzgDate THEN ISNULL(DATEDIFF(dd, PlanZzgDate, ISNULL(ActualZzgDate, GETDATE())), 0)ELSE 0 END AS 延期天数
FROM    data_wide_cb_contract a
        INNER JOIN dbo.data_wide_mdm_Project p ON a.SourceGUID = p.p_projectId
        INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = a.BuGuid
WHERE   a.IsZzg = 1 and  p.IsMineDisk  in (1,2,3)
--ContractName='施工总承包合同补充协议4（珠江四季花园AT1009902地块（三期）13-19栋及肉菜市场土建工程）'



-- SELECT 
-- 	a.ContractGUID
-- 	,MAX(c.ExpectBgTime) as PlanZzgDate
-- 	,MIN(ISNULL(ce.ActualBgTime,myworkflowProcessEntity.FinishDateTime) ) AS ActualZzgDate
-- from cb_ContractProj a
-- INNER JOIN cb_Contract C ON A.ContractGUID = C.ContractGUID AND C.IsNeedBg = 1 and C.IsOverallContract = 1
-- LEFT JOIN cb_ContractExtend ce ON ce.ContractGUID =c.ContractGUID
-- LEFT JOIN dbo.cb_BcContract bc ON a.ContractGUID = bc.MasterContractGUID AND bc.PricingMethod = '总价包干' AND  bc.SupType ='预算转包干'
-- LEFT JOIN myworkflowProcessEntity on bc.BcContractGUID = myworkflowProcessEntity.BusinessGUID and BusinessType = '补充合同审批'
-- GROUP BY a.ContractGUID

