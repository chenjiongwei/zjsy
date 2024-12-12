USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_leaveSaleValue]    Script Date: 2024/12/12 16:53:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- 未售余货统计表
--统计项目不同业态整体余货情况，区分往年余货和新增余货分析
--usp_rpt_s_leaveSaleValue  '06F81A81-8ECF-E911-8A8E-40F2E92B3FDA'
ALTER PROC [dbo].[usp_rpt_s_leaveSaleValue](
     @ProjGUID VARCHAR(MAX),
     @date datetime --查询日期
)
AS
    BEGIN
--获取余货字段
WITH #yh AS (
    SELECT r.ParentProjGUID,
           bld.TopProductTypeName,
           bld.BuildingGUID,
           COUNT(1) AS 余货套数,
           SUM(ISNULL(BldArea, 0)) AS 余货面积,
           SUM(ISNULL(DjTotal, 0)) AS 余货金额,
           --取房间业绩认定日期在往年，但当前房间处于未签约状态的房间套数、面积、金额、均价
           SUM(CASE WHEN r.x_YeJiTime IS NOT NULL AND  YEAR(r.x_YeJiTime) < YEAR(@date) THEN 1 ELSE 0 END) AS 往年签约业绩退房未售套数,
           SUM(CASE WHEN r.x_YeJiTime IS NOT NULL AND  YEAR(r.x_YeJiTime) < YEAR(@date) THEN r.BldArea ELSE 0 END) AS 往年签约业绩退房未售面积,
           SUM(CASE WHEN r.x_YeJiTime IS NOT NULL AND  YEAR(r.x_YeJiTime) < YEAR(@date) THEN r.DjTotal ELSE 0 END) AS 往年签约业绩退房未售金额,
           -- 可计算业绩的余货
           SUM(CASE WHEN r.x_YeJiTime IS NULL THEN 1 ELSE 0 END) AS 可计算业绩余货套数,
           SUM(CASE WHEN r.x_YeJiTime IS NULL THEN r.BldArea ELSE 0 END) AS 可计算业绩余货套数面积,
           SUM(CASE WHEN r.x_YeJiTime IS NULL THEN r.DjTotal ELSE 0 END) AS 可计算业绩余货金额
    FROM   data_wide_s_Room r
           INNER JOIN dbo.data_wide_mdm_building bld ON bld.BuildingGUID = r.MasterBldGUID
    WHERE  r.status NOT IN ('签约') AND  ISNULL(r.DjTotal, 0) <> 0  
    GROUP BY r.ParentProjGUID,
             bld.TopProductTypeName,
             bld.BuildingGUID
),
-- 已售货值
#ys AS (
    SELECT r.ParentProjGUID,
           bld.TopProductTypeName,
           bld.BuildingGUID,
           COUNT(1) AS 已签约套数,
           SUM(ISNULL(r.CjBldArea, 0) ) AS 已签约面积,
           SUM(ISNULL(r.CjRmbTotal, 0) ) AS 已签约金额
    FROM   data_wide_s_Room r
           INNER JOIN dbo.data_wide_mdm_building bld ON bld.BuildingGUID = r.MasterBldGUID
    WHERE  r.status = '签约'
    GROUP BY r.ParentProjGUID,
             bld.TopProductTypeName,
             bld.BuildingGUID
),
-- 可售货值
#pt AS (
    SELECT bld.ProjGUID,
           bld.TopProductTypeName,
           bld.BuildingGUID,
           bld.FactNotOpen,
           SUM(ISNULL(AvailableArea, 0)) AS 可售面积,
           SUM(ISNULL(SaleAmount, 0)) AS 可售金额,
           SUM(CASE WHEN bld.ProductTypeName LIKE '%车位%' THEN bld.CarNum ELSE bld.SetNum END) AS 可售套数
    FROM   data_wide_mdm_building bld
          
    GROUP BY bld.ProjGUID,
             bld.TopProductTypeName,
             bld.BuildingGUID,
             bld.FactNotOpen
),
--已取证未定价
#wdj AS (
	         select
	         bld.ProjGUID,
	         bld.BuildingGUID,
	         bld.TopProductTypeName,
	         SUM(CASE WHEN bld.FactNotOpen is not null and bld.ManagementAttributes='可售' THEN 
	         (CASE WHEN bld.ProductTypeName LIKE '%车位%' THEN bld.CarNum ELSE bld.SetNum END)
	         ELSE 0 END) AS 已取证未定价统计套数,
           SUM(CASE WHEN bld.FactNotOpen is not null and bld.ManagementAttributes='可售' THEN bld.AvailableArea ELSE 0 END) AS 已取证未定价统计面积,
           SUM(CASE WHEN bld.FactNotOpen is not null and bld.ManagementAttributes='可售' THEN bld.SaleAmount ELSE 0 END)  AS 已取证未定价统计金额
    FROM   data_wide_mdm_building bld
           LEFT JOIN (
               SELECT a.BuildingGUID
               FROM data_wide_mdm_building a
               WHERE EXISTS (
                   SELECT 1
                   FROM data_wide_s_room b 
                   WHERE a.BuildingGUID = b.MasterBldGUID AND (b.BldPrice <> 0 OR b.DjTotal <> 0)
               )
           ) bldr ON bld.BuildingGUID = bldr.BuildingGUID
           where bldr.BuildingGUID is null 
           
    GROUP BY bld.ProjGUID,
             bld.TopProductTypeName,
             bld.BuildingGUID
)



