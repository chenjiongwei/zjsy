/*
创建时间：2024-12-03
创建人：陈炯蔚
功能：暂转固自动刷新作业
执行实例：
EXEC dbo.usp_cb_zzg_auto_refresh
*/

-- select  * into  cb_Contract_bak20241203  from cb_Contract   
alter   PROC [dbo].[usp_cb_zzg_auto_refresh]
AS
BEGIN
    -- 查询计划系统中包含"暂转固"字眼的计划工作项获取最新的计划完成日期插入临时表
    SELECT 
        proj.p_projectId,
        proj.projname,
        CASE 
            WHEN po.PlanObjectType = 1 THEN po.PlanObjectGUID
            WHEN po.PlanObjectType = 2 THEN po.ParentGUID 
        END AS PeriodGUID, --分期GUID
        pte.TaskName,
        pte.ActualFinishTime,
        pte.FinishTime -- 计划完成日期
    INTO #tmp_zzg_plan_task
    FROM jh_PlanTaskExecute pte 
    JOIN jh_PlanVersion pv 
        ON pte.PlanVersionGUID = pv.PlanVersionGUID
    JOIN jh_PlanObject po 
        ON po.PlanObjectGUID = pv.PlanObjectGUID
    JOIN p_Project proj 
        ON proj.p_projectId = po.ProjGUID
    WHERE pte.TaskName = '确定总包确认价(暂转固)'
        AND pte.FinishTime IS NOT NULL 
        AND pte.PlanType = 1

    --查询成本系统中暂转固合同的实际转固日期为空值
    SELECT 
        proj.projname, 
        cp.ProjGUID,
        a.ContractGUID,
        a.ContractName,
        a.ContractCode,
        a.ExpectBgTime -- 计划转固日期
    INTO #tmp_zzg_contract
    FROM cb_Contract a 
    INNER JOIN cb_ContractProj cp  ON cp.ContractGUID = a.ContractGUID
    left join  p_Project proj on proj.p_projectId = cp.ProjGUID
    WHERE a.IsNeedBg = 1 
        AND a.IsOverallContract = 1 

  --更新成本系统中暂转固合同的实际转固日期
    UPDATE ce  
    SET ce.ExpectBgTime = tpt.FinishTime
    -- SELECT  tzc.ProjName,  ce.ExpectBgTime , tpt.FinishTime ,tzc.*
    FROM cb_Contract ce
    INNER JOIN #tmp_zzg_contract tzc   ON tzc.ContractGUID = ce.ContractGUID
    OUTER APPLY (
        SELECT TOP 1 
            tpt.PeriodGUID projguid,  tpt.ProjName,
            FinishTime 
        FROM #tmp_zzg_plan_task tpt 
        WHERE tpt.PeriodGUID = tzc.ProjGUID 
        ORDER BY tpt.FinishTime DESC
    ) tpt
    WHERE tzc.ExpectBgTime IS  not  NULL and  datediff(day,ce.ExpectBgTime , tpt.FinishTime ) <>0 

    --删除临时表
    DROP TABLE #tmp_zzg_plan_task
    DROP TABLE #tmp_zzg_contract
END



-- SELECT  a.BuGuid AS BUGUID ,
--         bu.BUName AS BUName ,
--         p.p_projectId ,
--         p.ProjName ,
--         ContractName ,
-- 		JbrName,
--         ActualZzgDate ,
--         PlanZzgDate ,
-- 		a.HtAmount AS 合同金额,
-- 		a.BcContractAmount AS 补充合同金额, 
-- 		a.BcContractzzgHtAmount AS 暂转固补充合同金额,
--         CASE WHEN ActualZzgDate IS NOT NULL THEN '是' ELSE '否' END AS 是否已转固 ,
--         CASE WHEN ISNULL(ActualZzgDate, GETDATE()) > PlanZzgDate THEN '是' ELSE '否' END AS 是否延期 ,
--         CASE WHEN ISNULL(ActualZzgDate, GETDATE()) > PlanZzgDate THEN ISNULL(DATEDIFF(dd, PlanZzgDate, ISNULL(ActualZzgDate, GETDATE())), 0)ELSE 0 END AS 延期天数
-- FROM    data_wide_cb_contract a
--         INNER JOIN dbo.data_wide_mdm_Project p ON a.SourceGUID = p.p_projectId
--         INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = a.BuGuid
-- WHERE   a.IsZzg = 1 and  p.IsMineDisk  in (1,2,3)
-- --ContractName='施工总承包合同补充协议4（珠江四季花园AT1009902地块（三期）13-19栋及肉菜市场土建工程）'


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


