USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_GetAmountDetailsInfo]    Script Date: 2024/12/4 14:36:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--EXEC  [usp_rpt_s_GetAmountDetailsInfo] '5E3BC2C3-F005-EA11-8A8E-40F2E92B3FDA'  ,'2024-01-01','2024-04-30'

ALTER PROC [dbo].[usp_rpt_s_GetAmountDetailsInfo](@ProjGUID VARCHAR(MAX) ,
                                                  @SDate DATETIME , --收款开始日期
                                                  @EDate DATETIME   --收款截止日期
)
AS
    BEGIN

        --查询结果
        SELECT  CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END AS 项目推广名 ,
				pp.x_area AS 管理片区,
				pp.x_ManagementSubject AS 管理主体,
                p.ProjShortName AS 期数 ,
                p.ProjName AS 项目名称 ,
                g.AreaName AS 分区 ,
                g.RoomNum AS 房间号 ,
                g.BldName AS 楼栋名称 ,
                g.UnitNo AS 单元 ,
                g.ShortRoomInfo AS 房号 ,g.RoomGUID AS 房间GUID,
                ISNULL(tr.CCstAllName, tr.OCstAllName) AS 客户名称 ,
                CASE WHEN tr.CStatus = '激活' AND tr.ContractType = '网签' THEN '网签' 
					 WHEN tr.CStatus = '激活' AND tr.ContractType = '草签' THEN '草签'  
					 WHEN tr.OStatus = '激活'  THEN '认购' 
					 WHEN tr.CCloseReason='退房' OR tr.OCloseReason='退房' THEN '退房'
					 WHEN tr.CCloseReason='换房' OR tr.OCloseReason='换房' THEN '换房'
					 ELSE ISNULL(tr.CCloseReason,tr.OCloseReason) END AS 交易状态 ,
                tr.OQsDate AS 认购日期 ,
                tr.x_InitialledDate AS 草签日期 ,
                tr.CNetQsDate AS 网签日期 ,
                tr.ProjNum AS 项目排号 ,
                CASE WHEN tr.TopProductTypeName = '车位' THEN
                         STUFF(
                         (SELECT    DISTINCT RTRIM(',' + tr1.RoomInfo)
                          FROM  data_wide_s_Trade tr1
                          WHERE tr1.TopProductTypeName = '住宅' AND  tr1.IsLast = 1 AND  tr1.TradeStatus = '激活'
                                AND  ISNULL(tr1.OCstAllCardID, tr1.CCstAllCardID) = ISNULL(tr.OCstAllCardID, tr.CCstAllCardID)
                         FOR XML PATH('')), 1, 1, '')
                END AS 车位对应业主的住宅房号 ,
                CASE WHEN tr.TopProductTypeName = '车位' THEN
                         STUFF(
                         (SELECT    DISTINCT RTRIM(',' + ISNULL(tr1.OCstAllName, tr1.CCstAllName))
                          FROM  data_wide_s_Trade tr1
                          WHERE tr1.TopProductTypeName = '住宅' AND  tr1.IsLast = 1 AND  tr1.TradeStatus = '激活'
                                AND  ISNULL(tr1.OCstAllCardID, tr1.CCstAllCardID) = ISNULL(tr.OCstAllCardID, tr.CCstAllCardID)
                         FOR XML PATH('')), 1, 1, '')
                END AS 车位对应住宅业主名 ,
                --NULL AS 车位对应业主的住宅房号,
                --NULL AS 车位对应住宅业主名,
                g.SkDate AS 收款日期 ,
                g.PreVouchKpDate AS 开票日期 ,
                g.InvoType AS 票据类型 ,g.VouchType,
                g.InvoNO AS 票据编号 ,
                g.ItemType AS 款项类型 ,
                g.ItemName AS 款项名称 ,
                g.BZ AS 币种 ,
                g.Amount AS 金额 ,
                g.TaxRate AS 税率 ,
                CASE WHEN (1 + ISNULL(g.TaxRate, 0)) = 0 THEN 0 ELSE ISNULL(g.Amount, 0) / (1 + ISNULL(g.TaxRate, 0)*0.01)END AS 无税金额 ,
                g.TaxAmount AS 税额 ,
                g.ExRate AS 汇率 ,
                g.RmbAmount AS 折人民币金额 ,
                g.GetForm AS 支付方式 ,
                g.Remark AS 摘要 ,
                g.RzBank AS 入账银行 ,
                g.PosTerminal AS 刷卡终端 ,
                g.PosCode AS POS单号 ,
				g.PosAmount AS POS手续费 ,
                g.PosBankCard AS 银行卡 ,
                g.FsettlCode AS 结算方式 ,
                g.FsettleNo AS 结算单号 ,
                g.GetForm AS 银付方式 ,
                g.AuditName AS 审核人 ,
                g.kpr AS 开票人 ,
                g.Jkr AS 交款人,  tr.YjfDate AS 预计交房日期 ,tr.SjjfDate AS 实际交房日期,
                NULL AS 放款银行
        FROM    dbo.data_wide_s_Getin g WITH(NOLOCK)
                INNER JOIN dbo.data_wide_mdm_Project p WITH(NOLOCK)ON p.p_projectId = g.ProjGUID
                INNER JOIN data_wide_mdm_Project pp WITH(NOLOCK)ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
	
                LEFT JOIN dbo.data_wide_s_Trade tr WITH(NOLOCK)ON tr.TradeGUID = g.SaleGUID --and ((tr.oStatus='激活' or tr.CStatus='激活')or tr.CCloseReason='退房' or tr.OCloseReason='退房')
             AND  tr.IsLast = 1 --调整为左连接取出诚意金房款
        -- INNER JOIN dbo.data_wide_s_Room r ON r.RoomGUID = g.RoomGUID
        WHERE   g.VouchStatus <> '作废' AND   g.ProjGUID IN(SELECT    [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') ) AND  g.SkDate BETWEEN @SDate AND @EDate
		AND  g.VouchType NOT IN ( 'POS机单', '划拨单', '放款单' )
        ORDER BY -- CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END ,
        p.ProjName;
    --  g.RoomInfo;
    END;










---- 宽表调整data_wide_s_Getin
/*实收宽表-1.新增实收款项*/
SELECT g.GetinGUID,      --收款GUID
       g.VouchGUID,      --单据GUID
       g.SaleGUID,       --销售单GUID
       g.ItemType,       --款项类型
       g.ItemName,       --款项名称
       g.IsSysCx,        --是否冲销
       case when charindex('楼款',g.ItemName)>0 then '楼款'
            when charindex('首期',g.ItemName)>0 then '首期'
            when charindex('定金',g.ItemName)>0 then '定金'
            else '其他' end as Report_ItemName,     --款项名称（模糊匹配）
       g.ItemNameGUID,   --款项名称GUID
	   feeItem.FeeItemCode AS ItemCode,       --款项排序Code
       TopFeeItem.FeeItemCode AS TopItemCode,       --一级款项排序Code
       TopFeeItem.FeeItemGUID AS TopItemNameGUID,   --一级款项名称GUID
       g.Amount,         --收款金额
       g.RmbAmount,      --收款金额(人民币)
       g.RzBank,         --入账银行
       g.GetForm,        --支付方式
       g.PosCode,        --POS单号
       g.PosAmount,      --POS机手续费
       g.TaxAmount,      --税额
       /* 款项等于定金时，收款日期为转账单的实收日期 */
       case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end as SkDate, --收款日期
            /*  CASE WHEN g.GetForm LIKE '%POS%' AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
			 WHEN g.GetForm LIKE '%POS%' AND wd.x_NextWorkDate IS  NULL THEN CONVERT(VARCHAR ,DATEADD(DAY, 1, g.GetDate) ,23)
			 ELSE CONVERT(VARCHAR , g.GetDate ,23)  END AS HKdate,--回款到账日期 */
       g.RoomGUID,       --房间GUID
       g.PosGUID,        --银行回单GUID
       g.BeforeRmbYe,    --对冲前人民币余额
       g.TaxRate         --
FROM   s_Getin g
inner join s_voucher v on v.VouchGUID = g.VouchGUID
	   LEFT JOIN s_FeeItem feeItem
           ON g.ItemNameGuid = feeItem.FeeItemGUID
	   LEFT JOIN s_FeeItem TopFeeItem
           ON TopFeeItem.FeeItemGUID = feeItem.ParentGUID
       	 --  LEFT JOIN x_HoliDayDetial wd ON CONVERT(VARCHAR ,DATEADD(DAY, 1, g.GetDate) ,23)  = CONVERT(VARCHAR,wd.x_vacationDate,23)



