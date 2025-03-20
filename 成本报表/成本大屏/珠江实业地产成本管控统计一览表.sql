--EXEC usp_kb_CostMangerAnalysis
USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_kb_CostMangerAnalysis]    Script Date: 2025/3/20 16:23:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_kb_CostMangerAnalysis]
/*
功能：珠江实业地产成本管控统计一览表
create by  chenjw  2023-09-06
usp_kb_CostMangerAnalysis 
*/
AS
    BEGIN
        --考核项目插入到临时表
        SELECT  p.BUGUID ,
                bu.BUName ,
                p_projectId ,
                ProjName ,
                ProjCode ,
                p.ParentGUID
        INTO    #ExamProj
        FROM    dbo.data_wide_mdm_Project p
                INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = p.BUGUID
        WHERE   p.IsMineDisk in ( 1,2,3)  AND p.Level = 3;

        --月度考核评分表
        SELECT  ProjGUID ,
                SUM(ISNULL(Total, 0)) AS Total ,
                SUM(ISNULL(Deduct, 0)) AS Deduct ,
                SUM(ISNULL(Point, 0)) AS Point
        INTO    #examine
        FROM    data_wide_dws_cb_examine a
        GROUP BY ProjGUID;

        --/////////////////////////////////目标成本与项目计划节点匹配情况////////////////////////////
        /*
			处理逻辑
			成本系统版本	主项计划版本	一致	匹配			
			成本系统版本	主项计划版本	差一个版本	根据时间（主项计划时间+期限） > 当前时间比 			匹配
			成本系统版本	主项计划版本	差两个版本	不匹配			
			*/
        WITH dtl AS (
                SELECT bu.BUName ,
                    p.BUGUID ,
                    p.ProjName ,
                    p.p_projectId ,
                    VersionName AS 当前目标成本版本 ,
                    CONVERT(VARCHAR(10), t.ApproveDate, 121) AS 当前目标成本版本审核日期 ,
                    CASE WHEN 装修版节点审核日期 IS NOT NULL THEN '大货区装修施工图出图'
                         ELSE CASE WHEN 施工图版节点审核日期 IS NOT NULL THEN '全套施工图出图（封板图）'
                         ELSE CASE WHEN 启动版节点审核日期 IS NOT NULL THEN '目标成本评审会（启动版）' 
                         ELSE CASE WHEN 可研版节点审核日期 IS NOT NULL THEN '投资专业评审会（可研报告）' 
                         ELSE '未审核项目主项计划' END END
                        END
                    END AS 当前项目进度,
                    CASE WHEN VersionName = '可研版' THEN 1
                         WHEN VersionName = '启动版' THEN 2
                         WHEN VersionName = '施工图版' THEN 3
                         WHEN VersionName = '装修版' THEN 4
                    END AS 目标成本版本,
                    --CASE WHEN VersionName = '可研版' AND   可研版节点审核日期 IS NOT NULL THEN '匹配'
                    --     WHEN VersionName = '启动版' AND   启动版节点审核日期 IS NOT NULL THEN '匹配'
                    --     WHEN VersionName = '施工图版' AND  施工图版节点审核日期 IS NOT NULL THEN '匹配'
                    --     WHEN VersionName = '装修版' AND   装修版节点审核日期 IS NOT NULL THEN '匹配'
                    --     ELSE '不匹配'
                    --END AS 进度与目标成本是否匹配 ,

                    ISNULL(CONVERT(VARCHAR(10), jh.可研版节点审核日期, 121), '') AS 可研版节点审核日期 ,
                    ISNULL(CONVERT(VARCHAR(10), jh.启动版节点审核日期, 121), '') AS 启动版节点审核日期 ,
                    ISNULL(CONVERT(VARCHAR(10), jh.施工图版节点审核日期, 121), '') AS 施工图版节点审核日期 ,
                    ISNULL(CONVERT(VARCHAR(10), jh.装修版节点审核日期, 121), '') AS 装修版节点审核日期,
                    CASE 
					     WHEN ISNULL(CONVERT(VARCHAR(10), jh.装修版节点审核日期, 121), '') <> '' THEN 4
                         WHEN ISNULL(CONVERT(VARCHAR(10), jh.施工图版节点审核日期, 121), '') <> '' THEN 3
                         WHEN ISNULL(CONVERT(VARCHAR(10), jh.启动版节点审核日期, 121), '') <> '' THEN 2
                         WHEN ISNULL(CONVERT(VARCHAR(10), jh.可研版节点审核日期, 121), '') <> '' THEN 1
                    END AS 进度版本,
					case when   p.IsMineDisk =1  then  '建设中' when   p.IsMineDisk =2   then '已完工' when p.IsMineDisk =3 then  '未开始' end  as  项目进度
            FROM   data_wide_mdm_Project p
                    --查询最新版目标成本，不取调整版
            INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = p.BUGUID
            OUTER APPLY (SELECT  TOP 1   TCV.TargetCostVersionName AS VersionName ,
                                        ApproveDate
                        FROM    data_wide_cb_TargetCostStageVersion TCSV
                                INNER JOIN data_wide_cb_TargetCostVersion TCV ON TCV.TargetCostVersionGUID = TCSV.TargetCostVersionGUID
                        WHERE   TCSV.ApproveStateEnum = 3 AND   TargetCostVersionName <> '调整版' AND  TCSV.ProjectGUID = p.p_projectId
                        ORDER BY TCV.RowIndex DESC) t
            --查询当前进度系统版本
            LEFT JOIN(SELECT    a.ProjGUID ,
                                a.PlanObjectGUID ,
                                MAX(CASE WHEN a.TaskName = '投资专业评审会（可研报告）' THEN ActualFinishTime END) AS '可研版节点审核日期' ,
                                MAX(CASE WHEN a.TaskName = '目标成本评审会（启动版）' THEN ActualFinishTime END) AS '启动版节点审核日期' ,
                                DATEADD(DAY,60, MAX(CASE WHEN a.TaskName = '全套施工图出图（封板图）' THEN ActualFinishTime END) ) AS '施工图版节点审核日期' , --取工作项名称like“全套施工图出图”+60天
                                DATEADD(DAY,45, MAX(CASE WHEN a.TaskName = '大货区装修施工图出图' THEN ActualFinishTime END) ) AS '装修版节点审核日期' -- 工作项名称like“大货区装修出图”+45天
                        FROM  data_wide_jh_TaskDetail a
                        WHERE a.ApproveState = 2
                        GROUP BY a.ProjGUID ,
                                a.PlanObjectGUID) jh ON jh.PlanObjectGUID = p.p_projectId
            WHERE  p.Level = 3 --AND  p.p_projectId ='9D6B5F12-ECCF-E911-8A8E-40F2E92B3FDA'
			
			)
        SELECT  * ,
        CASE  
		WHEN  项目进度 ='已完工' THEN  '匹配'  
				     WHEN ISNULL(当前目标成本版本, '') = '' THEN '未开始'
                     WHEN 当前目标成本版本 = '方案版' THEN '不匹配'
                     WHEN ISNULL(进度版本, 0) - ISNULL(目标成本版本, 0) > 1 THEN '不匹配'
                     WHEN 进度版本 = 目标成本版本 THEN '匹配'
        WHEN ISNULL(进度版本,0) - ISNULL(目标成本版本,0) = 1
            THEN 
            CASE WHEN 当前目标成本版本 = '可研版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,5,CONVERT(DATETIME, 启动版节点审核日期)),120) >= CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '匹配'
                WHEN 当前目标成本版本 = '可研版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,5,CONVERT(DATETIME, 启动版节点审核日期)),120) < CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '不匹配'
                WHEN 当前目标成本版本 = '启动版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,60,CONVERT(DATETIME, 施工图版节点审核日期)),120) >= CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '匹配'
                WHEN 当前目标成本版本 = '启动版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,60,CONVERT(DATETIME, 施工图版节点审核日期)),120) < CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '不匹配'
                --WHEN 当前目标成本版本 = '施工图版' 
                --    AND CONVERT(VARCHAR(10),DATEADD(DAY,45,CONVERT(DATETIME, 装修版节点审核日期)),120) >= CONVERT(VARCHAR(10),GETDATE(),120)
                --THEN '匹配'
                --WHEN 当前目标成本版本 = '施工图版' 
                --    AND CONVERT(VARCHAR(10),DATEADD(DAY,45,CONVERT(DATETIME, 装修版节点审核日期)),120) < CONVERT(VARCHAR(10),GETDATE(),120)
                --THEN '不匹配'
				WHEN 当前目标成本版本 in ('施工图版','装修版') THEN  '匹配'
                         END
                WHEN ISNULL(目标成本版本, 0) - ISNULL(进度版本, 0) = 1 THEN '匹配'
		        WHEN 当前目标成本版本 in ('施工图版','装修版') THEN  '匹配'
                     WHEN 当前项目进度 = '未审核项目主项计划' THEN '无主项计划'
                END AS 进度与目标成本是否匹配
        INTO    #jdMate
        FROM    dtl;

        --/////////////////////////动态成本月度回顾/////////////////////////////////
        SELECT  p.BUGUID ,
                p.ParentGUID AS ProjGUID ,
                p.p_projectId AS 分期GUID ,
                p.ProjName AS 项目分期名称 ,
                m.MonthlyReviewGUID AS 动态成本回顾GUID ,
                m.CurVersion AS 当前动态成本回顾版本号 ,
                CASE WHEN ISNULL(x_JsfyBeyondTargetTisk, 0) <> 0 THEN '建设费用有超目标风险;' ELSE '' END + CASE WHEN ISNULL(x_GlfyBeyondTargetTisk, 0) <> 0 THEN '管理费用有超目标风险;' ELSE '' END
                + CASE WHEN ISNULL(x_CwfyBeyondTargetTisk, 0) <> 0 THEN '财务费用有超目标风险;' ELSE '' END + CASE WHEN ISNULL(x_YxfyBeyondTargetTisk, 0) <> 0 THEN '营销费用有超目标风险;' ELSE '' END AS 超目标成本风险 ,
                CASE WHEN (ISNULL(x_JsfyBeyondTargetTisk, 0) + ISNULL(x_GlfyBeyondTargetTisk, 0) + ISNULL(x_CwfyBeyondTargetTisk, 0) + ISNULL(x_YxfyBeyondTargetTisk, 0)) > 0 THEN '超风险'
                     ELSE '无风险'
                END AS 是否有超目标成本风险 ,
                ISNULL(x_JsfyBeyondTargetTisk, 0) AS 建设费用有无超目标风险 ,                  -- 建设费用有无超目标风险,
                ISNULL(x_GlfyBeyondTargetTisk, 0) AS 管理费用有无超目标风险 ,                  --管理费用有无超目标风险,
                ISNULL(x_CwfyBeyondTargetTisk, 0) AS 财务费用有无超目标风险 ,                  --财务费用有无超目标风险,
                ISNULL(x_YxfyBeyondTargetTisk, 0) AS 营销费用有无超目标风险 ,                  --营销费用有无超目标风险,
                ISNULL(x_LocaleAlterOverdueNotOnlineCount, 0) AS 截止本月签证变更未上线单据数量 ,  --截止本月签证变更未上线单据数量,
                ISNULL(x_LocaleAlterOverdueNotOnlineJe, 0) AS 截止本月签证变更未上线单据预估金额 ,   --截止本月签证变更未上线单据预估金额,
                ISNULL(x_DesignAlterOverdueNotOnlineCount, 0) AS 截止本月设计变更未上线单据数量 ,  --截止本月设计变更未上线单据数量,
                ISNULL(x_DesignAlterOverdueNotOnlineJe, 0) AS 截止本月设计变更未上线单据预估金额 ,   --截止本月设计变更未上线单据预估金额,
                ISNULL(x_DelaySignContractCount, 0) AS 延期签约合同份数 ,                   --延期签约合同份数
                ISNULL(x_MonthLocaleAlterOverdueCount, 0) AS 本月签证变更超期上线数量 ,
                ISNULL(x_MonthDesignAlterOverdueCount, 0) AS 本月设计变更超期上线数量
        INTO    #MonthlyReview
        FROM(SELECT ProjGUID ,
                    MonthlyReviewGUID ,
                    CurVersion ,
                    x_JsfyBeyondTargetTisk ,                -- 建设费用有无超目标风险,
                    x_GlfyBeyondTargetTisk ,                --管理费用有无超目标风险,
                    x_CwfyBeyondTargetTisk ,                --财务费用有无超目标风险,
                    x_YxfyBeyondTargetTisk ,                --营销费用有无超目标风险,
                    x_LocaleAlterOverdueNotOnlineCount ,    --截止本月签证变更未上线单据数量,
                    x_LocaleAlterOverdueNotOnlineJe ,       --截止本月签证变更未上线单据预估金额,
                    x_DesignAlterOverdueNotOnlineCount ,    --截止本月设计变更未上线单据数量,
                    x_DesignAlterOverdueNotOnlineJe ,       --截止本月设计变更未上线单据预估金额,
                    x_DelaySignContractCount ,              --延期签约合同份数
                    x_MonthLocaleAlterOverdueCount ,        --本月签证变更超期上线数量
                    x_MonthDesignAlterOverdueCount ,        --本月设计变更超期上线数量
                    ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) RN
             FROM   data_wide_cb_MonthlyReview
             WHERE  (1 = 1 AND  ApproveState = '已审核')) m
            INNER JOIN dbo.data_wide_mdm_Project p ON p.p_projectId = m.ProjGUID
        WHERE   m.RN = 1;

        --/////////////////////////////////已上线设计变更统计/////////////////////////////////
        --整体变更率	
        --现场签证变更率	 ,
        --设计变更变更率
        WITH #alt AS (
                     SELECT p.BUGUID AS BUGUID ,
                            bu.BUName AS 区域 ,
                            p.p_projectId ,
                            p.ParentGUID ,
                            p.ProjName AS 分期名称 ,
							alt.ContractGUID,
                            SUM(ISNULL(alt.CfAmount, 0)) AS 变更签证金额 ,
                            COUNT(DISTINCT CASE WHEN ISNULL(alt.CfAmount, 0) <> 0 THEN alt.BillCode END) AS 变更签证份数 ,
                            SUM(CASE WHEN alt.BillType IN ('现场签证', '现场签证完工确认') THEN ISNULL(alt.CfAmount, 0)END) AS 现场签证金额 ,
                            COUNT(DISTINCT CASE WHEN alt.BillType IN ('现场签证', '现场签证完工确认') AND   ISNULL(alt.CfAmount, 0) <> 0 THEN BillCode END) AS 现场签证份数 ,
                            SUM(CASE WHEN alt.BillType IN ('设计变更', '设计变更完工确认') THEN ISNULL(alt.CfAmount, 0)END) AS 设计变更金额 ,
                            COUNT(DISTINCT CASE WHEN alt.BillType IN ('设计变更', '设计变更完工确认') AND   ISNULL(alt.CfAmount, 0) <> 0 THEN BillCode END) 设计变更份数
                     FROM   data_wide_cb_budgetuse alt
                            INNER JOIN dbo.data_wide_mdm_Project p ON alt.ProjectGUID = p.p_projectId
                            INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = p.BUGUID
                     WHERE  alt.ApproveStateEnum = 3 AND alt.BillType IN ('设计变更', '设计变更完工确认', '现场签证', '现场签证完工确认')
                            AND   (alt.CostCode LIKE 'A.02.02%' OR alt.CostCode LIKE 'A.02.03%' OR alt.CostCode LIKE 'A.02.04%' OR alt.CostCode LIKE 'A.05.02%')
							--如果有完工确认的金额，要取完工确认的金额而非申报金额 
                            AND NOT EXISTS (SELECT  alt1.BillGUID
                                    FROM    data_wide_cb_budgetuse alt1
                                    WHERE   alt1.BillType IN ('设计变更完工确认', '现场签证完工确认') 
									AND  alt.AlterGUID IS NOT NULL 
									AND   alt1.ProjectGUID = alt.ProjectGUID AND  alt1.FactTableAlterGUID = alt.FactTableAlterGUID
                                            AND alt1.alterGUID = alt.BillGUID)
                     GROUP BY p.BUGUID ,
                              bu.BUName ,
                              p.p_projectId ,
                              p.ParentGUID ,
                              p.ProjName,
							  alt.ContractGUID

				) ,
            /* #ConAlt AS (
			             SELECT p.BUGUID AS BUGUID ,
                                bu.BUName AS 区域 ,
                                p.p_projectId ,
                                p.ParentGUID ,
                                p.ProjName AS 分期名称 ,
                                alt.ContractGUID ,
                                SUM(ISNULL(alt.CfAmount, 0)) AS 变更签证金额 ,
                                COUNT(DISTINCT CASE WHEN ISNULL(alt.CfAmount, 0) <> 0 THEN alt.BillCode END) AS 变更签证份数 ,
                                SUM(CASE WHEN alt.BillType IN ('现场签证', '现场签证完工确认') THEN ISNULL(alt.CfAmount, 0)END) AS 现场签证金额 ,
                                COUNT(DISTINCT CASE WHEN alt.BillType IN ('现场签证', '现场签证完工确认') AND   ISNULL(alt.CfAmount, 0) <> 0 THEN BillCode END) AS 现场签证份数 ,
                                SUM(CASE WHEN alt.BillType IN ('设计变更', '设计变更完工确认') THEN ISNULL(alt.CfAmount, 0)END) AS 设计变更金额 ,
                                COUNT(DISTINCT CASE WHEN alt.BillType IN ('设计变更', '设计变更完工确认') AND   ISNULL(alt.CfAmount, 0) <> 0 THEN BillCode END) 设计变更份数
                         FROM   data_wide_cb_budgetuse alt
                                INNER JOIN dbo.data_wide_mdm_Project p ON alt.ProjectGUID = p.p_projectId
                                INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = p.BUGUID
                         WHERE  alt.ApproveStateEnum = 3 AND alt.BillType IN ('设计变更', '设计变更完工确认', '现场签证', '现场签证完工确认')
                                AND   (alt.CostCode LIKE 'A.02.02%' OR alt.CostCode LIKE 'A.02.03%' OR alt.CostCode LIKE 'A.02.04%' OR alt.CostCode LIKE 'A.05.02%')
                         GROUP BY p.BUGUID ,
                                  bu.BUName ,
                                  p.p_projectId ,
                                  p.ParentGUID ,
                                  p.ProjName ,
                                  alt.ContractGUID) ,*/
     -- 合同金额
             #c AS (SELECT  p.BUGUID ,
                            bu.BUName AS 区域 ,
                            p.ProjName AS 分期名称 ,
                            p.p_projectId ,
                            p.ParentGUID ,
                           -- '签证变更' AS AlterClass ,
                            c.ContractGUID ,
                            SUM(ISNULL(c.CfAmount, 0)) AS 合同金额
                    FROM(SELECT c1.ContractGUID ,
                                c1.ProjectGUID ,
                                c1.CostGUID ,
                                c1.ApproveStateEnum ,
                                SUM(ISNULL(c1.CfAmount, 0)) AS CfAmount ,
                                MAX(CASE WHEN c1.BillType = '合同' THEN c1.BillCode END) AS BillCode ,
                                MAX(CASE WHEN c1.BillType = '合同' THEN c1.BillName END) AS BillName
                         FROM   data_wide_cb_budgetuse c1
                         WHERE  c1.BillType IN ('合同', '补充合同') AND   c1.ApproveStateEnum = 3
                                AND (CostCode LIKE 'A.02.02%' OR CostCode LIKE 'A.02.03%' OR CostCode LIKE 'A.02.04%' OR CostCode LIKE 'A.05.02%')
                         GROUP BY c1.ContractGUID ,
                                  c1.ProjectGUID ,
                                  c1.CostGUID ,
                                  c1.ApproveStateEnum) c
                        INNER JOIN dbo.data_wide_mdm_Project p ON p.p_projectId = c.ProjectGUID
                        INNER JOIN data_wide_mdm_BusinessUnit bu WITH(NOLOCK)ON p.BUGUID = bu.BUGUID
                    WHERE   ApproveStateEnum = 3 AND
                    --合同对应的设计变更及补充协议
                    EXISTS (SELECT  alt1.ProjectGUID ,
                                    alt1.CostGUID ,
                                    alt1.ContractGUID ,
                                    SUM(ISNULL(alt1.CfAmount, 0)) AS AltCfAmount
                            FROM    data_wide_cb_budgetuse alt1
                            WHERE   alt1.BillType IN ('设计变更', '设计变更完工确认', '现场签证', '现场签证完工确认') AND   alt1.ApproveStateEnum = 3
                                    -- AND  (alt1.CostCode LIKE  'A.02.02%' OR  alt1.CostCode LIKE  'A.02.03%' OR  alt1.CostCode LIKE  'A.02.04%' OR  alt1.CostCode LIKE  'A.05.02%') 
                                    AND alt1.ProjectGUID = c.ProjectGUID AND alt1.ContractGUID = c.ContractGUID --AND  alt1.CostGUID =c.CostGUID
                            GROUP BY alt1.ProjectGUID ,
                                     alt1.CostGUID ,
                                     alt1.ContractGUID )
                    GROUP BY p.BUGUID ,
                             bu.BUName ,
                             p.ProjName ,
                             p.p_projectId ,
                             p.ParentGUID ,
                             c.ContractGUID
                  /* UNION ALL
                    --设计变更
                    SELECT  p.BUGUID ,
                            bu.BUName AS 区域 ,
                            p.ProjName AS 分期名称 ,
                            p.p_projectId ,
                            p.ParentGUID ,
                            '设计变更' AS AlterClass ,
                            c.ContractGUID ,
                            SUM(ISNULL(c.CfAmount, 0)) AS 合同金额
                    FROM(SELECT c1.ContractGUID ,
                                c1.ProjectGUID ,
                                c1.CostGUID ,
                                c1.ApproveStateEnum ,
                                SUM(ISNULL(c1.CfAmount, 0)) AS CfAmount ,
                                MAX(CASE WHEN c1.BillType = '合同' THEN c1.BillCode END) AS BillCode ,
                                MAX(CASE WHEN c1.BillType = '合同' THEN c1.BillName END) AS BillName
                         FROM   data_wide_cb_budgetuse c1
                         WHERE  c1.BillType IN ('合同', '补充合同') AND   c1.ApproveStateEnum = 3
                                AND (CostCode LIKE 'A.02.02%' OR CostCode LIKE 'A.02.03%' OR CostCode LIKE 'A.02.04%' OR CostCode LIKE 'A.05.02%')
                         GROUP BY c1.ContractGUID ,
                                  c1.ProjectGUID ,
                                  c1.CostGUID ,
                                  c1.ApproveStateEnum) AS c
                        INNER JOIN dbo.data_wide_mdm_Project p ON p.p_projectId = c.ProjectGUID
                        INNER JOIN data_wide_mdm_BusinessUnit bu WITH(NOLOCK)ON p.BUGUID = bu.BUGUID
                    WHERE   ApproveStateEnum = 3
                            --合同对应的设计变更及补充协议
                            AND EXISTS (SELECT  alt1.ProjectGUID ,
                                                alt1.CostGUID ,
                                                alt1.ContractGUID ,
                                                SUM(ISNULL(alt1.CfAmount, 0)) AS AltCfAmount
                                        FROM    data_wide_cb_budgetuse alt1
                                        WHERE   alt1.BillType IN ('设计变更', '设计变更完工确认') AND   alt1.ApproveStateEnum = 3
                                                -- AND  (alt1.CostCode LIKE  'A.02.02%' OR  alt1.CostCode LIKE  'A.02.03%' OR  alt1.CostCode LIKE  'A.02.04%' OR  alt1.CostCode LIKE  'A.05.02%') 
                                                AND alt1.ProjectGUID = c.ProjectGUID AND alt1.ContractGUID = c.ContractGUID --AND  alt1.CostGUID =c.CostGUID
                                        GROUP BY alt1.ProjectGUID ,
                                                 alt1.CostGUID ,
                                                 alt1.ContractGUID)
                    GROUP BY p.BUGUID ,
                             bu.BUName ,
                             p.ProjName ,
                             p.p_projectId ,
                             p.ParentGUID ,
                             c.ContractGUID
                    --签证变更(现场签证+设计变更)
                    UNION ALL
                    SELECT  p.BUGUID ,
                            bu.BUName AS 区域 ,
                            p.ProjName AS 分期名称 ,
                            p.p_projectId ,
                            p.ParentGUID ,
                            '现场签证' AS AlterClass ,
                            c.ContractGUID ,
                            SUM(ISNULL(c.CfAmount, 0)) AS 合同金额
                    FROM(SELECT c1.ContractGUID ,
                                c1.ProjectGUID ,
                                c1.CostGUID ,
                                c1.ApproveStateEnum ,
                                SUM(ISNULL(c1.CfAmount, 0)) AS CfAmount ,
                                MAX(CASE WHEN c1.BillType = '合同' THEN c1.BillCode END) AS BillCode ,
                                MAX(CASE WHEN c1.BillType = '合同' THEN c1.BillName END) AS BillName
                         FROM   data_wide_cb_budgetuse c1
                         WHERE  c1.BillType IN ('合同', '补充合同') AND   c1.ApproveStateEnum = 3
                                AND (CostCode LIKE 'A.02.02%' OR CostCode LIKE 'A.02.03%' OR CostCode LIKE 'A.02.04%' OR CostCode LIKE 'A.05.02%')
                         GROUP BY c1.ContractGUID ,
                                  c1.ProjectGUID ,
                                  c1.CostGUID ,
                                  c1.ApproveStateEnum) AS c
                        INNER JOIN dbo.data_wide_mdm_Project p ON p.p_projectId = c.ProjectGUID
                        INNER JOIN data_wide_mdm_BusinessUnit bu WITH(NOLOCK)ON p.BUGUID = bu.BUGUID
                    WHERE   ApproveStateEnum = 3
                            --合同对应的设计变更及补充协议
                            AND EXISTS (SELECT  alt1.ProjectGUID ,
                                                alt1.CostGUID ,
                                                alt1.ContractGUID ,
                                                SUM(ISNULL(alt1.CfAmount, 0)) AS AltCfAmount
                                        FROM    data_wide_cb_budgetuse alt1
                                        WHERE   alt1.BillType IN ('现场签证', '现场签证完工确认') AND   alt1.ApproveStateEnum = 3
                                                -- AND  (alt1.CostCode LIKE  'A.02.02%' OR  alt1.CostCode LIKE  'A.02.03%' OR  alt1.CostCode LIKE  'A.02.04%' OR  alt1.CostCode LIKE  'A.05.02%') 
                                                AND alt1.ProjectGUID = c.ProjectGUID AND alt1.ContractGUID = c.ContractGUID --AND  alt1.CostGUID =c.CostGUID
                                        GROUP BY alt1.ProjectGUID ,
                                                 alt1.CostGUID ,
                                                 alt1.ContractGUID)
                    GROUP BY p.BUGUID ,
                             bu.BUName ,
                             p.ProjName ,
                             p.p_projectId ,
                             p.ParentGUID ,
                             c.ContractGUID*/ 
				)

       --查询结果
        SELECT  ISNULL(p.BUGUID, con.BUGUID) AS BUGUID ,
                ISNULL(con.p_projectId, p.p_projectId) AS p_projectId ,
                ISNULL(con.ParentGUID, p.ParentGUID) AS ParentGUID ,
                ISNULL(con.分期名称, p.ProjName) AS 分期名称 ,
                SUM(ISNULL(alt.变更签证金额, 0)) AS 变更签证金额 ,
                sum(ISNULL(alt.变更签证份数, 0)) AS 变更签证份数 ,
                sum(ISNULL(alt.现场签证金额, 0)) AS 现场签证金额 ,
                sum(ISNULL(alt.现场签证份数, 0)) AS 现场签证份数 ,
                sum(ISNULL(alt.设计变更金额, 0)) AS 设计变更金额 ,
                sum(ISNULL(alt.设计变更份数, 0)) AS 设计变更份数 ,
                sum(ISNULL(con.合同金额, 0)) AS 合同金额 ,
                --ISNULL(b.现场签证对应合同金额, 0) AS 现场签证对应合同金额 ,
                --ISNULL(b.设计变更对应合同金额, 0) AS 设计变更对应合同金额 ,
                --ISNULL(b.签证变更对应合同金额, 0) AS 签证变更对应合同金额 ,
                CASE WHEN SUM(ISNULL(con.合同金额, 0)) = 0 THEN 0 ELSE SUM(ISNULL(变更签证金额, 0)) / SUM(ISNULL(con.合同金额, 0)) END AS 整体变更率 ,
                CASE WHEN SUM(ISNULL(con.合同金额, 0)) = 0 THEN 0 ELSE SUM(ISNULL(现场签证金额, 0)) / SUM(ISNULL(con.合同金额, 0)) END AS 现场签证变更率 ,
                CASE WHEN SUM(ISNULL(con.合同金额, 0)) = 0 THEN 0 ELSE SUM(ISNULL(设计变更金额, 0)) / SUM(ISNULL(con.合同金额, 0)) END AS 设计变更变更率
        INTO    #alterRate
        FROM    data_wide_mdm_Project p
                INNER JOIN data_wide_mdm_BusinessUnit bu WITH(NOLOCK)ON p.BUGUID = bu.BUGUID
				INNER JOIN  #c con  ON  con.p_projectId= p.p_projectId
                LEFT JOIN (
					   SELECT    #alt.p_projectId ,
								ContractGUID ,
								sum(ISNULL(变更签证金额, 0)) AS 变更签证金额 ,
								sum(ISNULL(变更签证份数, 0)) AS 变更签证份数 ,
								sum(ISNULL(现场签证金额, 0)) AS 现场签证金额 ,
								sum(ISNULL(现场签证份数, 0)) AS 现场签证份数 ,
								sum(ISNULL(设计变更金额, 0)) AS 设计变更金额 ,
								sum(ISNULL(设计变更份数, 0)) AS 设计变更份数 
					  FROM  #alt
					  GROUP BY #alt.p_projectId ,
							   ContractGUID
				) alt ON  con.ContractGUID = alt.ContractGUID AND  con.p_projectId  = alt.p_projectId
                --LEFT JOIN(SELECT    bb.BUGUID ,
                --                    bb.区域 ,
                --                    bb.p_projectId ,
                --                    bb.ParentGUID ,
                --                    bb.分期名称 ,
                --                    SUM(ISNULL(bb.合同金额, 0)) AS 合同金额 ,
                --                    SUM(CASE WHEN bb.AlterClass = '现场签证' THEN ISNULL(bb.合同金额, 0)ELSE 0 END) AS 现场签证对应合同金额 ,
                --                    SUM(CASE WHEN bb.AlterClass = '设计变更' THEN ISNULL(bb.合同金额, 0)ELSE 0 END) AS 设计变更对应合同金额 ,
                --                    SUM(CASE WHEN bb.AlterClass = '签证变更' THEN ISNULL(bb.合同金额, 0)ELSE 0 END) AS 签证变更对应合同金额
                --          FROM  #c AS bb
                --                INNER JOIN #ConAlt cc ON bb.p_projectId = cc.p_projectId AND bb.ContractGUID = cc.ContractGUID
                --          GROUP BY bb.BUGUID ,
                --                   bb.区域 ,
                --                   bb.p_projectId ,
                --                   bb.ParentGUID ,
                --                   bb.分期名称) b ON a.p_projectId = b.p_projectId
        WHERE   p.Level = 3  
		GROUP BY ISNULL(p.BUGUID, con.BUGUID)  ,
                ISNULL(con.p_projectId, p.p_projectId) ,
                ISNULL(con.ParentGUID, p.ParentGUID) ,
				ISNULL(con.分期名称, p.ProjName) ;

        --/////////////////////////////科目超支统计//////////////////////////////////////////////////////
        WITH #cost AS (SELECT   P1.p_projectId AS ProjGUID ,
                                P1.ProjName AS 项目名称 ,
                                P.p_projectId AS fqProjGUID ,
                                P.ProjName AS 分期名称 ,
                                MD.CostCode AS 科目编号 ,
                                MD.CostShortName AS 科目名称 ,
                                ISNULL(MD.CurDynamicCost, 0) AS 动态成本金额 ,
                                ISNULL(MD.TargetCost, 0) + ISNULL(MD.AdjustCost, 0) AS 目标成本金额 , --本次目标成本+调整金额
                                ISNULL(MD.CurDynamicCost, 0) - (ISNULL(MD.TargetCost, 0) + ISNULL(MD.AdjustCost, 0)) AS 科目超支金额 ,
                                CASE WHEN (ISNULL(MD.TargetCost, 0) + ISNULL(MD.AdjustCost, 0)) = 0 THEN 0
                                     ELSE (ISNULL(MD.CurDynamicCost, 0) - (ISNULL(MD.TargetCost, 0) + ISNULL(MD.AdjustCost, 0))) * 1.0 / (ISNULL(MD.TargetCost, 0) + ISNULL(MD.AdjustCost, 0))
                                END AS 科目超支比例
                       --ISNULL(TCVD.TotalTargetCost, 0) AS 目标成本金额 ,
                       --ISNULL(MD.CurDynamicCost, 0) - ISNULL(TCVD.TotalTargetCost, 0) AS 科目超支金额 ,
                       --CASE WHEN ISNULL(TCVD.TotalTargetCost, 0) = 0 THEN 0
                       --     ELSE (ISNULL(MD.CurDynamicCost, 0) - ISNULL(TCVD.TotalTargetCost, 0)) * 100.0 / ISNULL(TCVD.TotalTargetCost, 0)
                       --END AS 科目超支比例
                       FROM (SELECT ProjGUID ,
                                    MonthlyReviewGUID ,
                                    ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY ReviewDate DESC) RN
                             FROM   data_wide_cb_MonthlyReview
                             WHERE  (1 = 1) --AND ApproveStateEnum = 3
                       ) M
                            LEFT JOIN data_wide_mdm_Project P WITH(NOLOCK)ON P.p_projectId = M.ProjGUID
                            LEFT JOIN data_wide_mdm_Project P1 WITH(NOLOCK)ON P.ParentGUID = P1.p_projectId
                            LEFT JOIN data_wide_cb_MonthlyReviewCostDetail MD ON M.MonthlyReviewGUID = MD.MonthlyReviewGUID
                            OUTER APPLY(SELECT  TOP 1   TCSV.TargetCostStageVersionGUID
                                        FROM    data_wide_cb_TargetCostStageVersion TCSV WITH(NOLOCK)
                                                LEFT JOIN data_wide_cb_TargetCostVersion TCV WITH(NOLOCK)ON TCV.TargetCostVersionGUID = TCSV.TargetCostVersionGUID
                                        WHERE   TCSV.ApproveStateEnum = 3 AND   ProjectGUID = M.ProjGUID
                                        ORDER BY CASE WHEN TCV.IsSetVersion = 1 THEN 9999999999999999 ELSE TCV.RowIndex END DESC) TCSV
                            LEFT JOIN(SELECT    StageAccountGUID ,
                                                TargetCostStageVersionGUID ,
                                                SUM(TotalTargetCost) TotalTargetCost
                                      FROM  data_wide_cb_TargetCostStageVersionDetail WITH(NOLOCK)
                                      --WHERE ProjectGUID IN (@ProjGUID)
                                      GROUP BY StageAccountGUID ,
                                               TargetCostStageVersionGUID
                                      HAVING SUM(TotalTargetCost) > 0) TCVD ON TCSV.TargetCostStageVersionGUID = TCVD.TargetCostStageVersionGUID AND TCVD.StageAccountGUID = MD.CostGUID
                       WHERE M.RN = 1 AND   MD.CostShortName IN ('工程间接费', '室外工程费', '土建及外立面装修工程', '机电安装工程费', '精装修工程费', '其它室内工程费', '公共配套设施费')
                             --AND ISNULL(MD.CurDynamicCost, 0) - ISNULL(TCVD.TotalTargetCost, 0) > 0)
                             AND (ISNULL(MD.CurDynamicCost, 0) - (ISNULL(MD.TargetCost, 0) + ISNULL(MD.AdjustCost, 0))) > 0)
        SELECT  p.p_projectId AS fqProjGUID ,
                p.ProjName AS 分期名称 ,
                ISNULL(cst.超支科目数量, 0) AS 超支科目数量 ,
                ISNULL(cst.科目超值金额, 0) AS 科目超值金额 ,
                ISNULL(cst.动态成本金额, 0) AS 动态成本金额 ,
                ISNULL(cst.目标成本金额, 0) AS 目标成本金额 ,
                CASE WHEN ISNULL(cst.超支科目数量, 0) > 0 THEN '红灯预警' ELSE '绿灯正常' END AS 预警状态
        INTO    #kmOver
        FROM    data_wide_mdm_Project p
                LEFT JOIN(SELECT    a.fqProjGUID ,
                                    a.分期名称 ,
                                    COUNT(a.科目编号) AS 超支科目数量 ,
                                    SUM(ISNULL(a.科目超支金额, 0)) AS 科目超值金额 ,
                                    SUM(ISNULL(a.动态成本金额, 0)) AS 动态成本金额 ,
                                    SUM(ISNULL(a.目标成本金额, 0)) AS 目标成本金额
                          FROM  #cost a
                          GROUP BY fqProjGUID ,
                                   分期名称) cst ON p.p_projectId = cst.fqProjGUID
        WHERE   p.Level = 3;

        --///////////////////////////查询结果///////////////////////////
        SELECT  CONVERT(VARCHAR(10), GETDATE(), 121) AS 报告日期 ,
                ROW_NUMBER() OVER (ORDER BY a.BUName, a.ProjName ) AS 序号 ,
                a.BUName AS 公司 ,
                a.ProjName AS 项目分期名称 ,
                b.Deduct AS 扣分 ,
                b.Point AS 得分 ,
				c.项目进度,
				--c.项目进度排序,
                c.进度与目标成本是否匹配,
                CASE WHEN c.进度与目标成本是否匹配 = '匹配' THEN c.当前目标成本版本 END AS 匹配 ,
                CASE WHEN c.进度与目标成本是否匹配 = '不匹配' THEN c.当前目标成本版本 END AS 不匹配 ,
                CASE WHEN c.进度与目标成本是否匹配 = '无主项计划' THEN c.当前目标成本版本 END AS 无主项计划 ,
                CASE WHEN c.进度与目标成本是否匹配 = '未开始' THEN c.当前目标成本版本 END AS 未开始 ,

                ISNULL(d.截止本月设计变更未上线单据数量, 0) AS 设计变更未上线单据数量 ,
                ISNULL(d.截止本月设计变更未上线单据预估金额, 0) / 10000.0 AS 设计变更未上线预估金额 ,
                ISNULL(d.截止本月签证变更未上线单据数量, 0) AS 现场签证未上线单据数量 ,
                ISNULL(d.截止本月签证变更未上线单据预估金额, 0) / 10000.0 AS 现场签证未上线预估金额 ,
                ISNULL(f.设计变更金额, 0) / 10000.0 AS 设计变更已上线金额 ,
				--ISNULL(f.设计变更对应合同金额,0) /10000.0 AS 设计变更对应合同金额,
		        ISNULL(f.合同金额,0) /10000.0 AS 设计变更对应合同金额,
                f.设计变更变更率 AS 设计变更已上线变更率 ,
                ISNULL(f.现场签证金额, 0) / 10000.0 AS 现场签证已上线金额 ,
				ISNULL(f.合同金额,0)/10000.0 AS 现场签证对应合同金额,
                f.现场签证变更率 AS 现场签证已上线签证率 ,
                ISNULL(f.变更签证金额, 0) / 10000.0 AS 变更签证已上线金额 ,
				ISNULL(f.合同金额,0)/10000.0 AS 签证变更对应合同金额,
                f.整体变更率 AS 变更签证已上线变更签证率 ,
                e.超支科目数量 AS 科目超支数量 ,
                ISNULL(e.科目超值金额, 0) / 10000.0 AS 科目超支金额 ,
                d.超目标成本风险 AS 超成本预警 ,
                --当前日期大于25号的取本月，25号之前的取上月月份
                '珠江地产1-' + CASE WHEN DAY(GETDATE()) < 25 THEN CONVERT(VARCHAR(10), MONTH(DATEADD(MONTH, -1, GETDATE())))ELSE CONVERT(VARCHAR(10), MONTH(GETDATE()))END + '月成本管控统计一览表' AS 报表标题
        INTO    #Rust
        FROM    #ExamProj a
                LEFT JOIN #examine b ON a.p_projectId = b.ProjGUID
                LEFT JOIN #jdMate c ON c.p_projectId = a.p_projectId
                LEFT JOIN #MonthlyReview d ON d.分期GUID = a.p_projectId
                LEFT JOIN #kmOver e ON e.fqProjGUID = a.p_projectId
                LEFT JOIN #alterRate f ON f.p_projectId = a.p_projectId
        WHERE(1 = 1);

        ---////统计成本分析概述
        DECLARE @BUCount AS INT; --公司数量
        DECLARE @FqCount AS INT; --项目分期数量
        DECLARE @GreaterFqCount AS INT; --优秀的分期数量
        DECLARE @GreaterFqRate AS MONEY; --优秀的考核分期占比
        DECLARE @GreateFqProjName VARCHAR(200); --优秀项目分期名称列表
        DECLARE @LowerFqCount AS INT; --不合格的分期数量
        DECLARE @LowerFqRate AS MONEY; --不合格的考核分期占比
        DECLARE @LowerFqProjName VARCHAR(200);

		DECLARE @MateFqCount int --匹配分期数
        DECLARE @NotMateFqCount INT --不匹配分期数
		DECLARE @NotProjPlanFqCount INT --无主项计划分期数
		DECLARE @NotStartedFqCount INT  --未开始分期数

		DECLARE @MateFqRate Money --匹配分期占比
        DECLARE @NotMateFqRate Money --不匹配分期占比
		DECLARE @NotProjPlanFqRate Money --无主项计划分期占比
		DECLARE @NotStartedFqRate Money  --未开始分期占比

        --统计赋值
        SELECT  @BUCount = COUNT(DISTINCT 公司) ,
                @FqCount = COUNT(DISTINCT 项目分期名称) ,
                @GreaterFqCount = SUM(CASE WHEN 得分 >= 90 THEN 1 ELSE 0 END) ,
                @GreaterFqRate = CASE WHEN COUNT(DISTINCT 项目分期名称) = 0 THEN 0 ELSE SUM(CASE WHEN 得分 >= 90 THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT 项目分期名称) * 1.0 END ,
                @LowerFqCount = SUM(CASE WHEN 得分 < 90 THEN 1 ELSE 0 END) ,
                @LowerFqRate = CASE WHEN COUNT(DISTINCT 项目分期名称) = 0 THEN 0 ELSE SUM(CASE WHEN 得分 < 90 THEN 1 ELSE 0 END) * 1.0 / COUNT(DISTINCT 项目分期名称) * 1.0 END,
				@MateFqCount =SUM(CASE WHEN  ISNULL(进度与目标成本是否匹配,'') ='匹配' THEN  1 ELSE  0 END   ),
				@NotMateFqCount=SUM(CASE WHEN  ISNULL(进度与目标成本是否匹配,'') ='不匹配' THEN  1 ELSE  0 END   ),
				@NotProjPlanFqCount=SUM(CASE WHEN  ISNULL(进度与目标成本是否匹配,'') ='无主项计划' THEN  1 ELSE  0 END   ),
				@NotStartedFqCount=SUM(CASE WHEN  ISNULL(进度与目标成本是否匹配,'') ='未开始' THEN  1 ELSE  0 END   ),

				@MateFqRate =CASE WHEN COUNT(DISTINCT 项目分期名称) = 0 THEN 0 ELSE   SUM(CASE WHEN  ISNULL(匹配,'')<>'' THEN  1 ELSE  0 END   ) *1.0 / COUNT(DISTINCT 项目分期名称)  *1.0  END ,
				@NotMateFqRate=CASE WHEN COUNT(DISTINCT 项目分期名称) = 0 THEN 0 ELSE  SUM(CASE WHEN  ISNULL(不匹配,'')<>'' THEN  1 ELSE  0 END   ) *1.0 / COUNT(DISTINCT 项目分期名称)  *1.0  END ,
				@NotProjPlanFqRate=CASE WHEN COUNT(DISTINCT 项目分期名称) = 0 THEN 0 ELSE  SUM(CASE WHEN  ISNULL(无主项计划,'')<>'' THEN  1 ELSE  0 END   )*1.0 / COUNT(DISTINCT 项目分期名称)  *1.0  END ,
				@NotStartedFqRate=CASE WHEN COUNT(DISTINCT 项目分期名称) = 0 THEN 0 ELSE  SUM(CASE WHEN  ISNULL(未开始,'')<>'' OR ( 匹配 IS NULL AND  不匹配 IS NULL AND 无主项计划 IS NULL AND  未开始 IS NULL  ) THEN  1 ELSE  0 END   )*1.0 / COUNT(DISTINCT 项目分期名称)  *1.0  END 
        FROM    #Rust;

        --输出结果表
        SELECT  @BUCount AS 公司数量 ,
                @FqCount AS 项目分期数量 ,
                @GreaterFqCount AS 优秀的分期数量 ,
                @GreaterFqRate AS 优秀的考核分期占比 ,
                @LowerFqCount AS 不合格的分期数量 ,
                @LowerFqRate AS 不合格的考核分期占比 ,
				@MateFqCount AS  匹配分期数,
				@NotMateFqCount AS 不匹配分期数,
				@NotProjPlanFqCount AS 无主项计划分期数,
				@NotStartedFqCount AS 未开始分期数,
				
				@MateFqRate AS 匹配分期占比,
				@NotMateFqRate AS 不匹配分期占比,
				@NotProjPlanFqRate AS 无主项计划分期占比,
				@NotStartedFqRate AS 未开始分期占比,
                STUFF((SELECT   TOP 3   RTRIM(',' + 项目分期名称)
                       FROM #Rust
                       WHERE 得分 >= 90
                       ORDER BY 得分 DESC
                      FOR XML PATH('')), 1, 1, '') AS 优秀项目分期名称列表 ,
			    STUFF((SELECT   TOP 3   RTRIM(',' + 项目分期名称)
                       FROM #Rust
                       WHERE 得分 < 90
                       ORDER BY 得分 
                      FOR XML PATH('')), 1, 1, '') AS 不合格项目分期名称列表 ,
                *
        FROM    #Rust;

        --///////////////////////////删除临时表///////////////////////////
        DROP TABLE #examine ,
                   #ExamProj ,
                   #jdMate ,
                   #MonthlyReview ,
                   #kmOver ,
                   #alterRate;
    END;
