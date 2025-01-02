--ZSDC-05-实收款项明细表(全表)-含回款到账日期
IF @版本号='实时' 
BEGIN
SELECT  
    null as SnapshotTime,
    null as VersionNo,
    null as ProjGUID,
    null as SkDate,
    CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END AS 项目推广名 ,
    pp.x_area AS 管理片区,
    pp.x_ManagementSubject AS 管理主体,
    p.ProjShortName AS 期数 ,
    p.ProjName AS 项目名称 ,
    g.AreaName AS 分区 ,
    g.RoomNum AS 房间号 ,
    g.BldName AS 楼栋名称 ,
    g.UnitNo AS 单元 ,
    g.ShortRoomInfo AS 房号 ,
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
    /* CASE WHEN  pp.ProjName IN ('西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心') 
                AND g.GetForm LIKE '%POS%' AND g.VouchType ='收款单' AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
            WHEN  pp.ProjName IN ('西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心') 
                AND g.GetForm LIKE '%POS%' AND g.VouchType ='收款单' AND wd.x_NextWorkDate IS  NULL THEN CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
        WHEN  pp.ProjName IN ('西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心') 
                AND ( g.GetForm NOT LIKE '%POS%' or  g.VouchType !='收款单')  THEN  CONVERT(VARCHAR , g.SkDate ,23)
        WHEN  pp.ProjName IN ('珠江海珠里','珠江嘉园','时光荟','同嘉路项目','钟落潭项目') AND g.GetForm LIKE '%POS%' AND g.VouchType ='收款单'
                THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
        WHEN  pp.ProjName IN ('珠江海珠里','珠江嘉园','时光荟','同嘉路项目','钟落潭项目') AND (g.GetForm NOT LIKE '%POS%' or  g.VouchType !='收款单') THEN  CONVERT(VARCHAR , g.SkDate ,23)
        ELSE    CONVERT(VARCHAR , g.SkDate ,23) END */
        CASE 
                WHEN g.VouchType ='退款单' THEN  isnull (g.rzdate, g.KpDate)
                WHEN g.VouchType ='转账单' THEN  g.KpDate
                WHEN g.VouchType ='换票单' THEN  g.SkDate
                WHEN g.VouchType ='收款单' THEN 
                CASE 
                        WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  NOT LIKE '%POS%' THEN g.SkDate
                        WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  LIKE '%POS%'  AND  pp.ProjName IN ('珠江花玙苑','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心')  AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
                        WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  LIKE '%POS%'  AND  pp.ProjName IN ('珠江花玙苑','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心')  AND wd.x_NextWorkDate IS  NULL THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
                        WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName  IN ('珠江海珠里','珠江嘉园','时光荟','同嘉路项目','钟落潭项目')   THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
                        
                        WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  NOT LIKE '%POS%' THEN g.SkDate
                        WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江花玙苑','花屿花城','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','同嘉路项目','钟落潭项目','珠江海珠里','珠江嘉园','时光荟') THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
                        WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江金悦','中侨中心') AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
                        WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江金悦','中侨中心') AND  wd.x_NextWorkDate IS  NULL THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
                ELSE g.SkDate END ELSE g.SkDate END AS   HKdate,		
        /*
项目名称	回款规则
珠江·花屿花城	工作日+1
珠实·西关都荟	工作日+1
珠江广钢花城	工作日+1
白云湖项目	工作日+1
珠江花城	工作日+1
同嘉路项目	自然日+1
钟落潭项目	自然日+1
珠江西湾里	工作日+1
中侨中心	工作日+1
珠江海珠里	自然日+1
珠江嘉园	自然日+1
时光荟	自然日+1
其他项目均等于收款日期  g.PreVouchKpDate AS 开票日期 ,
        */   
        g.KpDate AS 开票日期 ,
        g.InvoType AS 票据类型 ,
        g.VouchType,
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
        g.Jkr AS 交款人,  
        tr.YjfDate AS 预计交房日期 ,
        tr.SjjfDate AS 实际交房日期,
        tr.HtCarryoverDate as 首次结转日期,
        g.rzdate as 入账日期,
        NULL AS 放款银行,
        case when  isnull( g.IsExport,0) =0  then '否' else  '是' end as 是否输出NCC
FROM    dbo.data_wide_s_Getin g WITH(NOLOCK)
INNER JOIN dbo.data_wide_mdm_Project p WITH(NOLOCK)ON p.p_projectId = g.ProjGUID
INNER JOIN data_wide_mdm_Project pp WITH(NOLOCK)ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
LEFT JOIN data_wide_s_Holiday wd ON CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)  = CONVERT(VARCHAR,wd.x_vacationDate,23)
LEFT JOIN dbo.data_wide_s_Trade tr WITH(NOLOCK)ON tr.TradeGUID = g.SaleGUID --and ((tr.oStatus='激活' or tr.CStatus='激活')or tr.CCloseReason='退房' or tr.OCloseReason='退房')
        AND  tr.IsLast = 1 --调整为左连接取出诚意金房款
-- INNER JOIN dbo.data_wide_s_Room r ON r.RoomGUID = g.RoomGUID
WHERE   g.VouchStatus <> '作废' AND   g.ProjGUID IN (@ProjGUID) AND  g.SkDate BETWEEN @SDate AND @EDate
    AND  g.VouchType NOT IN ( 'POS机单', '划拨单', '放款单' )
ORDER BY -- CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END ,
    p.ProjName
    --  g.RoomInfo
END
ELSE 
BEGIN
    select 
        SnapshotTime,
        VersionNo,
        ProjGUID,
        SkDate,
        项目推广名,
        管理片区,
        管理主体,
        期数,
        项目名称,
        分区,
        房间号,
        楼栋名称,
        单元,
        房号,
        客户名称,
        交易状态,
        认购日期,
        草签日期,
        网签日期,
        项目排号,
        车位对应业主的住宅房号,
        车位对应住宅业主名,
        收款日期,
        回款日期 AS HKdate,
        开票日期,
        票据类型,
        凭证类型 as VouchType,
        票据编号,
        款项类型,
        款项名称,
        币种,
        金额,
        税率,
        无税金额,
        税额,
        汇率,
        折人民币金额,
        支付方式,
        摘要,
        入账银行,
        刷卡终端,
        POS单号,
        POS手续费,
        银行卡,
        结算方式,
        结算单号,
        银付方式,
        审核人,
        开票人,
        交款人,
        预计交房日期,
        实际交房日期,
        首次结转日期,
        入账日期,
        放款银行,
        是否输出NCC
    from Result_ReceivedPaymentDetail
    where VersionNo = @版本号
        and ProjGUID in (@ProjGUID)
END