-- SELECT a.ContractGUID,
--        a.HtTypeGUID,
--        b.HtTypeFullCode,
--        b.HtTypeName,
--        CASE
--            WHEN b.ParentHtTypeGUID = '00000000-0000-0000-0000-000000000000' THEN
--                b.HtTypeFullCode
--            ELSE
--                c.HtTypeFullCode
--        END AS BigHtTypeFullCode,
--        CASE
--            WHEN b.ParentHtTypeGUID = '00000000-0000-0000-0000-000000000000' THEN
--                b.HtTypeName
--            ELSE
--                c.HtTypeName
--        END AS BigHtTypeName,
--        a.ContractCode,
--        a.ContractName,
--        a.SignDate,
--        a.YfProviderGUID,
--        a.YfProviderName,
--        a.JfProviderGUID,
--        a.JfProviderName,
-- 	   a.BfProviderGUIDs,
-- 	   a.BfProviderNames,
-- 	   a.CreatedTime,
--        a.ItemAmount,
-- 	   case when a.IsNeedBg = 1 and a.IsOverallContract = 1 then 1 else 0 end as IsZzg,
--        a.BxLimit,
--        a.JbrName,
--        a.ApproveStateEnum,
--        a.ApproveState,
--        CONVERT(DECIMAL(18, 4), ROUND(a.TotalAmount * a.Rate, 4)) AS TotalAmount,
--        a.HtAmount,
--        a.HtAmount_NonTax AS HtAmountNonTax,
-- 	   a.BjcbAmount,
-- 	   a.PerformBail,
-- 	   a.EndDate as ContractCompletionDate,
-- 	   a.ApproveDate,
--        a.ProjGUID,
--        a.BuGuid,
--        a.SourceTypeEnum,
--        a.SourceType,
--        a.SourceGUID,
--        a.ProjectCostOwnerGUIDs,
--        a.ProjectCostOwnerNames,
--        CASE
--            WHEN t.CostOwnerCnt = 0 THEN
--                NULL
--            WHEN t.CostOwnerCnt = 1 THEN
--                0
--            ELSE
--                1
--        END AS IsMutilCostOwner,
--        --a.BcContractAmountNotTo AS BcContractAmount,
--        --a.BcContractAmountNotToNonTax AS BcContractAmountNonTax,
-- 	   ISNULL(bc.HtAmount,0)  AS  BcContractAmount,
-- 	   ISNULL(bc.HtAmount_NonTax,0) AS BcContractAmountNonTax,
-- 	   ISNULL(bc.zzgHtAmount,0)  AS   BcContractzzgHtAmount, --暂转固补充协议金额
-- 	   ISNULL(bc.zzgHtAmount_NonTax,0) AS BcContractzzgHtAmount_NonTax,
--        a.SubContractAmount,
--        a.SubContractAmountNonTax,
--        a.AdjustAmount,
--        a.AdjustAmount_NonTax AS AdjustAmountNonTax,
--        a.JsStateEnum,
--        a.JsState,
--        CONVERT(DECIMAL(18, 4), ROUND(ISNULL(a.TotalApproveOutputValue_Bz, 0) * a.Rate, 4)) AS TotalApproveOutputValue,
--        CONVERT(
--                   DECIMAL(18, 4),
--                   ROUND(
--                            ((ISNULL(a.TotalApproveOutputValue_Bz, 0) * ISNULL(a.TotalProgressPayRate, 0) * 0.01
--                              - ISNULL(a.TotalProgressDeduct_Bz, 0)
--                             ) * a.Rate
--                            ),
--                            4
--                        )
--               ) AS TotalProgressPayAmount,
--        b.IsEngineeringType,
--        CASE
--            WHEN a.JsStateEnum <> 3 THEN
--                ISNULL(a.BxAmount,0)
--            ELSE
--                ISNULL(e.BxAmount,0)
--        END AS BxAmount,
--        CASE
--            WHEN a.JsStateEnum <> 3 THEN
--                     ISNULL(a.BxAmount,0)- ISNULL(d.TotalFkBxDeductAmount,0)
--            ELSE
--               ISNULL(e.BxAmount,0) - ISNULL(d.TotalFkBxDeductAmount,0)
--        END AS BalanceBxAmount,
--        ISNULL(d.TotalFkBxDeductAmount,0) AS DeductBxAmount,
-- 	   a.TotalDeductAmount_Bz as TotalDeductAmount,
-- 	   a.TotalDeductedAmount_Bz as TotalDeductedAmount
-- FROM dbo.cb_Contract a
--     LEFT JOIN dbo.cb_HtType b  ON a.HtTypeGUID = b.HtTypeGUID
-- 	LEFT JOIN  (
-- 			   SELECT MasterContractGUID,
-- 			   SUM(ISNULL(HtAmount, 0)) AS HtAmount,
-- 			   SUM(ISNULL(HtAmount_NonTax, 0)) AS HtAmount_NonTax,
-- 			   SUM(CASE WHEN   SupType= '预算转包干' THEN  ISNULL(HtAmount,0 ) ELSE  0 END ) AS zzgHtAmount,
-- 			   SUM(CASE WHEN   SupType= '预算转包干' THEN  ISNULL(HtAmount_NonTax,0 ) ELSE  0 END ) AS zzgHtAmount_NonTax
-- 		FROM cb_BcContract
-- 		WHERE ApproveState = '已审核' 
-- 		GROUP BY MasterContractGUID
-- 	) bc ON bc.MasterContractGUID =a.ContractGUID
--     LEFT JOIN dbo.cb_HtType c
--         ON b.BUGUID = c.BUGUID
--            AND c.HtTypeFullCode = SUBSTRING(b.HtTypeFullCode, 0, CHARINDEX('.', b.HtTypeFullCode))
--     LEFT JOIN dbo.cb_ContractExtend d
--         ON d.ContractGUID = a.ContractGUID
--     LEFT JOIN dbo.cb_HTBalance e
--         ON e.ContractGUID = a.ContractGUID
--            AND e.BalanceTypeEnum <> 1
--     OUTER APPLY
-- (
--     SELECT COUNT(1) AS CostOwnerCnt
--     FROM dbo.cb_ContractProj p
--     WHERE p.ContractGUID = a.ContractGUID
-- ) t



