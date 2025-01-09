-- 11本年合同回款率分析
-- 2025-01-08 调整收款日期的取数口径

USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_getAmountRateInfo]    Script Date: 2025/1/9 15:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--本年合同回款率分析
--EXEC [usp_rpt_s_getAmountRateInfo] '06F81A81-8ECF-E911-8A8E-40F2E92B3FDA'
ALTER PROC [dbo].[usp_rpt_s_getAmountRateInfo](
        @ProjGUID VARCHAR(MAX), -- 一级项目GUID
        @TjDate datetime -- 统计日期
        ) 
AS
    BEGIN
        SELECT  bu.BUName AS 公司 ,
                pp.p_projectId ,
                CASE WHEN ISNULL(pp.SpreadName, '') <> '' THEN ISNULL(pp.SpreadName, '')ELSE pp.ProjName END AS 项目 ,
                CASE WHEN bld.TopProductTypeName IN ('住宅', '车位', '其他', '办公') THEN bld.TopProductTypeName
                     WHEN bld.TopProductTypeName = '商业' AND  bld.ProductTypeName = '公寓' THEN '公寓'
                     WHEN bld.TopProductTypeName = '商业' AND  bld.ProductTypeName <> '公寓' THEN '商业'
					 WHEN bld.TopProductTypeName IS NULL THEN  '其他'
                END AS 业态 ,
                SUM(ISNULL(gg.BnRmbAmount, 0)) / 10000.0 AS 当年签约当年回款 ,
                SUM(ISNULL(tr.CCjRoomTotal, 0)) / 10000.0 AS 本年合约销售额 ,
                CASE WHEN SUM(ISNULL(tr.CCjRoomTotal, 0)) = 0 THEN 0 ELSE SUM(ISNULL(gg.BnRmbAmount, 0)) / SUM(ISNULL(tr.CCjRoomTotal, 0)) END AS 当年签约回款率
        FROM    data_wide_mdm_Project pp
                INNER JOIN dbo.data_wide_s_Room r ON r.ParentProjGUID = pp.p_projectId
				LEFT JOIN dbo.data_wide_mdm_building bld ON bld.BuildingGUID =r.MasterBldGUID
                INNER JOIN data_wide_mdm_BusinessUnit bu ON bu.BUGUID = pp.BUGUID
                INNER JOIN data_wide_s_Trade tr WITH(NOLOCK)ON tr.RoomGUID = r.RoomGUID AND tr.TradeStatus = '激活' AND  tr.IsLast = 1
                LEFT JOIN(SELECT    g.SaleGUID AS SaleGUID ,
                                    SUM(CASE WHEN DATEDIFF(YEAR, ISNULL(v.RzDate, g.SkDate), @TjDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS BnRmbAmount
                          FROM  data_wide_s_Getin g WITH(NOLOCK)
                                LEFT JOIN data_wide_s_Voucher v WITH(NOLOCK)ON g.VouchGUID = v.VouchGUID
                          WHERE g.VouchStatus <> '作废' AND  g.ItemType IN ('贷款类房款', '非贷款类房款')
                          GROUP BY g.SaleGUID) gg ON gg.SaleGUID = tr.TradeGUID
        WHERE   pp.Level = 2 AND DATEDIFF(YEAR, tr.CQsDate, @TjDate) = 0 AND  (tr.x_InitialledDate IS NULL OR YEAR(tr.x_InitialledDate) >= YEAR(@TjDate))
                AND   pp.p_projectId IN(SELECT  [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') )
        GROUP BY bu.BUName ,
                 pp.p_projectId ,
                 CASE WHEN ISNULL(pp.SpreadName, '') <> '' THEN ISNULL(pp.SpreadName, '')ELSE pp.ProjName END ,
                  CASE WHEN bld.TopProductTypeName IN ('住宅', '车位', '其他', '办公') THEN bld.TopProductTypeName
                     WHEN bld.TopProductTypeName = '商业' AND  bld.ProductTypeName = '公寓' THEN '公寓'
                     WHEN bld.TopProductTypeName = '商业' AND  bld.ProductTypeName <> '公寓' THEN '商业'
					 WHEN bld.TopProductTypeName IS NULL THEN  '其他'
                END 
    END;
