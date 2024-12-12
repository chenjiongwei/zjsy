USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_RoomDetailsInfo]    Script Date: 2024/12/12 15:44:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

    
--EXEC  [usp_rpt_s_RoomDetailsInfo] '','住宅'  
  
ALTER PROC [dbo].[usp_rpt_s_RoomDetailsInfo](@ProjGUID VARCHAR(MAX) ,      --项目分期GUID  
                                      @ProductType VARCHAR(1000),--产品类型   
									  @BBH VARCHAR(10))    --版本号  
AS  
    BEGIN  
	IF @BBH='实时'
	BEGIN
        ----查询房间的增值税率信息保存到临时表  
        --SELECT  r.RoomGUID ,  
        --        r.BldGUID ,  
        --        r.RoomInfo ,  
        --        r.ProjGUID ,  
        --        (CASE WHEN sr.RoomGuid IS NULL THEN mpv.Value ELSE sr.Rate END) / 100.0 AS vatRate ,  
        --        CASE WHEN sr.RoomGuid IS NULL THEN 0 ELSE 1 END AS SpecilRoomRate   --是否特殊房间税率  
        --INTO    #vatRoomRate  
        --FROM    [dotnet_erp60_test_0427_old].dbo.s_Room r  
        --        LEFT JOIN [dotnet_erp60_test_0427_old].dbo.[myParamValue] mpv ON mpv.ScopeId = r.ProjGUID AND  mpv.ParamCode = 's_VATRate'  
        --        LEFT JOIN [dotnet_erp60_test_0427_old].dbo.s_SpecilRoomRate sr ON sr.RoomGuid = r.RoomGUID  
        --WHERE   r.projguid IN(SELECT    [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') );  
  
        --查询结果  
        SELECT  p.p_projectId ,  
                CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END AS 项目推广名 ,  
				pp.x_area AS 管理片区 ,  
				pp.x_ManagementSubject 管理主体 ,  
                r.RoomInfo AS 房间全名 ,  
                r.RoomGUID AS 房源唯一码 ,  
                p.ProjName AS 期数 ,  
                CASE WHEN r.TopProductTypeName IN ('住宅', '车位', '其他', '办公') THEN r.TopProductTypeName  
                     WHEN r.TopProductTypeName = '商业' AND   r.ProductTypeName = '公寓' THEN '公寓'  
                     WHEN r.TopProductTypeName = '商业' AND   r.ProductTypeName <> '公寓' THEN '商业'  
                     WHEN r.TopProductTypeName IS NULL THEN  '其他'  
                END AS 产品类型 ,  
                r.BldName AS 楼栋 ,  
                r.Floor AS 楼层 ,  
                r.Unit AS 单元号 ,  
                r.RoomNum AS 房号 ,  
                r.BldArea AS 建筑面积 ,  
                r.TnArea AS 套内面积 ,  
                r.DjBldPrice AS 底价建筑单价 ,  
                r.DjTnPrice AS 底价套内单价 ,  
                r.DjTotal AS 底价总价含税 ,  
                r.DjTotal / (1 + ISNULL(vrr.vatRate, 0)) AS 底价总价不含税 ,  
                r.DjTotal / (1 + ISNULL(vrr.vatRate, 0)) * ISNULL(vrr.vatRate, 0) AS 底价总价税额 ,  
                r.CalMode AS 计价方式 ,  
                r.BldPrice AS 标准建筑单价 ,  
                r.TnPrice AS 标准套内单价 ,  
                r.Total AS 标准总价 ,  
                ISNULL(vrr.vatRate, 0) AS 增值税率 ,  
                r.Total / (1 + ISNULL(vrr.vatRate, 0)) AS 标准总价不含税 ,  
                r.Total / (1 + ISNULL(vrr.vatRate, 0)) * ISNULL(vrr.vatRate, 0) AS 标准总价税额 ,  
                                                --  (CASE   
                                                --WHEN r.ChooseRoomLockGUID IS NOT NULL THEN '选房锁定'  
                                                --WHEN c.IsDj2AreaLock = 1 THEN '底价方案锁定'  
                                                --WHEN c.IsBzj2AreaLock = 1 THEN '标准价方案锁定'  
                                                --WHEN c.IsHfLock = 1 THEN '换房锁定'  
                                                --WHEN c.IsDjTf = 1 THEN '退房后底价确认'  
                                                --WHEN c.IsBzjTf = 1 THEN '退房后标准价确认' END)   
                CASE WHEN r.IsHfLock = 1 THEN '换房锁定'  
                     WHEN r.IsOnlineTradeLock = 1 THEN '在线交易锁定'  
                     WHEN r.IsTradeLock = 1 THEN '交易锁定'  
                     WHEN r.ChooseRoomLockGUID IS NOT NULL THEN '选房锁定'  
                     WHEN r.IsTfLock = 1 THEN '标准价退房锁定'  
                     WHEN r.BottomPriceReturnHouseLock = 1 THEN '底价退房锁定'  
                     WHEN r.IsYkkpLock = 1 THEN '开盘锁定'  
                     WHEN r.OpeningLock = 1 THEN '云客开盘锁定'  
                     WHEN r.WorkMortgageLock = 1 THEN '工抵房锁定'  
                END AS 锁定原因 ,  
                r.TradeLocker AS 锁定人 ,          --宽表新增字段  
                r.TradeLockTime AS 锁定时间 ,       --宽表新增字段  
                vrr.RoomSort AS 合作合同 ,  
                vrr.ManageStatus AS 美林保留 ,  
                r.ControlReason AS 销控原因 ,  
                r.ControlUserName AS 操作员 ,  
                r.Status AS 房间状态,  
                CASE WHEN   r.ControlType = '待售' THEN '已放盘' ELSE r.ControlType END   AS 控制类型 ,  
                r.ControlTime AS 销控时间 ,  
                r.YsBldArea AS 预测建筑面积 ,  
                r.YsTnArea AS 预测套内面积 ,  
                r.ScBldArea AS 实测建筑面积 ,  
                r.ScTnArea AS 实测套内面积 , 
                r.x_YsGardenArea AS 预售花园面积 ,  
                r.x_YsNonPropertyGardenArea AS 预售无产权花园面积 ,  
                r.x_ScGardenArea AS 实测花园面积 ,  
                r.x_ScNonPropertyGardenArea 实测无产权花园面积 ,  
                r.ProductTypeName AS 房间类型 ,  
                r.RoomStru AS 房型 ,              --宽表新增字段  
                r.HxName AS 户型 ,  
                r.Cx AS 朝向 ,  
                r.x_DecorationStatus AS 装修标准 ,  --宽表新增字段  
                ISNULL(tr.cCstAllName, tr.oCstAllName) AS 客户名称 ,  
                ISNULL(tr.cCstAllTel, tr.oCstAllTel) AS 联系电话 ,  
                --NULL AS 联系电话 ,  
                ISNULL(tr.cCstAllCardType, tr.oCstAllCardType) AS 证件类型 ,  
                ISNULL(tr.cCstAllCardID, tr.oCstAllCardID) AS 证件号 ,  
                ISNULL(tr.cAddress, oAddress) AS 联系地址 ,  
                ISNULL(tr.ORoomBldPrice,odr.ORoomBldPrice) AS 认购单价 ,  
                ISNULL(tr.OCjTotal,odr.OCjTotal) AS 认购总价 ,  
                ISNULL(tr.OQsDate,odr.OQsDate) AS 认购日期 ,  
                tr.ZcOrderDate AS 首次认购日期,  
                tr.CCjRoomBldPrice AS 合同单价 ,  
                tr.CCjTotal AS 合同总价 ,  
                tr.YqyDate AS 预计签约日期 ,  
                tr.x_YjInitialledDate AS 草签日期 , --新增字段  
				--tr.x_YjInitialledDate AS 预计草签日期,  
				tr.x_InitialledDate AS 实际草签日期,  
				tr.YqyDate AS 预计网签日期,  
				tr.CNetQsDate AS 实际网签日期,  
                --CASE WHEN tr.ContractType = '草签' THEN tr.CQsDate ELSE tr.CNetQsDate END AS 签约日期 ,  
                  
                CASE WHEN isnull(tr.x_InitialledDate,0)=0 and tr.CNetQsDate IS not null THEN  tr.CNetQsDate   
                     WHEN isnull(tr.x_InitialledDate,0)=0 and isnull(tr.CNetQsDate,0)=0 THEN NULL  
                ELSE tr.x_InitialledDate END AS 签约日期,  
                  
                r.x_YeJiTime AS 业绩认定日期 ,  
                tr.CBaDate AS 备案日期 ,tr.CBaNo,  
                tr.x_InitialledNo AS 草签合同编号,  
                tr.CAgreementNo AS 合同编号 ,  
                tr.YjfDate AS 预计交房日期 ,tr.SjjfDate AS 实际交房日期,  
                --ISNULL(OPayForm, CPayForm) AS 付款方式 ,  
                --ISNULL(OAjBank, CAjBank) AS 按揭银行 ,  
				--ISNULL(OAjTotal, CAjTotal) AS 按揭贷款金额 ,  
				ISNULL(CAjTotal,OAjTotal ) AS 按揭贷款金额 , 
				ISNULL(SsAj,0.00) as 按揭放款金额, 
				ISNULL(CGjjTotal,OGjjTotal ) AS 公积金贷款金额 ,  
				ISNULL(ssgjj,0.00) as 公积金放款金额,
				CASE  WHEN  ISNULL(CPayForm,'') <>'' THEN CPayForm ELSE  OPayForm END AS 付款方式 ,  
				CASE  WHEN  ISNULL(CAjBank,'') <>'' THEN CAjBank ELSE  OAjBank END AS 按揭银行 ,  
                tr.AjfkDate AS 按揭放款日期 ,  
                tr.GjjfkDate AS 公积金放款日期 ,  
                ISNULL(tr.CDiscount, tr.ODiscount) AS 合计折扣 ,  
                ISNULL(tr.cDiscountRemark, tr.oDiscountRemark) AS 折扣说明 ,  
                ISNULL(tr.CCjTotal, tr.OCjTotal) AS 成交总价 ,
                ISNULL(tr.CBcxyTotal, tr.OBcxyTotal) AS 补充协议金额 ,  
                ISNULL(YSBCXY.YSBCXYRmbAmount,0) AS 应收补充协议金额,
                --ISNULL(tr.Ssfk, 0) AS 已收房款 ,  
                ISNULL(gg.getRmbAmount,0) AS 已收房款 , 
                ISNULL(ggbcxy.bcxyje,0) AS 已收补充协议金额, 
                ISNULL(tr.YsDj, 0) AS 定金应收金额 ,  
                ISNULL(tr.SsDj, 0) AS 定金实收金额 ,  
                p2.RmbAmount AS 首期应付金额 ,  
                p2.RmbYe AS 首期余额 ,  
                p2.RmbDsAmount AS 首期多收 ,  
                p2.lastDate AS 首期应付日期 ,  
                CASE WHEN p2.RmbAmount IS NULL THEN '' ELSE CASE WHEN p2.RmbYe = 0 THEN '是' ELSE '否' END END AS 首期是否付清 , 
			    ss2.je As 首期实收金额,
			    ss2.rq AS 首期实收日期,
                p3.RmbAmount AS 二期应付金额 ,  
                p3.RmbYe AS 二期余额 ,  
                p3.RmbDsAmount AS 二期多收 ,  
                p3.lastDate AS 二期应付日期 ,  
                CASE WHEN p3.RmbAmount IS NULL THEN '' ELSE CASE WHEN p3.RmbYe = 0 THEN '是' ELSE '否' END END AS 二期是否付清 ,  
			   ss3.je AS 二期实收金额,
			   ss3.rq AS 二期实收日期,
                p4.RmbAmount AS 三期应付金额 ,  
                p4.RmbYe AS 三期余额 ,  
                p4.RmbDsAmount AS 三期多收 ,  
                p4.lastDate AS 三期应付日期 , 
                 
                p5.RmbAmount AS 维修基金应付金额 ,  
                p5.RmbYe AS 维修基金余额 ,  
                p5.RmbDsAmount AS 维修基金多收 ,  
                p5.lastDate AS 维修基金应付日期 ,  
                CASE WHEN p4.RmbAmount IS NULL THEN '' ELSE CASE WHEN p4.RmbYe = 0 THEN '是' ELSE '否' END END AS 三期是否付清 ,  
			   ss4.je 三期实收金额,
			   ss4.rq 三期实收日期,
                CASE WHEN r.Status = '认购' AND   tr.YqyDate < GETDATE() THEN '是' ELSE '否' END AS 签约是否超期 ,  
                r.Bcfa AS 补差方案 ,  
                ISNULL(tr.BcTotal, 0) + ISNULL(tr.FsBcTotal, 0) AS 实际补差人民币 ,  
                --ISNULL(tr.BcAfterCTotal, 0) AS 面积补差后实际成交金额 ,  
                ISNULL(ISNULL(tr.CCjTotal, tr.OCjTotal), 0)+ISNULL(tr.BcTotal, 0) + ISNULL(tr.FsBcTotal, 0) as 面积补差后实际成交金额,  
				case when (ISNULL(tr.CCjTotal, tr.OCjTotal) >0 
				AND ISNULL(ISNULL(tr.CCjTotal, tr.OCjTotal), 0)+ISNULL(tr.BcTotal, 0) + 
				ISNULL(tr.FsBcTotal, 0)-ISNULL(gg.getRmbAmount,0)=0 ) 
				then '已收齐' else '' end as 是否已收齐房款,  
				case when ISNULL(gg.getRmbAmount,0)-ISNULL(bcg.getRmbAmount,0) - 
				ISNULL(tr.CCjTotal, tr.OCjTotal) = 0 
				then '已收齐' else '' end as 不含补差房款是否已收齐,  
				case WHEN ISNULL(gg.getRmbAmount,0) >=  ISNULL (YS.YSRmbAmount,0) 
				AND ISNULL (YS.YSRmbAmount,0) !=0  THEN '已收齐' ELSE '' END AS 房款是否收齐,  
				case WHEN ISNULL(bcg.getRmbAmount,0) >= ISNULL(buchaYS.bcYS,0) 
				AND  ISNULL(buchaYS.bcYS,0) !=0   THEN '已收齐' ELSE '' END AS 补差是否已收齐,  
				ISNULL(bcg.getRmbAmount,0) AS 实收补差款,  
                r.ExecName AS 补差经办人 ,  
                tr.BcExeTime AS 补差经办时间 ,  
                tr.AjServiceProc AS 按揭贷款服务进程 ,  
                tr.RhServiceProc AS 入伙服务进程 ,  
                tr.RhCompleteDate AS 入伙确认时间 ,  
                tr.HtCarryoverDate AS 首次结转收入日期 ,  
                tr.CqServiceProc AS 产权服务进程 ,  
                tr.HtdjServiceProc AS 合同登记服务进程 ,  
                tr.MainMediaName AS 媒体大类 ,  
                tr.SubMediaName AS 媒体子类 ,  
                ISNULL(tr.CZygw, tr.OZygw) AS 销售顾问 ,  
                ISNULL(tr.x_CSalesLeader, tr.x_OSalesLeader) AS 销售组长 ,  
                isnull(ISNULL(tr.CProjectTeam, tr.OProjectTeam),
                      ( SELECT STUFF(  
						  (   SELECT DISTINCT ',' + CONVERT(VARCHAR(200), ptu.ProjTeamName)  
						   FROM   data_wide_s_ProjectTeamUser ptu      
						   WHERE ( ptu.ProjGUID =p.p_projectId OR ptu.ProjGUID =pp.p_projectId)  AND    
						   CHARINDEX(LOWER(CONVERT(VARCHAR(50),ptu.UserGUID )) ,
						   LOWER(ISNULL(tr.CZygwAllGUID, tr.OZygwAllGUID)) ) >0  
						   FOR XML PATH('')) ,   
					  1 ,  
					  1 ,  
					  ''))) AS 团队 ,  
               --  ISNULL(tr.x_CAgentLeader, tr.x_OAgentLeader) AS 团队 ,  
                ISNULL(tr.x_CCstAttributes, tr.x_OCstAttributes) AS 客户属性 ,  
                tr.Gfyt AS 购房用途 ,  
                tr.Homearea AS 居住区域 ,  
                tr.AgeStage AS 年龄段,
                tr.ccjbldarea as 合同单面积,
                tr.ocjbldarea as 认购单面积
        FROM    dbo.data_wide_mdm_Project p WITH (NOLOCK )  
                INNER JOIN data_wide_mdm_Project pp WITH (NOLOCK ) 
                ON p.ParentGUID = pp.p_projectId AND pp.Level = 2  
                INNER JOIN data_wide_s_Room r WITH (NOLOCK ) ON p.p_projectId = r.ProjGUID  
                -- LEFT JOIN p_hhyroom x ON x.RoomGUID = r.RoomGUID  
                LEFT JOIN data_wide_dws_s_roomexpand vrr WITH (NOLOCK ) ON vrr.RoomGUID = r.RoomGUID  
                --LEFT JOIN  data_wide_s_SaleHsData  shd on  Status = '激活' shd ON   shd.RoomGUID =r.RoomGUID  
                LEFT JOIN data_wide_s_Trade tr  WITH (NOLOCK )  ON tr.RoomGUID = r.RoomGUID AND tr.TradeStatus = '激活' AND   tr.IsLast = 1  
    -- 草签转网签的合同wideguid会丢失  
    OUTER APPLY (  
       SELECT TOP 1 otr.OCjTotal,otr.ORoomBldPrice,otr.OQsDate 
       FROM   data_wide_s_Trade otr   
       WHERE  tr.TradeGUID =otr.TradeGUID AND tr.RoomGUID =otr.RoomGUID 
       AND  otr.CAddReason ='认购转签约'  -- AND otr.ContractType ='草签'  
       AND otr.OQsDate IS NOT NULL    
       ORDER BY  otr.OQsDate DESC   
    ) odr 
    --实收房款金额 
    LEFT JOIN  (  
       SELECT g.SaleGUID, SUM(ISNULL( g.RmbAmount,0)) AS  getRmbAmount
       FROM  dbo.data_wide_s_Getin g   
       WHERE  g.VouchStatus <> '作废' AND g.ItemType IN ('贷款类房款','非贷款类房款','补充协议款')   
       GROUP BY g.SaleGUID  
    )gg ON gg.SaleGUID =tr.TradeGUID 
    --实收补充协议款20241030 
     LEFT JOIN  (  
       SELECT g.SaleGUID, SUM(ISNULL( g.RmbAmount,0)) AS bcxyje  
       FROM  dbo.data_wide_s_Getin g   
       WHERE  g.VouchStatus <> '作废' AND g.ItemType IN ('补充协议款')   
       GROUP BY g.SaleGUID  
    )ggbcxy ON ggbcxy.SaleGUID =tr.TradeGUID  
    --应收房款金额  
     LEFT JOIN(SELECT   TradeGUID , SUM(ISNULL(  RmbAmount ,0)) AS YSRmbAmount  
                          FROM  data_wide_s_Fee WITH (NOLOCK )  
        WHERE ItemType IN ('贷款类房款','非贷款类房款','补充协议款')  GROUP BY TradeGUID ) AS YS ON YS.TradeGUID = tr.TradeGUID   
        --应收补充协议款20241030  
     LEFT JOIN(SELECT   TradeGUID , SUM(ISNULL(  RmbAmount ,0)) AS YSBCXYRmbAmount  
                          FROM  data_wide_s_Fee WITH (NOLOCK )  
        WHERE ItemType IN ('补充协议款')  GROUP BY TradeGUID ) AS YSBCXY ON YSBCXY.TradeGUID = tr.TradeGUID 
    --应收补差金额  
     LEFT JOIN(SELECT   TradeGUID , SUM(ISNULL(  RmbAmount ,0)) AS bcYS  
                          FROM  data_wide_s_Fee WITH (NOLOCK )  
        WHERE ItemType = '非贷款类房款' AND  ItemName like '%补差%'  GROUP BY TradeGUID ) AS buchaYS ON buchaYS.TradeGUID = tr.TradeGUID   
    --补差实收金额  
    LEFT JOIN  (  
       SELECT g.SaleGUID, SUM(ISNULL( g.RmbAmount,0)) AS  getRmbAmount  
       FROM  dbo.data_wide_s_Getin g   
       WHERE  g.VouchStatus <> '作废' AND g.ItemType IN ('非贷款类房款') AND IsFk = 1 AND ItemName like '%补差%'  
       GROUP BY g.SaleGUID  
    )bcg ON bcg.SaleGUID =tr.TradeGUID  
  LEFT JOIN(SELECT  ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row ,  
                    FeeGUID ,  
                    TradeGUID ,  
                    Sequence ,  
                    ItemType ,  
                    ItemName ,  
                    lastDate ,  
                    RmbAmount ,  
                    RmbYe ,  
                    RmbDsAmount  
  FROM  data_wide_s_Fee WITH (NOLOCK )  
  WHERE ItemType = '非贷款类房款' AND ItemName <> '定金') AS p2 ON p2.TradeGUID = tr.TradeGUID AND p2.row = 1  
                LEFT JOIN(SELECT    ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row ,  
                                    FeeGUID ,  
                                    TradeGUID ,  
                                    Sequence ,  
                                    ItemType ,  
                                    ItemName ,  
                                    lastDate ,  
                                    RmbAmount ,  
                                    RmbYe ,  
                                    RmbDsAmount  
                          FROM  data_wide_s_Fee WITH (NOLOCK )  
                          WHERE ItemType = '非贷款类房款' AND ItemName <> '定金') AS p3 ON p3.TradeGUID = tr.TradeGUID AND p3.row = 2  
                LEFT JOIN(SELECT    ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row ,  
                                    FeeGUID ,  
                                    TradeGUID ,  
                                    Sequence ,  
                                    ItemType ,  
                                    ItemName ,  
                                    lastDate ,  
                                    RmbAmount ,  
                                    RmbYe ,  
                                    RmbDsAmount   
                          FROM  data_wide_s_Fee WITH (NOLOCK )  
                          WHERE ItemType = '非贷款类房款' AND ItemName <> '定金') AS p4 ON p4.TradeGUID = tr.TradeGUID AND p4.row = 3  
     LEFT JOIN(SELECT    
                                    TradeGUID ,  
                                    MAX(lastDate) AS lastDate ,  
                                    SUM(ISNULL(RmbAmount,0)) AS RmbAmount  ,  
                                    SUM(ISNULL(RmbYe,0) ) AS  RmbYe ,  
                                    SUM(ISNULL(RmbDsAmount,0) ) AS RmbDsAmount  
                          FROM  data_wide_s_Fee WITH (NOLOCK )  
                          WHERE ItemType = '代收费用' AND ItemName like '%维修%'  
         GROUP BY  TradeGUID  
        ) AS p5 ON p5.TradeGUID = tr.TradeGUID  
 --新增实收金额和实收日期20241030       
left join 
(  SELECT    
    SaleGUID ,
    ItemName,
    SUM(RmbAmount) je,
    case when SUM(RmbAmount)>0 then max(SkDate) end rq    
FROM  data_wide_s_Getin WITH (NOLOCK )  
WHERE  VouchStatus='激活' 
GROUP BY  SaleGUID , ItemName )ss2 on ss2.SaleGUID=tr.TradeGUID and ss2.ItemName=p2.ItemName
left join 
(  SELECT    
    SaleGUID ,
    ItemName,
    SUM(RmbAmount) je,
    case when SUM(RmbAmount)>0 then max(SkDate) end rq    
FROM  data_wide_s_Getin WITH (NOLOCK )  
WHERE  VouchStatus='激活' 
GROUP BY  SaleGUID , ItemName )ss3 on ss3.SaleGUID=tr.TradeGUID and ss3.ItemName=p3.ItemName
left join 
(  SELECT    
    SaleGUID ,
    ItemName,
    SUM(RmbAmount) je,
    case when SUM(RmbAmount)>0 then max(SkDate) end rq    
FROM  data_wide_s_Getin WITH (NOLOCK )  
WHERE  VouchStatus='激活' 
GROUP BY  SaleGUID , ItemName )ss4 on ss4.SaleGUID=tr.TradeGUID and ss4.ItemName=p4.ItemName
  WHERE   
   p.p_projectId IN(SELECT [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') ) 
                AND (CASE WHEN r.TopProductTypeName IN ('住宅', '车位', '其他', '办公') THEN r.TopProductTypeName  
                          WHEN r.TopProductTypeName = '商业' AND  r.ProductTypeName = '公寓' THEN '公寓'  
                          WHEN r.TopProductTypeName = '商业' AND  r.ProductTypeName <> '公寓' THEN '商业'  
           WHEN r.TopProductTypeName IS NULL THEN  '其他'  
                     END) IN (SELECT  value FROM  dbo.fn_Split1(@ProductType, ',') );  
  
  

END;
ELSE 
		BEGIN 
	select 
    SnapshotTime
    ,VersionNo
    ,BUGUID
    ,ProjGUID
    ,ProductType
    ,p_projectId
    ,项目推广名
    ,管理片区
    ,管理主体
    ,房间全名
    ,房源唯一码
    ,期数
    ,产品类型
    ,楼栋
    ,楼层
    ,单元号
    ,房号
    ,建筑面积
    ,套内面积
    ,底价建筑单价
    ,底价套内单价
    ,底价总价含税
    ,底价总价不含税
    ,底价总价税额
    ,计价方式
    ,标准建筑单价
    ,标准套内单价
    ,标准总价
    ,增值税率
    ,标准总价不含税
    ,标准总价税额
    ,锁定原因
    ,锁定人
    ,锁定时间
    ,合作合同
    ,美林保留
    ,销控原因
    ,操作员
    ,房间状态
    ,控制类型
    ,销控时间
    ,预测建筑面积
    ,预测套内面积
    ,实测建筑面积
    ,实测套内面积
    ,预售花园面积
    ,预售无产权花园面积
    ,实测花园面积
    ,实测无产权花园面积
    ,房间类型
    ,房型
    ,户型
    ,朝向
    ,装修标准
    ,客户名称
    ,联系电话
    ,证件类型
    ,证件号
    ,联系地址
    ,认购单价
    ,认购总价
    ,认购日期
    ,首次认购日期
    ,合同单价
    ,合同总价
    ,预计签约日期
    ,草签日期
    ,实际草签日期
    ,预计网签日期
    ,实际网签日期
    ,签约日期
    ,业绩认定日期
    ,备案日期
    ,CBaNo
    ,草签合同编号
    ,合同编号
    ,预计交房日期
    ,实际交房日期
    ,按揭贷款金额
    ,按揭放款金额
    ,公积金贷款金额
    ,公积金放款金额
    ,付款方式
    ,按揭银行
    ,按揭放款日期
    ,公积金放款日期
    ,合计折扣
    ,折扣说明
    ,成交总价
    ,补充协议金额
    ,应收补充协议金额
    ,已收房款
    ,已收补充协议金额
    ,定金应收金额
    ,定金实收金额
    ,首期应付金额
    ,首期余额
    ,首期多收
    ,首期应付日期
    ,首期是否付清
    ,首期实收金额
    ,首期实收日期
    ,二期应付金额
    ,二期余额
    ,二期多收
    ,二期应付日期
    ,二期是否付清
    ,二期实收金额
    ,二期实收日期
    ,三期应付金额
    ,三期余额
    ,三期多收
    ,三期应付日期
    ,维修基金应付金额
    ,维修基金余额
    ,维修基金多收
    ,维修基金应付日期
    ,三期是否付清
    ,三期实收金额
    ,三期实收日期
    ,签约是否超期
    ,补差方案
    ,实际补差人民币
    ,面积补差后实际成交金额
    ,是否已收齐房款
    ,不含补差房款是否已收齐
    ,房款是否收齐
    ,补差是否已收齐
    ,实收补差款
    ,补差经办人
    ,补差经办时间
    ,按揭贷款服务进程
    ,入伙服务进程
    ,入伙确认时间
    ,首次结转收入日期
    ,产权服务进程
    ,合同登记服务进程
    ,媒体大类
    ,媒体子类
    ,销售顾问
    ,销售组长
    ,团队
    ,客户属性
    ,购房用途
    ,居住区域
    ,年龄段
    ,合同单面积
    ,认购单面积
from Result_RoomLedgerDetail 
where 
    VersionNo = @BBH
   and ProjGUID IN (SELECT [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') )
        and ProductType IN (SELECT  value FROM  dbo.fn_Split1(@ProductType, ',') );
		END;
END;  
