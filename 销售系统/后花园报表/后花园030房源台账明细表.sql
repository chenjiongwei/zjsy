USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_RoomDetailsInfoByHhy]    Script Date: 2025/2/25 14:29:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER    PROC [dbo].[usp_rpt_s_RoomDetailsInfoByHhy](
@ProjGUID VARCHAR(MAX)       --项目分期GUID
--@SDate DATETIME ,          --签约日期开始日期
--@EDate DATETIME            --签约日期截止日期
)
AS
/*
后花园房间明细表
*/
    BEGIN

        --查询结果
        SELECT  p.p_projectId ,
                CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END AS 项目推广名 ,
				pp.ProjName AS  项目名称,
				p.ProjShortName AS 团队名称,
				pp.x_area AS 管理片区 ,
				pp.x_ManagementSubject 管理主体 ,
                r.RoomInfo AS 房间全名 ,
                r.RoomGUID AS 房源唯一码 ,
                --p.ProjName AS 期数 ,
                CASE WHEN r.TopProductTypeName IN ('住宅', '车位', '其他', '办公') THEN r.TopProductTypeName
                     WHEN r.TopProductTypeName = '商业' AND   r.ProductTypeName = '公寓' THEN '公寓'
                     WHEN r.TopProductTypeName = '商业' AND   r.ProductTypeName <> '公寓' THEN '商业'
					 WHEN r.TopProductTypeName IS NULL THEN  '其他'
                END AS 产品类型 ,
                r.BldName AS 楼栋 ,
                r.Floor AS 楼层 ,
                r.no AS 单元号 ,
				--SUBSTRING(  r.RoomNum,LEN(r.Floor) + 1, LEN(r.RoomNum) )  AS 单元号 ,  -- 单元号取房号除去楼层号
                r.RoomNum AS 房号 ,
                r.BldArea AS 建筑面积 ,
                r.TnArea AS 套内面积 ,
                r.DjBldPrice AS 底价建筑单价 ,
                r.DjTnPrice AS 底价套内单价 ,
                r.DjTotal AS 底价总价含税 ,
                r.DjTotal / (1 + ISNULL(vrr.vatRate, 0)) AS 底价总价不含税 ,
                r.DjTotal / (1 + ISNULL(vrr.vatRate, 0)) * ISNULL(vrr.vatRate, 0) AS 底价总价税额 ,
				NULL AS  抵押状态,
				NULL AS 是否锁定,
                r.CalMode AS 计价方式 ,
                r.BldPrice AS 标准建筑单价 ,
                r.TnPrice AS 标准套内单价 ,
                r.Total AS 标准总价 ,
                ISNULL(vrr.vatRate, 0) AS 增值税率 ,
                r.Total / (1 + ISNULL(vrr.vatRate, 0)) AS 标准总价不含税 ,
                r.Total / (1 + ISNULL(vrr.vatRate, 0)) * ISNULL(vrr.vatRate, 0) AS 标准总价税额 ,
                --		(CASE 
                --WHEN r.ChooseRoomLockGUID IS NOT NULL THEN '选房锁定'
                --WHEN c.IsDj2AreaLock = 1 THEN '底价方案锁定'
                --WHEN c.IsBzj2AreaLock = 1 THEN '标准价方案锁定'
                --WHEN c.IsHfLock = 1 THEN '换房锁定'
                --WHEN c.IsDjTf = 1 THEN '退房后底价确认'
                --WHEN c.IsBzjTf = 1 THEN '退房后标准价确认' END) 
                NULL AS 锁定原因 ,
                NULL AS 锁定人 ,          --宽表新增字段
                NULL AS 锁定时间 ,       --宽表新增字段
                vrr.RoomSort AS 合作合同 ,
                vrr.ManageStatus AS 美林保留 ,
                NULL AS 销控原因 ,
                NULL AS 操作员 ,
				r.Status AS  房源状态,
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
                CASE WHEN   ISNULL(bld.ProductTypeName,'') ='高层' THEN  '洋房'  ELSE    ISNULL( bld.ProductTypeName,'' ) END  AS 房间类型 ,
                r.RoomStru AS 房型 ,              --宽表新增字段
                r.HxName AS 户型 ,
                r.Cx AS 朝向 ,
                r.x_DecorationStatus AS 装修标准 ,  --宽表新增字段
                ISNULL(tr.CCstAllName,tr.OCstAllName) AS 客户名称 ,
                --ISNULL(tr.OCstAllTel, tr.CCstAllTel) AS 联系电话 ,
				NULL  AS 联系电话 ,
                ISNULL(tr.CCstAllCardType,tr.OCstAllCardType ) AS 证件类型 ,
                ISNULL( tr.CCstAllCardID,tr.OCstAllCardID) AS 证件号 ,
                ISNULL(tr.CAddress,tr.OAddress ) AS 联系地址 ,

                --ISNULL(tr.OCjRoomBldPrice,odr.OCjRoomBldPrice) AS 认购单价 ,
                --ISNULL(tr.OCjTotal,odr.OCjTotal) AS 认购总价 ,
				--ISNULL(tr.OQsDate,odr.OQsDate)  AS   认购日期,
				ISNULL(ISNULL(tr.OCjRoomBldPrice,odr.OCjRoomBldPrice),sco.CjBldPrice) AS 认购单价 ,
				ISNULL(ISNULL(tr.OCjTotal,odr.OCjTotal),sco.CjRmbTotal) AS 认购总价 ,
				ISNULL(ISNULL(ISNULL(tr.OQsDate,odr.OQsDate),sco.QSDate),tr.ZcOrderDate)  AS   认购日期,
                --ISNULL(tr.OYjgsDate,odr.OYjgsDate)  AS 系统认购日期 , -- 取业绩归属日期
				ISNULL(ISNULL(tr.OYjgsDate,odr.OYjgsDate),sco.YwgsDate)  AS 系统认购日期 , -- 取业绩归属日期

                tr.CCjRoomBldPrice AS 合同单价 ,
                tr.CCjTotal AS 合同总价 ,
                tr.YqyDate AS 预计签约日期 ,

                CASE WHEN tr.x_InitialledDate IS NOT NULL  THEN tr.x_InitialledDate ELSE tr.CNetQsDate END AS 签约日期 ,
                r.x_YeJiTime AS 业绩认定日期 ,
                tr.CBaDate AS 备案日期 ,
                tr.CAgreementNo AS 合同编号 ,
                tr.YjfDate AS 预计交房日期 ,
                --ISNULL(OPayForm, CPayForm) AS 付款方式 ,
                --ISNULL(OAjBank, CAjBank) AS 按揭银行 ,
                ISNULL(CAjTotal,OAjTotal ) AS 按揭贷款金额 ,
				CASE  WHEN  ISNULL(CPayForm,'') <>'' THEN CPayForm ELSE  OPayForm END AS 付款方式 ,
				CASE  WHEN  ISNULL(CAjBank,'') <>'' THEN CAjBank ELSE  OAjBank END AS 按揭银行 ,
                tr.AjfkDate AS 按揭放款日期 ,
                tr.GjjfkDate AS 公积金放款日期 ,
                CASE WHEN  ISNULL(tr.CDiscount, tr.ODiscount) IS  NOT NULL THEN  
			    CONVERT(VARCHAR(20),CONVERT( DECIMAL(18,2),ISNULL(tr.CDiscount, tr.ODiscount)) ) + '%' END AS 合计折扣 ,
                ISNULL(tr.ODiscountRemark, tr.CDiscountRemark) AS 折扣说明 ,
                ISNULL(tr.CCjTotal, tr.OCjTotal) AS 成交总价 ,
                --ISNULL(tr.Ssfk, 0) AS 已收房款 ,
				ISNULL(gg.getRmbAmount,0) AS 已收房款 ,
                ISNULL(tr.YsDj, 0) AS 定金应收金额 ,
                ISNULL(tr.SsDj, 0) AS 定金实收金额 ,
                p2.RmbAmount AS 首期应付金额 ,
                p2.RmbYe AS 首期余额 ,
                p2.RmbDsAmount AS 首期多收 ,
                p2.lastDate AS 首期应付日期 ,
                CASE WHEN p2.RmbAmount IS NULL THEN '' ELSE CASE WHEN p2.RmbYe = 0 THEN '是' ELSE '否' END END AS 首期是否付清 ,
                p3.RmbAmount AS 二期应付金额 ,
                p3.RmbYe AS 二期余额 ,
                p3.RmbDsAmount AS 二期多收 ,
                p3.lastDate AS 二期应付日期 ,
                CASE WHEN p3.RmbAmount IS NULL THEN '' ELSE CASE WHEN p3.RmbYe = 0 THEN '是' ELSE '否' END END AS 二期是否付清 ,
                p4.RmbAmount AS 三期应付金额 ,
                p4.RmbYe AS 三期余额 ,
                p4.RmbDsAmount AS 三期多收 ,
                p4.lastDate AS 三期应付日期 ,
				p5.RmbAmount AS 维修基金应付金额 ,
                p5.RmbYe AS 维修基金余额 ,
                p5.RmbDsAmount AS 维修基金多收 ,
                p5.lastDate AS 维修基金应付日期 ,
                CASE WHEN p4.RmbAmount IS NULL THEN '' ELSE CASE WHEN p4.RmbYe = 0 THEN '是' ELSE '否' END END AS 三期是否付清 ,
                CASE WHEN r.Status = '认购' AND   tr.YqyDate < GETDATE() THEN '是' ELSE '否' END AS 签约是否超期 ,
                r.Bcfa AS 补差方案 ,
                ISNULL(tr.BcTotal, 0) + ISNULL(tr.FsBcTotal, 0) AS 实际补差人民币 ,
                ISNULL(tr.BcAfterCTotal, 0) AS 面积补差后实际成交金额 ,
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
				tr.x_Referrer AS 推荐人,
				tr.x_CustomerFirstVisitDate AS 客户首访日期,
                ISNULL(tr.CZygw, tr.OZygw) AS 销售顾问 ,
                ISNULL(tr.x_CSalesLeader, tr.x_OSalesLeader) AS 销售组长 ,
				ISNULL(ISNULL(tr.CProjectTeam, tr.OProjectTeam),( SELECT STUFF(
						(   SELECT DISTINCT ',' + CONVERT(VARCHAR(200), ptu.ProjTeamName)
							FROM   data_wide_s_ProjectTeamUser ptu    
							WHERE ( ptu.ProjGUID =p.p_projectId OR ptu.ProjGUID =pp.p_projectId)  AND    CHARINDEX(LOWER(CONVERT(VARCHAR(50),ptu.UserGUID )) ,LOWER(ISNULL(tr.CZygwAllGUID, tr.OZygwAllGUID)) ) >0
							FOR XML PATH('')) ,
						1 ,
						1 ,
						''))) AS 团队 ,
                ISNULL(tr.x_CAgentLeader, tr.x_OAgentLeader) AS 销售代理组长 ,
                ISNULL(tr.x_CCstAttributes, tr.x_OCstAttributes) AS 客户属性 ,
                tr.Gfyt AS 购房用途 ,
                tr.Homearea AS 居住区域 ,
                tr.AgeStage AS 年龄段,
				NULL AS  是否样板房,	  
				ISNULL(tr.CCjZxTotal,tr.OCjZxTotal) AS  装修总价,	
				NULL AS  土地使用年限,	
				r.x_YuanQu AS  苑区,
				r.RecordNumber AS  备案号,	
				r.x_PreparedPrice AS  备案价,	
                tr.x_YjInitialledDate AS 预计草签日期 , --新增字段
				--tr.x_YjInitialledDate AS 预计草签日期,
				tr.x_InitialledDate AS 实际草签日期,
				ISNULL(tr.x_InitialledDate,tr.x_YjInitialledDate )  AS 草签日期,  --有实际取实际没有取预计
				tr.YqyDate AS 预计网签日期,
				tr.CNetQsDate AS 实际网签日期,
				ISNULL(tr.CNetQsDate, tr.YqyDate) AS  网签日期, --有实际取实际没有取预计
				CASE WHEN tr.ContractType ='网签' AND  sfcq.TradeGUID IS NULL THEN  '是' ELSE  '否' END   AS  是否直接网签,	
				CASE WHEN tr.CStatus = '激活' AND tr.ContractType = '网签' THEN '网签' 
				     WHEN tr.CStatus = '激活' AND tr.ContractType = '草签' THEN '草签' 
					 WHEN r.Status ='认购' THEN  '认购' END AS  合同性质,	
				ISNULL(tr.CTradeJYJC,tr.OTradeJYJC) AS  交易进程,
				ISNULL(tr.CBcxyRemark, tr.OBcxyRemark) AS  附加条件
        FROM    dbo.data_wide_mdm_Project p WITH (NOLOCK )
                INNER JOIN data_wide_mdm_Project pp WITH (NOLOCK ) ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
                INNER JOIN data_wide_s_Room r WITH (NOLOCK ) ON p.p_projectId = r.ProjGUID
				INNER JOIN dbo.data_wide_mdm_building  bld WITH (NOLOCK )  ON bld.BuildingGUID =r.MasterBldGUID
                LEFT JOIN data_wide_dws_s_roomexpand vrr WITH (NOLOCK ) ON vrr.RoomGUID = r.RoomGUID
                --LEFT JOIN  data_wide_s_SaleHsData  shd on  Status = '激活' shd ON   shd.RoomGUID =r.RoomGUID
                LEFT JOIN data_wide_s_Trade tr  WITH (NOLOCK ) ON tr.RoomGUID = r.RoomGUID AND tr.TradeStatus = '激活' AND   tr.IsLast = 1
			   OUTER APPLY (
			       SELECT TOP 1  tr1.TradeGUID, tr1.CQsDate FROM  data_wide_s_Trade tr1 WHERE  tr1.ContractType ='草签' AND tr1.RoomGUID =tr.RoomGUID AND tr1.TradeGUID =tr.TradeGUID
				   ORDER BY  tr.CQsDate DESC 
			   ) sfcq
				-- 草签转网签的合同wideguid会丢失
				OUTER APPLY (
				   SELECT TOP 1 otr.OCjTotal,otr.OCjRoomBldPrice,otr.OQsDate,otr.OYjgsDate
				   FROM   data_wide_s_Trade otr 
				   WHERE  tr.TradeGUID =otr.TradeGUID AND tr.RoomGUID =otr.RoomGUID AND  otr.OCloseReason ='转签约'  -- AND otr.ContractType ='草签'
				   AND otr.OQsDate IS NOT NULL  
				   ORDER BY  otr.OQsDate DESC 
				) odr

				--签约换房要找回原来的签约
				LEFT JOIN dotnet_erp60.dbo.s_Trade st ON tr.ZcContractGUID = st.ContractGUID
				LEFT JOIN dotnet_erp60.dbo.s_trade hf on st.pretradeguid=hf.tradeguid
				LEFT JOIN dotnet_erp60.dbo.s_Order sco ON hf.ZcOrderGUID = sco.OrderGUID

				LEFT JOIN  (
				   SELECT g.SaleGUID, SUM(ISNULL( g.RmbAmount,0)) AS  getRmbAmount
				   FROM  dbo.data_wide_s_Getin g 
				   WHERE  g.VouchStatus <> '作废' AND g.ItemType IN ('贷款类房款','非贷款类房款') 
				   GROUP BY g.SaleGUID
				)gg ON gg.SaleGUID =tr.TradeGUID
                LEFT JOIN(SELECT    ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row ,
                                    FeeGUID ,
                                    TradeGUID ,
                                    Sequence ,
                                    ItemType ,
                                    ItemName ,
                                    -- Flag ,
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
                                    -- Flag ,
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
                                    --  Flag ,
                                    lastDate ,
                                    RmbAmount ,
                                    RmbYe ,
                                    RmbDsAmount 
                          FROM  data_wide_s_Fee WITH (NOLOCK )
                          WHERE ItemType = '非贷款类房款' AND ItemName <> '定金') AS p4 ON p4.TradeGUID = tr.TradeGUID AND p4.row = 3
				 LEFT JOIN(SELECT   -- ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row ,
                                    -- FeeGUID ,
                                    TradeGUID ,
                                    --Sequence ,
                                    --ItemType ,
                                    --ItemName ,
                                    ---- Flag ,
                                    MAX(lastDate) AS lastDate ,
                                    SUM(ISNULL(RmbAmount,0)) AS RmbAmount  ,
                                    SUM(ISNULL(RmbYe,0) ) AS  RmbYe ,
                                    SUM(ISNULL(RmbDsAmount,0) ) AS RmbDsAmount
                          FROM  data_wide_s_Fee WITH (NOLOCK )
                          WHERE ItemType = '代收费用' AND ItemName LIKE '%维修%'
						   GROUP BY  TradeGUID
						  ) AS p5 ON p5.TradeGUID = tr.TradeGUID
        WHERE   p.p_projectId IN(SELECT [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') ) 
		AND  r.BUName LIKE  '%后花园%'
		AND  r.BldArea <> '1' AND r.DjTotal > 0
		--AND ( ( CASE WHEN tr.x_InitialledDate IS NOT NULL  THEN tr.x_InitialledDate ELSE tr.CNetQsDate END  )
		--BETWEEN @SDate AND @EDate )
        order by   r.RoomInfo

    END;


