USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_s_ProjSaleDetailsInfo]    Script Date: 2024/12/12 16:04:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_rpt_s_ProjSaleDetailsInfo]
(
    @ProjGUID VARCHAR(MAX),   --项目分期GUID   
    @RoomStatus VARCHAR(200), --房间状态  
    @SDate DATETIME,          --收款开始日期  
    @EDate DATETIME           --收款截止日期  
-- @QYDate DATETIME ,          --签约开始日期  
--  @QYEDate DATETIME ,          --签约截止日期  
-- @YJDate DATETIME ,    --业绩开始日期  
-- @YJEDate DATETIME     --业绩截止日期  
)
AS
BEGIN
    SELECT p.p_projectId,
           CASE
               WHEN ISNULL(pp.SpreadName, '') = '' THEN
                   pp.ProjName
               ELSE
                   pp.SpreadName
           END AS 项目推广名,
           pp.ProjName AS 项目,
           p.ProjShortName AS 期数,
           r.BldName AS 楼栋,
           r.ShortRoomInfo AS 认购单位,
           tr.HtCarryoverDate AS 结转日期,
           r.RoomGUID AS 房源唯一码,
           r.TopProductTypeName + '-' + r.ProductTypeName AS 产品类型,
           CASE
               WHEN tr.CStatus = '激活'
                    AND tr.ContractType = '网签' THEN
                   '网签'
               WHEN tr.CStatus = '激活'
                    AND tr.ContractType = '草签' THEN
                   '草签'
               ELSE
                   '认购'
           END AS 销售状态,          --认购、草签、网签  
           r.BldCode AS 楼栋编号,
           r.Unit AS 单元,
           r.Floor AS 楼层,
           tr.RoomNum AS 房号,
           tr.RoomInfo AS 房间编号,
           r.Status AS 房间状态,
           (
               SELECT STUFF(
                      (
                          SELECT ';' + ApplyType + '(' + CASE
                                                             WHEN AuditStatus = '已审批'
                                                                  AND ApplyStatus = '已执行' THEN
                                                                 '已执行'
                                                             ELSE
                                                                 AuditStatus
                                                         END + ')'
                          FROM data_wide_s_SaleModiApply sm
                          WHERE sm.ApplyStatus <> '作废'
                                AND sm.TradeGUID = tr.TradeGUID
                          FOR XML PATH('')
                      ),
                      1,
                      1,
                      ''
                           )
           ) AS 变更状态,
           r.HxName AS 户型,
           r.Cx AS 朝向,
           r.x_DecorationStatus AS 装修标准,
           r.YsBldArea AS 预售建筑面积,
           r.YsTnArea AS 预售套内面积,
           CASE
               WHEN tr.OCstAllName IS NOT NULL
                    AND tr.OCstAllName != tr.CCstAllName THEN
                   tr.CCstAllName --如果权益人发生变更则以后一个为准，证件号码和手机同理  
               ELSE
                   ISNULL(tr.OCstAllName, tr.CCstAllName)
           END AS 业主姓名,
           ISNULL(tr.OCstAllCardType, tr.CCstAllCardType) AS 证件类型,
           tr.SubMediaName AS 'mtxl',
           tr.MainMediaName AS 'Mtdl',
           CASE
               WHEN tr.OCstAllCardID IS NOT NULL
                    AND tr.OCstAllCardID != tr.CCstAllCardID THEN
                   tr.CCstAllCardID
               ELSE
                   ISNULL(tr.OCstAllCardID, tr.CCstAllCardID)
           END AS 证件号码,
           CASE
               WHEN tr.OCstAllTel IS NOT NULL
                    AND tr.OCstAllTel != tr.CCstAllTel THEN
                   tr.CCstAllTel
               ELSE
                   ISNULL(tr.OCstAllTel, tr.CCstAllTel)
           END AS 手机,
           ISNULL(tr.CAddress, tr.OAddress) AS 通讯地址,
           ISNULL(tr.CZygw, tr.OZygw) AS 置业顾问,
           ISNULL(tr.x_CSalesLeader, tr.x_OSalesLeader) AS 销售组长,
                                 --ISNULL(tr.CProjectTeam, tr.OProjectTeam) AS 销售团队 ,  
           ISNULL(
                     ISNULL(tr.CProjectTeam, tr.OProjectTeam),
           (
               SELECT STUFF(
                      (
                          SELECT DISTINCT
                                 ',' + CONVERT(VARCHAR(200), ptu.ProjTeamName)
                          FROM data_wide_s_ProjectTeamUser ptu
                          WHERE (
                                    ptu.ProjGUID = p.p_projectId
                                    OR ptu.ProjGUID = pp.p_projectId
                                )
                                AND CHARINDEX(
                                                 LOWER(CONVERT(VARCHAR(50), ptu.UserGUID)),
                                                 LOWER(ISNULL(tr.CZygwAllGUID, tr.OZygwAllGUID))
                                             ) > 0
                          FOR XML PATH('')
                      ),
                      1,
                      1,
                      ''
                           )
           )
                 ) AS 销售团队,
           r.LittleOrderDate AS 预选日期,
                                 -- rex.ZcRgQsDate AS 首次认购日期,  
           tr.OQsDate AS 认购日期,
           tr.ZcOrderDate AS 首次认购日期,
           CASE
               WHEN r.LittleOrderDate IS NOT NULL THEN
                   r.LittleOrderDate
               ELSE
                   tr.ZcOrderDate
           END AS 认购预选日期,        -- 取成交明细的首次认购日期，如有预选房，则取预选房间的日期  
           r.Total AS 标准总价,

                                 --改为trade表的字   
                                 --r.CjRmbTotal AS 成交总价 ,  
           ISNULL(tr.CCjTotal, tr.OCjTotal) AS 成交总价,
           ISNULL(tr.CCjRoomTotal, tr.OCjRoomTotal) AS 房间总价不含补充协议,
           r.CjBldPrice AS 成交单价, --建筑单价  
           r.DjTotal AS 底价总价,
           tr.BcAfterCTotal 补差后金额,
           ISNULL(tr.CBcxyTotal, tr.OBcxyTotal) AS 补充协议价,
           ISNULL(tr.CTaxRate, tr.OTaxRate) AS 合同税率,
           ISNULL(tr.CBcxyTaxRate, tr.OBcxyTaxRate) AS 补充协议税率,
           r.DjBldPrice AS 底价单价, --底价建筑单价  
           ISNULL(tr.CCjZxTotal, tr.OCjZxTotal) AS 装修改造合同价,
           CASE
               WHEN tr.CIsZxkbrht = 1 THEN
                   '是'
               WHEN tr.OIsZxkbrht = 1 THEN
                   '是'
               ELSE
                   '否'
           END AS 装修款是否并入主合同,
           ISNULL(tr.CDiscountRemark, tr.ODiscountRemark) AS 折扣说明,
           ISNULL(tr.CDiscount, tr.ODiscount) AS 折扣合计,
           ISNULL(tr.CPayForm, tr.OPayForm) AS 付款方式,
           ISNULL(tr.YsDj, 0) AS 定金金额,
           tr.ssdjDate AS 定金实收日期,
           dj.LastDate AS 定金应付日期,
           ISNULL(tr.SsDj, 0) AS 定金实收金额,
           ISNULL(tr.CAjBank, tr.OAjBank) AS 按揭银行,
           ISNULL(tr.YsAj, 0) AS 商贷金额,
           ISNULL(tr.YsGjj, 0) AS 公积金金额,
           tr.YsGjjLastDate AS 公积金应收日期,
           tr.YsAjLastDate AS 按揭应收日期,
           tr.HtdjCompleteDate AS 合同登记服务完成日期,
           tr.AjfkDate AS 商贷放款日期,
           ISNULL(tr.SsAj, 0) AS 商贷放款金额,
           tr.GjjfkDate AS 公积金放款日期,
           ISNULL(tr.SsGjj, 0) AS 公积金放款金额,
           ISNULL(tr.YsAj, 0) - ISNULL(tr.SsAj, 0) AS 按揭待放款余额,
           CASE
               WHEN tr.YsAj IS NULL THEN
                   ''
               ELSE
                   CASE
                       WHEN (ISNULL(tr.YsAj, 0) - ISNULL(tr.SsAj, 0)) <= 0 THEN
                           '是'
                       ELSE
                           '否'
                   END
           END AS 按揭款是否付清,
                                 -- ISNULL(tr.Ssfk, 0) AS 累计已收房款 ,  
           ISNULL(g.getRmbAmount, 0) AS 累计已收房款,
                                 --CASE WHEN ISNULL(r.CjRmbTotal, 0) = 0 THEN 0 ELSE ISNULL(tr.Ssfk, 0) / ISNULL(r.CjRmbTotal, 0)END AS 累计收款比例 ,  
                                 --ISNULL(tr.Ysfk, 0) - ISNULL(tr.Ssfk, 0) AS 待回款 ,  
                                 --CASE WHEN tr.Ysfk IS NULL THEN '' ELSE CASE WHEN (ISNULL(tr.Ysfk, 0) - ISNULL(tr.Ssfk, 0)) <= 0 THEN '是' ELSE '否' END END AS 是否已收齐房款 ,  
                                 --CASE WHEN tr.Ysfk IS NULL THEN '' ELSE CASE WHEN (ISNULL(tr.Ysfk, 0) - ISNULL(tr.Ssfk, 0)) <= 0 THEN g.LastSkDate ELSE NULL END END AS 收齐房款日期 ,  
           CASE
               WHEN ISNULL(r.CjRmbTotal, 0) = 0 THEN
                   0
               ELSE
                   ISNULL(g.getRmbAmount, 0) / ISNULL(r.CjRmbTotal, 0)
           END AS 累计收款比例,
           ISNULL(tr.Ysfk, 0) + ISNULL(tr.BcTotal, 0) - ISNULL(g.getRmbAmount, 0) AS 待回款,
           CASE
               WHEN tr.Ysfk IS NULL THEN
                   ''
               ELSE
                   CASE
                       WHEN (ISNULL(tr.Ysfk, 0) + ISNULL(tr.BcTotal, 0) - ISNULL(g.getRmbAmount, 0)) <= 0 THEN
                           '是'
                       ELSE
                           '否'
                   END
           END AS 是否已收齐房款,
                                 --CASE WHEN tr.Ysfk IS NULL THEN '' ELSE CASE WHEN (ISNULL(tr.Ysfk, 0) + ISNULL(tr.BcTotal,0) - ISNULL( g.getRmbAmount, 0)-isnull(bcg.getRmbAmount,0)) <= 0 THEN '是' ELSE '否' END END AS 不含补差是否已收齐房款 ,  
                                 -- CASE WHEN tr.Ysfk IS NULL THEN '' ELSE CASE WHEN (ISNULL(tr.Ysfk, 0) + ISNULL(tr.BcTotal,0) - ISNULL( g.getRmbAmount, 0)) <= 0 THEN g.LastSkDate ELSE NULL END END AS 收齐房款日期 ,  
           t.LastSkDate AS 收齐房款日期,
           g.bnRmbAmount AS 本年已收房款合计,
           r.x_YeJiTime AS 业绩认定日期,
           tr.x_YjInitialledDate AS 预计草签日期,
           tr.x_InitialledDate AS 实际草签日期,
           CASE
               WHEN tr.x_InitialledDate > tr.x_YjInitialledDate THEN
                   '是'
               WHEN
               (
                   tr.x_InitialledDate IS NULL
                   AND GETDATE() > tr.x_YjInitialledDate
               ) THEN
                   '是'
               ELSE
                   '否'
           END AS 草签是否超期,
           CASE
               WHEN tr.ContractType = '草签'
                    AND tr.x_InitialledDate IS NOT NULL THEN
                   tr.CAgreementNo
           END AS 草签合同编号,
           CASE
               WHEN tr.ContractType = '草签'
                    AND tr.x_InitialledDate IS NOT NULL THEN
                   r.CjRmbTotal
           END AS 草签合同价格,
           tr.YqyDate AS 预计网签日期,
           tr.CNetQsDate AS 实际网签日期,
           tr.CBaDate AS 备案日期,
           tr.CBaNo,
           CASE
               WHEN tr.CNetQsDate > tr.YqyDate THEN
                   '是'
               WHEN
               (
                   tr.CNetQsDate IS NULL
                   AND GETDATE() > tr.YqyDate
               ) THEN
                   '是'
               ELSE
                   '否'
           END AS 网签是否超期,
           CASE
               WHEN tr.ContractType = '网签'
                    AND tr.CNetQsDate IS NOT NULL THEN
                   tr.CAgreementNo
           END AS 网签合同编号,
           CASE
               WHEN tr.ContractType = '网签'
                    AND tr.CNetQsDate IS NOT NULL THEN
                   r.CjRmbTotal
           END AS 网签价格,
           CASE
               WHEN ISNULL(sma.yqfkNum, 0) > 0 THEN
                   '是'
               ELSE
                   '否'
           END AS 是否申请过延期付款,
           r.ScBldArea AS 实测建筑面积,
           r.ScTnArea AS 实测套内面积,
           ISNULL(r.BcTotal, 0) + ISNULL(r.FsBcTotal, 0) AS 面积补差金额,
           ISNULL(r.CjRmbTotal, 0) AS 面积补差后实际成交金额,
           ISNULL(tr.BcTotal, 0) + ISNULL(tr.FsBcTotal, 0) AS 实际补差金额,
                                 --ISNULL(bcg.getRmbAmount,0) AS 实收补差金额,  
           bx.RmbAmount AS 补充协议应付金额,
           bx.RmbYe AS 补充协议余额,
           bx.RmbDsAmount AS 补充协议多收,
           bx.lastDate AS 补充协议应付日期,
           tr.BcExeTime AS 补差日期,
           wx.RmbAmount AS 维修基金应付金额,
           wx.RmbYe AS 维修基金余额,
           wx.RmbDsAmount AS 维修基金多收,
           tr.YjfDate AS 预计交房日期,
           tr.SjjfDate AS 实际交房日期,
           wx.lastDate AS 维修基金应付日期,
           p2.RmbAmount AS 首期应付金额,
           p2.RmbYe AS 首期余额,
           p2.RmbDsAmount AS 首期多收,
           p2.LastDate AS 首期应付日期,
           CASE
               WHEN p2.RmbAmount IS NULL THEN
                   ''
               ELSE
                   CASE
                       WHEN p2.RmbYe = 0 THEN
                           '是'
                       ELSE
                           '否'
                   END
           END AS 首期是否付清,
           ss2.je AS 首期实收金额,
           ss2.rq AS 首期实收日期,
           p3.RmbAmount AS 二期应付金额,
           p3.RmbYe AS 二期余额,
           p3.RmbDsAmount AS 二期多收,
           p3.LastDate AS 二期应付日期,
           CASE
               WHEN p3.RmbAmount IS NULL THEN
                   ''
               ELSE
                   CASE
                       WHEN p3.RmbYe = 0 THEN
                           '是'
                       ELSE
                           '否'
                   END
           END AS 二期是否付清,
           ss3.je AS 二期实收金额,
           ss3.rq AS 二期实收日期,
           p4.RmbAmount AS 三期应付金额,
           p4.RmbYe AS 三期余额,
           p4.RmbDsAmount AS 三期多收,
           p4.LastDate AS 三期应付日期,
           CASE
               WHEN p4.RmbAmount IS NULL THEN
                   ''
               ELSE
                   CASE
                       WHEN p4.RmbYe = 0 THEN
                           '是'
                       ELSE
                           '否'
                   END
           END AS 三期是否付清,
           ss4.je 三期实收金额,
           ss4.rq 三期实收日期,
		   znj.参考滞纳金,
           tr.ccjbldarea as 合同单面积,
           tr.ocjbldarea as 认购单面积,
            CASE WHEN isnull(tr.x_InitialledDate,0)=0 and tr.CNetQsDate IS not null THEN  tr.CNetQsDate   
              WHEN isnull(tr.x_InitialledDate,0)=0 and isnull(tr.CNetQsDate,0)=0 THEN NULL  
            ELSE tr.x_InitialledDate END AS 签约日期
    FROM dbo.data_wide_s_Room r WITH (NOLOCK)
        LEFT JOIN data_wide_dws_s_roomexpand rex WITH (NOLOCK)
            ON r.RoomGUID = rex.RoomGUID
        INNER JOIN dbo.data_wide_mdm_Project p WITH (NOLOCK)
            ON p.p_projectId = r.ProjGUID
        INNER JOIN data_wide_mdm_Project pp WITH (NOLOCK)
            ON p.ParentGUID = pp.p_projectId
               AND pp.Level = 2
        INNER JOIN data_wide_s_Trade tr WITH (NOLOCK)
            ON tr.RoomGUID = r.RoomGUID
               AND tr.TradeStatus = '激活'
               AND tr.IsLast = 1
        LEFT JOIN
        (
            SELECT TradeGUID,
                   MAX(LastDate) AS lastDate,
                   SUM(ISNULL(RmbAmount, 0)) AS RmbAmount,
                   SUM(ISNULL(RmbYe, 0)) AS RmbYe,
                   SUM(ISNULL(RmbDsAmount, 0)) AS RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '代收费用'
                  AND ItemName LIKE '%维修%'
            GROUP BY TradeGUID
        ) wx
            ON wx.TradeGUID = tr.TradeGUID
        LEFT JOIN
        (
            SELECT TradeGUID,
                   MAX(LastDate) AS lastDate,
                   SUM(ISNULL(RmbAmount, 0)) AS RmbAmount,
                   SUM(ISNULL(RmbYe, 0)) AS RmbYe,
                   SUM(ISNULL(RmbDsAmount, 0)) AS RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '补充协议款'
            GROUP BY TradeGUID
        ) bx
            ON bx.TradeGUID = tr.TradeGUID

        -- 判断该交易是否存在已执行的延期付款，如存在则是，否则为否  
        LEFT JOIN
        (
            SELECT TradeGUID,
                   COUNT(SaleModiApplyGUID) AS yqfkNum
            FROM data_wide_s_SaleModiApply WITH (NOLOCK)
            WHERE ApplyStatus <> '作废'
                  AND ApplyType = '延期付款'
                  AND ApplyStatus = '已执行'
            GROUP BY TradeGUID
        ) AS sma
            ON sma.TradeGUID = tr.TradeGUID
        LEFT JOIN
        (
            SELECT SaleGUID,
                   SUM(ISNULL(RmbAmount, 0)) AS getRmbAmount,
                   -- MAX(SkDate) AS LastSkDate ,                                                                                     --最后一笔房款收款日期  
                   SUM(   CASE
                              WHEN DATEDIFF(YEAR, SkDate, GETDATE()) = 0 THEN
                                  RmbAmount
                              ELSE
                                  0
                          END
                      ) bnRmbAmount
            --本年实收房款金额  
            FROM data_wide_s_Getin WITH (NOLOCK)
            WHERE VouchStatus <> '作废'
                  AND ItemType IN ( '贷款类房款', '非贷款类房款', '补充协议款' )
                  AND IsFk = 1
            GROUP BY SaleGUID
        ) g
            ON g.SaleGUID = tr.TradeGUID
        --获取实收补差款金额  
        /* LEFT JOIN (SELECT SaleGUID, SUM(ISNULL(RmbAmount,0)) AS getRmbAmount  
                          FROM  data_wide_s_Getin WITH(NOLOCK)  
                          WHERE VouchStatus <> '作废' AND ItemType IN ('非贷款类房款') AND IsFk = 1 AND ItemName like '%补差%'  
                          GROUP BY SaleGUID) bcg ON bcg.SaleGUID = tr.TradeGUID  */
        OUTER APPLY
    (
        SELECT TOP 1
               gg.SaleGUID,
               gg.SkDate AS LastSkDate,
               gg.sumRmbAmount
        FROM
        (
            SELECT g.SaleGUID,
                   g.RmbAmount,
                   g.SkDate,
                   SUM(ISNULL(g.RmbAmount, 0)) OVER (PARTITION BY g.SaleGUID ORDER BY g.SkDate) AS sumRmbAmount
            FROM dbo.data_wide_s_Getin g
            WHERE g.VouchStatus <> '作废'
                  AND g.ItemType IN ( '贷款类房款', '非贷款类房款', '补充协议款' )
                  AND g.IsFk = 1
                  AND g.SaleGUID = tr.TradeGUID
        ) gg
        WHERE gg.sumRmbAmount >= (ISNULL(tr.Ysfk, 0) + ISNULL(tr.BcTotal, 0)) -- AND gg.SaleGUID =tr.TradeGUID  
        ORDER BY SkDate
    ) t
        LEFT JOIN
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row,
                   FeeGUID,
                   TradeGUID,
                   Sequence,
                   ItemType,
                   ItemName,
                   LastDate,
                   RmbAmount,
                   RmbYe,
                   RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '非贷款类房款'
                  AND ItemName = '定金'
        ) dj
            ON dj.TradeGUID = tr.TradeGUID
               AND dj.row = 1
        --增加应收和实收首期，二期，三期金额和日期20241030
        LEFT JOIN
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row,
                   FeeGUID,
                   TradeGUID,
                   Sequence,
                   ItemType,
                   ItemName,
                   LastDate,
                   RmbAmount,
                   RmbYe,
                   RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '非贷款类房款'
                  AND ItemName <> '定金'
        ) AS p2
            ON p2.TradeGUID = tr.TradeGUID
               AND p2.row = 1
        LEFT JOIN
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row,
                   FeeGUID,
                   TradeGUID,
                   Sequence,
                   ItemType,
                   ItemName,
                   LastDate,
                   RmbAmount,
                   RmbYe,
                   RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '非贷款类房款'
                  AND ItemName <> '定金'
        ) AS p3
            ON p3.TradeGUID = tr.TradeGUID
               AND p3.row = 2
        LEFT JOIN
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY TradeGUID ORDER BY Sequence) AS row,
                   FeeGUID,
                   TradeGUID,
                   Sequence,
                   ItemType,
                   ItemName,
                   LastDate,
                   RmbAmount,
                   RmbYe,
                   RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '非贷款类房款'
                  AND ItemName <> '定金'
        ) AS p4
            ON p4.TradeGUID = tr.TradeGUID
               AND p4.row = 3
        LEFT JOIN
        (
            SELECT TradeGUID,
                   MAX(LastDate) AS lastDate,
                   SUM(ISNULL(RmbAmount, 0)) AS RmbAmount,
                   SUM(ISNULL(RmbYe, 0)) AS RmbYe,
                   SUM(ISNULL(RmbDsAmount, 0)) AS RmbDsAmount
            FROM data_wide_s_Fee WITH (NOLOCK)
            WHERE ItemType = '代收费用'
                  AND ItemName LIKE '%维修%'
            GROUP BY TradeGUID
        ) AS p5
            ON p5.TradeGUID = tr.TradeGUID
        LEFT JOIN
        (
            SELECT SaleGUID,
                   ItemName,
                   SUM(RmbAmount) je,
                   CASE
                       WHEN SUM(RmbAmount) > 0 THEN
                           MAX(SkDate)
                   END rq
            FROM data_wide_s_Getin WITH (NOLOCK)
            WHERE VouchStatus = '激活'
            GROUP BY SaleGUID,
                     ItemName
        ) ss2
            ON ss2.SaleGUID = tr.TradeGUID
               AND ss2.ItemName = p2.ItemName
        LEFT JOIN
        (
            SELECT SaleGUID,
                   ItemName,
                   SUM(RmbAmount) je,
                   CASE
                       WHEN SUM(RmbAmount) > 0 THEN
                           MAX(SkDate)
                   END rq
            FROM data_wide_s_Getin WITH (NOLOCK)
            WHERE VouchStatus = '激活'
            GROUP BY SaleGUID,
                     ItemName
        ) ss3
            ON ss3.SaleGUID = tr.TradeGUID
               AND ss3.ItemName = p3.ItemName
        LEFT JOIN
        (
            SELECT SaleGUID,
                   ItemName,
                   SUM(RmbAmount) je,
                   CASE
                       WHEN SUM(RmbAmount) > 0 THEN
                           MAX(SkDate)
                   END rq
            FROM data_wide_s_Getin WITH (NOLOCK)
            WHERE VouchStatus = '激活'
            GROUP BY SaleGUID,
                     ItemName
        ) ss4  ON ss4.SaleGUID = tr.TradeGUID  AND ss4.ItemName = p4.ItemName
	   LEFT join 
        (
				SELECT TradeGUID,
						SUM(ISNULL(FineAmount1,0)) AS 参考滞纳金
				FROM data_wide_s_s_Cwfx WITH (NOLOCK)
				GROUP BY TradeGUID
         ) znj on  tr.TradeGUID=znj.tradeguid
    WHERE r.Status IN ( '认购', '小订', '签约' )
          AND r.ProjGUID IN
              (
                  SELECT [Value] FROM [dbo].[fn_Split](@ProjGUID, ',')
              )
          AND r.Status IN
              (
                  SELECT [Value] FROM [dbo].[fn_Split](@RoomStatus, ',')
              )
          AND tr.ZcOrderDate BETWEEN @SDate AND @EDate;
--and   tr.CNetQsDate BETWEEN @QYDate AND @QYEDate  
--and   r.x_YeJiTime  BETWEEN @YJDate AND @YJEDate  
--ORDER BY pp.ProjName ,  
--         p.ProjName;  
END