SELECT  p.p_projectId,
        CASE WHEN ISNULL(p.SpreadName, '') = '' THEN p.ProjName ELSE p.SpreadName END AS 推广名,
        pt.TopProductTypeName AS 业态,
        -- 余货统计
        SUM(ISNULL(yh.余货套数, 0)) AS 余货套数,
        SUM(ISNULL(yh.余货面积, 0)) AS 余货面积,
        CASE WHEN SUM(ISNULL(yh.余货面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(yh.余货金额, 0)) / SUM(ISNULL(yh.余货面积, 0)) END AS 余货均价,
        SUM(ISNULL(yh.余货金额, 0)) / 10000.0 AS 余货金额,
        -- 其中往年签约业绩退房未售
        SUM(ISNULL(yh.往年签约业绩退房未售套数, 0)) AS 往年签约业绩退房未售套数,
        SUM(ISNULL(yh.往年签约业绩退房未售面积, 0)) AS 往年签约业绩退房未售面积,
        CASE WHEN SUM(ISNULL(yh.往年签约业绩退房未售面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(yh.往年签约业绩退房未售金额, 0)) / SUM(ISNULL(yh.往年签约业绩退房未售面积, 0)) END AS 往年签约业绩退房未售均价,
        SUM(ISNULL(yh.往年签约业绩退房未售金额, 0)) / 10000.0 AS 往年签约业绩退房未售金额,
        -- 可计算业绩的余货
        SUM(ISNULL(yh.可计算业绩余货套数, 0)) AS 可计算业绩的余货套数,
        SUM(ISNULL(yh.可计算业绩余货套数面积, 0)) AS 可计算业绩的余货面积,
        CASE WHEN SUM(ISNULL(yh.可计算业绩余货套数面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(yh.可计算业绩余货金额, 0)) / SUM(ISNULL(yh.可计算业绩余货套数面积, 0)) END AS 可计算业绩的余货均价,
        SUM(ISNULL(yh.可计算业绩余货金额, 0)) / 10000.0 AS 可计算业绩的余货金额,
        -- 已取证未定价统计（包括已确权未定价）
        SUM(ISNULL(wdj.已取证未定价统计套数, 0)) AS 已取证未定价统计套数,
        SUM(ISNULL(wdj.已取证未定价统计面积, 0)) AS 已取证未定价统计面积,
        CASE WHEN SUM(ISNULL(wdj.已取证未定价统计面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(wdj.已取证未定价统计金额, 0)) / SUM(ISNULL(wdj.已取证未定价统计面积, 0)) END AS 已取证未定价统计均价,
        SUM(ISNULL(wdj.已取证未定价统计金额, 0))/ 10000.0 AS 已取证未定价统计金额,
        --,
        --已达预售未取证
        --SUM
        SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is not null and datediff(day,pt.FactNoPassport,@date)>0) THEN (CASE WHEN pt.ProductTypeName LIKE '%车位%' THEN pt.CarNum ELSE pt.SetNum END)
	         ELSE 0 END) AS 已达预售未取证货值统计套数,
        SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is not null and datediff(day,pt.FactNoPassport,@date)>0) THEN pt.AvailableArea ELSE 0 END) AS 已达预售未取证货值统计面积,
        CASE WHEN SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is not null and datediff(day,pt.FactNoPassport,@date)>0) THEN pt.AvailableArea ELSE 0 END) = 0 THEN 0 
        ELSE SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is not null and datediff(day,pt.FactNoPassport,@date)>0) THEN pt.SaleAmount ELSE 0 END) / 
			SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is not null and datediff(day,pt.FactNoPassport,@date)>0) THEN pt.AvailableArea ELSE 0 END) END AS 已达预售未取证货值统计均价,
        SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is not null and datediff(day,pt.FactNoPassport,@date)>0) THEN pt.SaleAmount ELSE 0 END) / 10000.0 AS 已达预售未取证货值统计金额,
        -- 在建未取证/待建货值统计
        SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is null or datediff(day,pt.FactNoPassport,@date)<0) THEN (CASE WHEN pt.ProductTypeName LIKE '%车位%' THEN pt.CarNum ELSE pt.SetNum END)
	         ELSE 0 END) AS 在建未取证待建货值统计套数,
        SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is null or datediff(day,pt.FactNoPassport,@date)<0) THEN pt.AvailableArea ELSE 0 END) AS 在建未取证待建货值统计面积,
        CASE WHEN SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is null or datediff(day,pt.FactNoPassport,@date)<0) THEN pt.AvailableArea ELSE 0 END) = 0 THEN 0 
        ELSE SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is null or datediff(day,pt.FactNoPassport,@date)<0) THEN pt.SaleAmount ELSE 0 END) / 
        SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is null or datediff(day,pt.FactNoPassport,@date)<0) THEN pt.AvailableArea ELSE 0 END) END AS 在建未取证待建货值统计均价,
       SUM(CASE WHEN pt.ManagementAttributes='可售' and (pt.FactNotOpen IS NULL or datediff(day,pt.FactNotOpen,@date)<0) and (pt.FactNoPassport is null or datediff(day,pt.FactNoPassport,@date)<0) THEN pt.SaleAmount ELSE 0 END) / 10000.0 AS 在建未取证待建货值统计金额
FROM    dbo.data_wide_mdm_Project p
        INNER JOIN data_wide_mdm_building pt ON pt.ProjGUID = p.p_projectId
        left join #wdj wdj ON wdj.ProjGUID= pt.ProjGUID and wdj.TopProductTypeName=pt.TopProductTypeName AND pt.BuildingGUID = wdj.BuildingGUID
        LEFT JOIN #yh yh ON yh.ParentProjGUID = pt.ProjGUID AND yh.TopProductTypeName = pt.TopProductTypeName AND pt.BuildingGUID = yh.BuildingGUID
        LEFT JOIN #ys ys ON ys.ParentProjGUID = pt.ProjGUID AND ys.TopProductTypeName = pt.TopProductTypeName AND pt.BuildingGUID = ys.BuildingGUID
       WHERE   p.Level = 2 AND p.p_projectId IN(SELECT [Value] FROM    [dbo].[fn_Split](@ProjGUID, ',') )
GROUP BY p.p_projectId,
         CASE WHEN ISNULL(p.SpreadName, '') = '' THEN p.ProjName ELSE p.SpreadName END,
         pt.TopProductTypeName;
END


