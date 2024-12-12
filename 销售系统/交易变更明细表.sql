USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_SaleAlterDetailsInfo]    Script Date: 2024/12/12 17:23:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 20241212 chenjw 调整 增加已交定金金额、累计已交款金额 */

ALTER PROC [dbo].[usp_rpt_s_SaleAlterDetailsInfo](@ProjGUID VARCHAR(MAX))
AS
    BEGIN
        SELECT  p.p_projectId ,
                pp.ProjName AS 项目 ,
                r.RoomInfo AS 房间 ,
                r.RoomGUID AS 房间唯一标识 ,
                sm.CstAllName AS 客户名称 ,tr.OCstAllTel,tr.OCstAllCardID,
                --CASE WHEN tr.CStatus = '激活' AND tr.ContractType = '网签' THEN '网签' WHEN tr.CStatus = '激活' AND tr.ContractType = '草签' THEN '草签' ELSE '认购' END AS 房间状态 ,
				CASE WHEN  sm.SaleType ='签约' AND tr.ContractType = '网签' THEN '网签' WHEN sm.SaleType ='签约' AND tr.ContractType = '草签' THEN '草签' 
				WHEN  sm.SaleType ='认购' THEN  '认购' END  AS 房间状态 ,
                tr.OQsDate AS 认购时间 ,tr.CAgreementNo,tr.x_InitialledNo,tr.ZcOrderDate,
                tr.x_InitialledDate AS 草签时间 ,
                tr.CNetQsDate AS 网签时间 ,
                r.x_YeJiTime AS 房间业绩认定日期 ,
                r.YsBldArea AS 预售建筑面积 ,
                r.YsTnArea AS 预售套内面积 ,
                ISNULL(tr.CPayForm, tr.OPayForm) AS 付款方式 ,
                ISNULL(tr.CCjTotal, OCjTotal) AS 成交金额 ,
                sm.ApplyType AS 申请类型 ,
                CASE WHEN sm.ApplyType = '退房' THEN tr.Sslk END AS 若申请退房退房金额 ,
                CASE WHEN sm.ApplyType = '退房' THEN CASE WHEN ISNULL(tr.CCjTotal, OCjTotal) = 0 THEN 0 ELSE ISNULL(tr.Sslk, 0) / ISNULL(tr.CCjTotal, OCjTotal)END END AS 房款占比 ,  --（退款金额/成交金额）
                sm.ReasonType AS 原因分类 ,
                sm.Reason AS 具体原因说明 ,
                ISNULL(x_CAgentLeader, x_OAgentLeader) AS 团队 ,
                ISNULL(tr.CZygw, tr.OZygw) AS 跟进销售 ,
                sm.AuditStatus AS 审批状态 ,
                sm.ApplyDate AS 申请日期 ,
                sm.AuditDate AS 批准日期 ,
                sm.ExecDate AS 执行日期 ,
                tr.SsDj as  已交定金金额,
                tr.Ssfk as 累计已交款金额
        FROM    dbo.data_wide_s_Room r WITH (NOLOCK )
                INNER JOIN dbo.data_wide_mdm_Project p  WITH (NOLOCK ) ON p.p_projectId = r.ProjGUID
                INNER JOIN data_wide_mdm_Project pp  WITH (NOLOCK ) ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
                INNER JOIN data_wide_s_SaleModiApply sm  WITH (NOLOCK ) ON sm.RoomGUID = r.RoomGUID
                LEFT JOIN dbo.data_wide_s_Trade tr WITH (NOLOCK )  ON sm.TradeGUID = tr.TradeGUID AND  tr.IsLast = 1
        WHERE   sm.ApplyStatus <> '作废' AND  r.ProjGUID IN(SELECT    [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') );
    END;


