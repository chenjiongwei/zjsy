USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_NotPayZnjDetail]    Script Date: 2024/12/26 16:20:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
执行示例： EXEC  usp_rpt_s_NotPayZnjDetail '0279B123-ACAA-45C5-C8F6-08D9680B609C'
逾期违约金明细表
modify date  20241118 将已收滞纳金和减免滞纳金金额字段放到第一笔款项上显示

*/

ALTER  PROC [dbo].[usp_rpt_s_NotPayZnjDetail] (@ProjGUID VARCHAR(MAX) --项目分期GUID 
)
AS
BEGIN

      --DECLARE  @ProjGUID VARCHAR(MAX)= '0279B123-ACAA-45C5-C8F6-08D9680B609C'
   --   -- 存在滞纳金的激活的交易
			--SELECT tr.TradeGUID,
			--	   SUM(FineAmount1) AS 参考滞纳金
			--INTO #ExistsZnj
			--FROM data_wide_s_s_Cwfx f WITH (NOLOCK)
			--	INNER JOIN data_wide_s_Trade tr WITH (NOLOCK)
			--		ON tr.IsLast = 1
			--		   AND f.TradeGUID = tr.TradeGUID
			--WHERE tr.TradeStatus = '激活'
			--	  AND tr.ProjGUID  IN  ( SELECT [Value] FROM [dbo].[fn_Split](@ProjGUID, ',') )
			--GROUP BY tr.TradeGUID
			--HAVING SUM(FineAmount1) > 0

     -- 将逾期违约金插入临时表
    SELECT CASE
                WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName
                ELSE pp.SpreadName END AS 项目推广名,
		   f.TradeGUID,
           p.ProjShortName AS 分区名称,
           f.BldName AS 楼栋名称,
           f.UnitNo AS 单元,
           f.ShortRoomInfo AS 房号,
           f.RoomGUID AS 房源唯一编码,
           f.RoomInfo AS 房间全名,
           ISNULL(tr.OCstAllName, tr.CCstAllName) AS 客户名称,
           CASE
                WHEN tr.CStatus = '激活'
                 AND tr.ContractType = '网签' THEN '网签'
                WHEN tr.CStatus = '激活'
                 AND tr.ContractType = '草签' THEN '草签'
                ELSE '认购' END AS 销售状态,
           r.YsBldArea AS 预售建筑面积,
           r.YsTnArea AS 预售套内面积,
           --rex.ZcRgQsDate AS 认购日期 ,
           tr.ZcOrderDate AS 认购日期,
           tr.x_InitialledDate AS 草签日期,
           -- rex.ZcContractDate AS 签约日期 ,  --首次签约日期
           tr.CQsDate AS 签约日期,
           tr.CNetQsDate,
           ISNULL(tr.CPayForm, tr.OPayForm) AS 付款方式名称,
           ISNULL(tr.CCjTotal, tr.OCjTotal) AS 成交总价,
           --ISNULL(tr.CZygw, tr.OZygw) AS 销售员,
           --ISNULL(tr.CProjectTeam, tr.OProjectTeam) AS 所属团队,
           --ISNULL(tr.CCstAllTel, tr.OCstAllTel) AS 联系电话,
           --ISNULL(tr.CAddress, tr.OAddress) AS 地址,
           f.ItemName AS 款项名称,
           f.ItemType AS 款项类型,
           ISNULL(tr.CAjBank, tr.OAjBank) AS 按揭银行,
           f.RmbAmount AS 应交款,
           --未交款违约金
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                 AND f.RmbYe > 0 THEN f.RmbYe END AS 应交款已逾期且未交款金额,
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                 AND f.RmbYe > 0 THEN f.LastDate END AS 未交款应收日期,
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                 AND f.RmbYe > 0 THEN GETDATE() END AS 未交款违约金截止日期,
           znj.FineRate / 100.0 AS 未交款违约金率,
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                 AND f.RmbYe > 0 THEN DATEDIFF(DAY, f.LastDate, GETDATE()) END AS 未交款逾期天数,
           --对应未交款项的应计滞纳金金额=未交款金额*违约金率*逾期天数
           ISNULL(CASE
                       WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                        AND f.RmbYe > 0 THEN f.RmbYe END,
                  0) * ISNULL(znj.FineRate / 100.0, 0)
           * ISNULL(CASE
                         WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                          AND f.RmbYe > 0 THEN DATEDIFF(DAY, f.LastDate, GETDATE()) END,
                    0) AS 未交款应计违约金参考,

           -- 已交款（曾存在逾期）违约金
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, sk.SkDate) > 0 -- AND f.RmbYe = 0
                 THEN sk.RmbAmount END AS 应交款已缴款但存在逾期金额,
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, sk.SkDate) > 0
                 THEN f.LastDate END AS 已交款应收日期,
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, sk.SkDate) > 0
                THEN sk.SkDate END AS 已缴款实收日期,
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, sk.SkDate) > 0
                 THEN sk.yqTs END AS 已交款逾期天数,
           znj.FineRate / 100.0 AS 已交款合同违约金率,
           --对应已交款项（存在逾期）的应计滞纳金金额 =已交款金额*违约金率*逾期天数
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, sk.SkDate) > 0
                 THEN sk.znjRmbAmount END AS 已交款应计滞纳金参考,
           -- 滞纳金收款情况
           CASE
                WHEN DATEDIFF(DAY, f.LastDate, sk.SkDate) > 0
                  THEN sk.znjRmbAmount
                ELSE 0 END + ISNULL(CASE
                                         WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                                          AND f.RmbYe > 0 THEN f.RmbYe END,
                                    0) * ISNULL(znj.FineRate / 100.0, 0)
           * ISNULL(CASE
                         WHEN DATEDIFF(DAY, f.LastDate, GETDATE()) > 0
                          AND f.RmbYe > 0 THEN DATEDIFF(DAY, f.LastDate, GETDATE()) END,
                    0) AS 应收违约金金额
           --ISNULL(f.RmbAmount, 0) + ISNULL(f.RmbDsAmount, 0) - ISNULL(f.RmbYe, 0) AS 已交款,
           --CASE
           --     WHEN f.ItemName = '滞纳金' THEN f.RmbAmount END AS 已产生滞纳金,
           --NULL AS 结转金额,
           --NULL AS 未收滞纳金,
           --f.JmLateFee AS 累计已减免滞纳金,
           --znj.参考滞纳金
	  INTO #znj  
      FROM data_wide_s_Fee f WITH (NOLOCK)
	  --INNER JOIN  #ExistsZnj  z ON z.TradeGUID =f.TradeGUID
     INNER JOIN dbo.data_wide_mdm_Project p WITH (NOLOCK)
        ON p.p_projectId = f.ProjGUID
     INNER JOIN data_wide_mdm_Project pp WITH (NOLOCK)
        ON p.ParentGUID = pp.p_projectId
       AND pp.Level = 2
     INNER JOIN data_wide_s_Trade tr WITH (NOLOCK)
        ON tr.RoomGUID = f.RoomGUID
       AND tr.IsLast = 1
       AND f.TradeGUID = tr.TradeGUID
     INNER JOIN dbo.data_wide_s_Room r WITH (NOLOCK)
        ON r.RoomGUID = f.RoomGUID
   /*  OUTER APPLY (SELECT g.SaleGUID,
                         g.ItemNameGUID,
                         MAX(g.SkDate) AS SkDate,
                         SUM(DATEDIFF(DAY, fee.LastDate, g.SkDate)) AS yqTs,
                         SUM(g.RmbAmount) AS RmbAmount,
                         SUM(DATEDIFF(DAY, fee.LastDate, g.SkDate) * g.RmbAmount * FineRate / 100.0) AS znjRmbAmount --参考滞纳金
                    FROM data_wide_s_Getin g WITH (NOLOCK)
                   INNER JOIN data_wide_s_Fee fee  ON fee.TradeGUID    = g.SaleGUID  AND fee.ItemNameGUID = g.ItemNameGUID
                    LEFT JOIN (SELECT TradeGUID,
                                      YsItemNameGuid,
                                      MAX(FineRate) AS FineRate
                                 FROM data_wide_s_s_Cwfx WITH (NOLOCK)
                                GROUP BY TradeGUID,
                                         YsItemNameGuid) znj1
                      ON f.ItemNameGUID   = znj1.YsItemNameGuid
                     AND f.TradeGUID      = znj1.TradeGUID
                   WHERE g.VouchStatus                       = '激活'
                     AND DATEDIFF(DAY, f.LastDate, g.SkDate) > 0
                     AND g.ItemNameGUID                      = f.ItemNameGUID
                     AND g.SaleGUID                          = f.TradeGUID
                   GROUP BY g.SaleGUID,
                            g.ItemNameGUID) sk
	*/
	OUTER APPLY (SELECT g.TradeGUID,
                         g.YsItemNameGuid,
                         MAX(g.SsDate) AS SkDate,
                         -- 最大逾期天数
                         max(DATEDIFF(DAY, g.YsDate, g.SsDate)) AS yqTs,                         
						 SUM(g.GetAmount) AS RmbAmount,
                         SUM(DATEDIFF(DAY, g.YsDate, g.SsDate) * g.GetAmount * FineRate / 100.0) AS znjRmbAmount --参考滞纳金
                    FROM data_wide_s_s_Cwfx g WITH (NOLOCK)
                   WHERE  DATEDIFF(DAY, g.YsDate,  g.SsDate ) > 0  AND g.YsItemNameGuid   = f.ItemNameGUID AND g.TradeGUID  = f.TradeGUID
				   AND   DATEDIFF(DAY,g.YsDate ,f.LastDate ) =0
                   GROUP BY g.TradeGUID,
                            g.YsItemNameGuid ) sk
      LEFT JOIN (
	             SELECT TradeGUID,
                        YsItemNameGuid,
						YsDate,
                        MAX(FineRate) AS FineRate,
                        SUM(FineAmount1) AS 参考滞纳金
                   FROM data_wide_s_s_Cwfx WITH (NOLOCK)
                  GROUP BY TradeGUID,
                           YsItemNameGuid,YsDate) znj
        ON f.ItemNameGUID = znj.YsItemNameGuid AND f.TradeGUID    = znj.TradeGUID AND   DATEDIFF(DAY,znj.YsDate ,f.LastDate ) =0
     -- LEFT  JOIN data_wide_dws_s_roomexpand rex ON rex.RoomGUID =r.RoomGUID
     WHERE f.IsFk         = 1
       AND f.ProjGUID IN (SELECT [Value] FROM [dbo].[fn_Split](@ProjGUID, ',') )
       -- AND ISNULL(f.RmbYe, 0) > 0
       AND tr.TradeStatus = '激活'
     ORDER BY tr.ProjGUID,
              tr.RoomInfo;

	--查询结果
	SELECT  *,
	    --   CASE WHEN  ROW_NUMBER() OVER(PARTITION BY TradeGUID ORDER BY znjRate DESC  ) = 1 THEN  
	    --      ( 1.00 -  SUM(ISNULL(znjRate,0) ) OVER(PARTITION BY t.TradeGUID) ) + znjRate ELSE znjRate
		   --END , --滞纳金占比尾数补差
     --     ISNULL(JmLateFee,0)  *  CASE WHEN  ROW_NUMBER() OVER(PARTITION BY TradeGUID ORDER BY znjRate DESC  ) = 1 THEN  
	    --      ( 1.00 -  SUM(ISNULL(znjRate,0) ) OVER(PARTITION BY t.TradeGUID) ) + znjRate ELSE znjRate
		   --END AS 累计已减免滞纳金,
     --     ISNULL(znjGetAmount,0)  *  CASE WHEN  ROW_NUMBER() OVER(PARTITION BY TradeGUID ORDER BY znjRate DESC  ) = 1 THEN  
	    --      ( 1.00 -  SUM(ISNULL(znjRate,0) ) OVER(PARTITION BY t.TradeGUID) ) + znjRate ELSE znjRate
		   --END AS 累计已收款违约金金额
            CASE WHEN  ROW_NUMBER() OVER(PARTITION BY TradeGUID ORDER BY znjRate DESC  ) = 1 THEN  
	           ISNULL(JmLateFee,0)  END AS 累计已减免滞纳金,
            CASE WHEN  ROW_NUMBER() OVER(PARTITION BY TradeGUID ORDER BY znjRate DESC  ) = 1 THEN  
	          ISNULL(znjGetAmount,0)  END AS 累计已收款违约金金额
	FROM  (
		SELECT  znj.*,
			 CONVERT(DECIMAL(36,12), CASE WHEN  SUM(  应收违约金金额  ) OVER(PARTITION BY znj.TradeGUID  ) =0  THEN  0 ELSE   应收违约金金额 
			  / SUM(应收违约金金额 ) OVER(PARTITION BY znj.TradeGUID  ) END  ) AS  znjRate, --滞纳金占比,
			ISNULL(JmLateFee,0)  AS  JmLateFee, -- 累计已减免滞纳金,
			ISNULL(znjGetAmount,0)  AS znjGetAmount --累计已收款违约金金额
		FROM  #znj znj
		LEFT JOIN  (
			 SELECT f.TradeGUID, SUM(ISNULL(JmLateFee,0))  AS JmLateFee --减免滞纳金
				  FROM  dbo.data_wide_s_Fee f
				  GROUP BY  f.TradeGUID
		) jm  ON jm.TradeGUID =znj.TradeGUID
		LEFT JOIN  (
		   SELECT  fx.TradeGUID,SUM(ISNULL(GetAmount,0)) AS znjGetAmount  --实收滞纳金
			FROM data_wide_s_s_Cwfx fx
		   WHERE  YsItemName ='滞纳金'
		   GROUP BY fx.TradeGUID
		) ss ON ss.TradeGUID = znj.TradeGUID
	) t

    --删除临时表
	DROP TABLE  #znj

END;