-- select
-- pte.PlanTaskExecuteGUID,
-- pte.TaskName,
-- pte.TaskTypeGUID,
-- pte.TaskTypeName,
-- pte.TaskAttribute,
-- pte.StartTime,
-- pte.FinishTime,
-- pte.Duration,
-- pte.Remark,
-- pte.RowNumber,
-- pte.ParentGUID,
-- pte.Code,
-- pte.ParentCode,
-- pte.LevelCode,
-- pte.Level,
-- pte.IsEnd,
-- pte.TaskState,
-- case when pte.TaskState=0 then '未开始'
-- 	 when pte.TaskState=10 then '进行中'
-- 	 when pte.TaskState=11 then '延期'
-- 	 when pte.TaskState=20 then '按期完成'
-- 	 when pte.TaskState=21 then '延期完成'
-- 	 else '' end as TaskStateName,
-- pte.DisplayState,
-- pte.DisplayStateName,
-- pte.CompleteRate,
-- pte.ActualStartTime,
-- pte.ActualFinishTime,
-- pte.ExpectedFinishDate,
-- pte.CompleteDescription,
-- pte.ActualDuration,
-- pv.PlanVersionGUID,
-- pv.PlanName,
-- pv.PlanFullName,
-- pv.PlanDesc,
-- pv.PlanType,
-- po.PlanObjectGUID,
-- po.PlanObjectName,
-- po.PlanObjectFullName,
-- po.PlanObjectDescription,
-- po.PlanObjectType,
-- po.PlanObjectState,
-- po.HierarchyCode,
-- po.MDMID,
-- proj.p_projectId as ProjGUID,
-- proj.ProjShortName as ProjectName,
-- pte.ApprovalRoleNames,
-- pte.DutyUserGUID,
-- pte.DutyUserName,
-- pte.ReportUserGUID,
-- pte.ReportUserName,
-- pte.ParticipantUserNames,
-- pte.TaskAchievementGUIDs,
-- pte.BuildingGUIDs,
-- pte.BuildingNames,
-- pte.LastReportGUID as TaskReportGUID,
-- pte.StandardTaskGUID,
-- pte.IsStop,
-- pte.KeyNodeTaskExecuteGUID,
-- case when po.PlanObjectType=1 then po.PlanObjectGUID
--      when po.PlanObjectType=2 then po.ParentGUID end as PeriodGUID 
-- from jh_PlanTaskExecute pte 
-- join jh_PlanVersion pv on pte.PlanVersionGUID=pv.PlanVersionGUID
-- join jh_PlanObject po on po.PlanObjectGUID=pv.PlanObjectGUID
-- join p_Project proj on proj.p_projectId=po.ProjGUID