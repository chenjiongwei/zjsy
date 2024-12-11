--ZSDC-01-考核指标完成情况
IF  @版本号='实时' 
BEGIN
SELECT  
    null as snapshot_time,
    '实时' as version,
    CASE WHEN ISNULL(pp.SpreadName, '') <> '' THEN ISNULL(pp.SpreadName, '')ELSE pp.ProjName END AS 项目 ,
    pp.BUGUID,
    pp.p_projectId,
    pp.x_ManagementSubject AS 管理主体 ,
    pp.x_area AS 片区 ,
    xst.BudgetContractAmount AS 合约销售额考核值集团版 ,
    xst.BudgetGetinAmount AS 销售回款额考核制集团版 ,
    NULL AS 合约销售额考核值内控版 ,
    NULL AS 销售回款额考核值内控版 ,
    con.LjCCCount AS 从开盘至今的累计销售套数 ,
    con.LjCCjBldArea AS 从开盘至今的累计销售面积 ,
    con.LjCCjRoomTotal AS 从开盘至今的累计销售金额 ,
    gg.LjRmbAmount AS 从开盘至今的累计回款金额 ,   
    con.BnCCCount AS 本年至今的累计销售签约套数 ,
    con.BnCCjBldArea AS 本年至今的累计销售签约面积 ,
    con.BnCCjRoomTotal AS 本年至今的累计销售签约金额 ,
    CASE WHEN ISNULL(xst.BudgetContractAmount,0) =0  THEN  0  ELSE  ISNULL(con.BnCCjRoomTotal,0) /ISNULL(xst.BudgetContractAmount,0) END   AS 本年至今的累计销售签约集团版达成率 ,
    NULL AS 本年至今的累计销售签约内控版达成率 ,
    gg.BnRmbAmount AS 本年至今累计回款金额 ,     
    CASE WHEN ISNULL(xst.BudgetGetinAmount,0) =0  THEN 0 ELSE  ISNULL( gg.BnRmbAmount ,0) /ISNULL(xst.BudgetGetinAmount,0) END  AS 本年至今累计回款集团版达成率 ,
    NULL AS 本年至今累计回款内控版达成率 ,   
    BnxksBldArea AS 本年新开售面积 ,   --  
    BnzjdjBldArea AS 在建待建面积, 
    BnQcchBldArea_QY AS 本年期初库存面积签约,
    BnQCchCCjBldArea_QY AS 截止当前库存签约面积签约口径 ,
    BnQCchCCjRoomTotal_QY AS 截止当前库存签约金额签约口径 ,
    CASE WHEN ISNULL(BnQcchBldArea_QY,0) =0 THEN  0  ELSE  ISNULL(BnQCchCCjBldArea_QY,0) / ISNULL(BnQcchBldArea_QY,0) END   AS 本年期初库存去化情况库存去化率签约 ,

    BnQcchBldArea_YJ AS 本年期初库存面积业绩,
    BnQCchCCjBldArea_YJ AS 截止当前库存签约面积业绩口径 ,
    BnQCchCCjRoomTotal_YJ AS 截止当前库存签约金额业绩口径 ,
    CASE WHEN ISNULL(BnQcchBldArea_YJ,0) =0 THEN  0  ELSE  ISNULL(BnQCchCCjBldArea_YJ,0) / ISNULL(BnQcchBldArea_YJ,0) END   AS 本年期初库存去化情况库存去化率业绩 ,

    sjqy AS 实际签约金额,
    yjrdqy AS 业绩认定签约金额,
    BnsjqyMoney AS 本年实际签约底价金额汇总,
    BnyjMoney AS 本年业绩认定底价金额汇总,
    --con.ZzBnCCjAvgPrice   AS 住宅类销售均价 ,
    --mb.mbAvgPrice   AS 住宅类经营计划目标均价 ,
    --mb.AvailableArea AS 住宅类销售面积 ,

    /*
    CASE WHEN ISNULL(mb.mbAvgPrice,0) * ISNULL( mb.AvailableArea ,0) = 0 THEN  0 ELSE  
    ( (ISNULL( con.ZzBnCCjAvgPrice,0) -ISNULL(mb.mbAvgPrice,0)) * ISNULL(mb.AvailableArea,0) ) /  (ISNULL(mb.mbAvgPrice,0) * ISNULL( mb.AvailableArea ,0) ) END  AS 住宅类货值变动率 ,
    */			
    case when BnsjqyMoney=0 then 0 else (sjqy-BnsjqyMoney)/BnsjqyMoney end AS 货值变动率1,
    case when BnyjMoney=0 then 0 else (yjrdqy-BnyjMoney)/BnyjMoney end AS 货值变动率2,
    CASE WHEN  ISNULL( BnCCCount,0) =0 THEN  0 ELSE ISNULL(yqbgCount,0) * 1.0 / ISNULL(BnCCCount,0) END  AS 延期付款变更率
FROM    data_wide_mdm_Project pp
LEFT JOIN(SELECT    ParentProjGUID AS ProjGUID ,
                    SUM(ISNULL(BudgetContractAmount, 0)) AS BudgetContractAmount ,
                    SUM(ISNULL(BudgetGetinAmount, 0)) AS BudgetGetinAmount
            FROM  data_wide_s_SalesBudget
            WHERE [YEAR] = YEAR(GETDATE()) AND   MONTH = 13
            GROUP BY ParentProjGUID
        ) xst ON pp.p_projectId = xst.ProjGUID
INNER     JOIN(SELECT    r.ParentProjGUID AS ProjGUID ,
                    SUM(ISNULL(tr.CCjBldArea, 0)) AS LjCCjBldArea ,
                    SUM(ISNULL(tr.CCjTotal, 0)) / 10000.0 AS LjCCjRoomTotal ,
                    COUNT(r.RoomGUID) AS LjCCCount,
                    SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  ) AS       ZzBnCCjBldArea ,
                    SUM(CASE WHEN r.TopProductTypeName ='住宅' AND DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0  THEN  ISNULL(tr.CCjRoomTotal, 0)   ELSE  0 END  ) AS ZzBnCCjRoomTotal ,
                    CASE WHEN  SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  ) =0  THEN 0 ELSE SUM(CASE WHEN r.TopProductTypeName ='住宅' AND DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0  THEN  ISNULL(tr.CCjRoomTotal, 0)   ELSE  0 END  ) / SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  )  END  AS ZzBnCCjAvgPrice,
                    SUM(CASE WHEN  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  ) AS BnCCjBldArea ,
                    SUM(CASE WHEN  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0  THEN  ISNULL(tr.CCjTotal, 0) / 10000.0  ELSE  0 END  ) AS BnCCjRoomTotal ,
                    sum(CASE WHEN  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0  THEN  1 ELSE  0 END  ) AS BnCCCount,
                    SUM(CASE WHEN DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 AND  sma.ApplyGUID IS NOT NULL THEN  1 ELSE  0 END  ) AS yqbgCount
            FROM  data_wide_s_Room r WITH(NOLOCK)
                INNER JOIN data_wide_s_Trade tr WITH(NOLOCK)ON tr.RoomGUID = r.RoomGUID AND tr.TradeStatus = '激活' AND   tr.IsLast = 1 
                OUTER APPLY (
                    SELECT  TOP  1  sm.ApplyGUID FROM  data_wide_s_SaleModiApply  sm WITH(NOLOCK) WHERE  sm.ApplyStatus = '已执行' AND sm.ApplyType IN ('延期付款','延期付款(签约)')  AND sm.RoomGUID =r.RoomGUID
                    AND sm.TradeGUID =tr.TradeGUID
                    ORDER BY  sm.ApplyDate DESC 
                )sma
            WHERE r.Status IN ('签约')
            GROUP BY r.ParentProjGUID
        ) con ON con.ProjGUID = pp.p_projectId
LEFT JOIN  (
    SELECT  g.ParentProjGUID AS ProjGUID,
    SUM(ISNULL(g.RmbAmount,0)/ 10000.0 ) AS LjRmbAmount, 
    SUM(CASE WHEN DATEDIFF(YEAR, ISNULL(g.SkDate,0), GETDATE()) = 0 THEN ISNULL(g.RmbAmount,0) / 10000.0  ELSE 0 END) AS BnRmbAmount  
    FROM   data_wide_s_Getin g WITH(NOLOCK)
    LEFT JOIN data_wide_s_Voucher v WITH(NOLOCK)ON g.VouchGUID = v.VouchGUID
    inner join data_wide_s_trade st on g.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
    WHERE g.VouchStatus <> '作废' AND  g.ItemType IN ('贷款类房款', '非贷款类房款','补充协议款' ) --and g.ItemName !='诚意金'
    GROUP BY  g.ParentProjGUID
) gg ON  gg.ProjGUID = pp.p_projectId
LEFT  JOIN  (
    SELECT 
        bld.ProjGUID AS ProjGUID, 
    --SUM(CASE WHEN  ISNULL(r.ScBldArea,0)<> 0  THEN  r.ScBldArea ELSE  r.YsBldArea END )  AS  BnQcchBldArea, 
        SUM(CASE WHEN datediff(YEAR,BLD.FactNotOpen,getdate())=0 THEN
            ( CASE WHEN r.MasterBldGUID IS null THEN bld.AvailableArea ELSE r.BldArea
            END)
        ELSE 0 END) AS BnxksBldArea,	--本年新开售面积
--楼栋的实际获取预售证时间为往年：取销售系统房间建筑面积汇总，剔除实际签约（含草签）日期在往年的房间，如房间状态为实测，取实测建筑面积，预售则取预计建筑面积；如果该楼栋没有创建房间，则全部取楼栋的总可售面积；
    --SUM(CASE WHEN BLD.FactNotOpen IS NULL THEN bld.AvailableArea ELSE 0 END) AS 	BnzjdjBldArea, --在建、待建面积	
        SUM(CASE WHEN  (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 ) 
             and  r.MasterBldGUID IS null and bld.FactNotOpen IS not null THEN bld.AvailableArea ELSE 
            (CASE WHEN  (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and  bld.FactNotOpen IS not null 
            and (DATEDIFF(YEAR,tr.CQsDate,GetDate())=0 OR tr.CQsDate IS null)THEN
                (CASE WHEN  ISNULL(r.ScBldArea,0)<> 0  THEN  r.ScBldArea ELSE  r.YsBldArea END)
            ELSE 0 END )
        END) AS BnQcchBldArea_QY, --签约口径本年期初库存	
            
        SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,tr.CQsDate, GETDATE() )  =0 
        THEN  tr.CCjBldArea ELSE  0 END  ) AS BnQCchCCjBldArea_QY,
        SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,tr.CQsDate, GETDATE() )  =0 
        THEN isnull( tr.CCjRoomTotal,0) /10000.0 ELSE  0 END  ) AS BnQCchCCjRoomTotal_QY,
                                
        --获取预售许可证日期-实际        
        SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   r.MasterBldGUID IS null and bld.FactNotOpen IS not null THEN bld.AvailableArea 
         ELSE 
                (CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and  bld.FactNotOpen IS not null and  
                (DATEDIFF(YEAR,r.x_YeJiTime,GetDate()) = 0 OR r.x_YeJiTime IS null) THEN
                    (CASE WHEN  ISNULL(r.ScBldArea,0)<> 0  THEN  r.ScBldArea ELSE  r.YsBldArea END)
                ELSE 0 END )
            END) AS BnQcchBldArea_YJ, --业绩口径本年期初库存	
                
        SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,r.x_YeJiTime, GETDATE() )  =0 
          THEN  tr.CCjBldArea ELSE  0 END  ) AS BnQCchCCjBldArea_YJ,
        SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,r.x_YeJiTime, GETDATE() )  =0 
          THEN isnull( tr.CCjRoomTotal,0) /10000.0 ELSE  0 END  ) AS BnQCchCCjRoomTotal_YJ  
    FROM data_wide_mdm_building bld WITH(NOLOCK)
        LEFT JOIN data_wide_s_Room r WITH(NOLOCK) ON bld.BuildingGUID = r.MasterBldGUID 
        left JOIN (
          select   CASE WHEN isnull(tr.x_InitialledDate,0)=0 and tr.CNetQsDate IS not null THEN  tr.CNetQsDate   
                     WHEN isnull(tr.x_InitialledDate,0)=0 and isnull(tr.CNetQsDate,0)=0 THEN NULL  
                   ELSE tr.x_InitialledDate END AS CQsDate, 
                   RoomGUID,tr.TradeStatus,tr.IsLast,tr.TradeGUID,tr.CCjBldArea,tr.CCjRoomTotal
                 from   data_wide_s_Trade  tr WITH (NOLOCK)
         )  tr  ON tr.RoomGUID = r.RoomGUID AND tr.TradeStatus = '激活' AND   tr.IsLast = 1 
        WHERE (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =0 OR bld.FactNotOpen is null) AND ( r.x_YeJiTime IS NULL  OR   DATEDIFF(year,r.x_YeJiTime,GETDATE() ) >=0) 
        GROUP BY bld.ProjGUID
) qcch ON qcch.ProjGUID = pp.p_projectId
LEFT JOIN (
    SELECT  p.p_projectId AS ProjGUID,
    SUM(ISNULL(SaleAmount,0)) AS SaleAmount,
    SUM(ISNULL(AvailableArea,0)) AS AvailableArea,
    CASE WHEN  SUM(ISNULL(AvailableArea,0))=0  THEN  0  ELSE  SUM(ISNULL(SaleAmount,0) )/SUM(ISNULL(AvailableArea,0)) END  AS mbAvgPrice
    FROM  data_wide_mdm_building bld WITH(NOLOCK)
    INNER JOIN  dbo.data_wide_mdm_Project p WITH(NOLOCK) ON bld.ProjectGuid =p.p_projectId AND  p.Level =2
    WHERE  TopProductTypeName ='住宅' 
    GROUP  BY  p.p_projectId
) mb  ON mb.ProjGUID =pp.p_projectId
LEFT JOIN(
    select 
        r.ParentProjGUID AS ProjGUID,
        SUM(CASE WHEN (DATEDIFF(YEAR,tr.CQsDate,GetDate())=0 and bld.TopProductTypeName='住宅')	THEN CjRmbTotal/10000.0 ELSE 0 END) AS sjqy,
        SUM(CASE WHEN (DATEDIFF(YEAR,x_YeJiTime,GetDate())=0 and bld.TopProductTypeName='住宅')	THEN CjRmbTotal/10000.0 ELSE 0 END) AS yjrdqy,	
        SUM(
        CASE WHEN DATEDIFF(YEAR,tr.CQsDate, GETDATE())=0 THEN(
        CASE WHEN r.wndjTotal IS not null THEN r.wndjTotal/10000.0  
        WHEN  DATEDIFF(YEAR,bld.FactNotOpen,GETDATE())=0 THEN bld.TargetUnitPrice*r.CjBldArea /10000.0 ELSE 0	 END)
        ELSE 0
        END			
        ) AS BnsjqyMoney, --实际签约金额汇总

        SUM(
        CASE WHEN DATEDIFF(YEAR,r.x_YeJiTime, GETDATE())=0 THEN(
        CASE WHEN  r.wndjTotal IS not null THEN r.wndjTotal/10000.0
        WHEN  DATEDIFF(YEAR,bld.FactNotOpen,GETDATE())=0 THEN bld.TargetUnitPrice*r.CjBldArea/10000.0 ELSE 0	 END)
        ELSE 0 END			
        ) AS BnyjMoney	--业绩认定签约金额汇总	
    from data_wide_s_Room r
    LEFT JOIN data_wide_mdm_building bld WITH(NOLOCK) ON  r.MasterBldGUID =bld.BuildingGUID 
    inner JOIN  (
      select  tr.RoomGUID,tr.TradeStatus,tr.IsLast,tr.TradeGUID,tr.CCjBldArea,tr.CCjRoomTotal,
      CASE WHEN isnull(tr.x_InitialledDate,0)=0 and tr.CNetQsDate IS not null THEN  tr.CNetQsDate   
                     WHEN isnull(tr.x_InitialledDate,0)=0 and isnull(tr.CNetQsDate,0)=0 THEN NULL  
                   ELSE tr.x_InitialledDate END AS CQsDate
      from data_wide_s_Trade tr WITH(NOLOCK)
    )  tr ON tr.RoomGUID = r.RoomGUID  AND  tr.TradeStatus='激活' AND   tr.IsLast = 1
where r.TopProductTypeName ='住宅' --只统计住宅				
GROUP  BY  r.ParentProjGUID			
) bd on bd.ProjGUID=pp.p_projectId
LEFT JOIN(
    select bld.ProjGUID,
        SUM(CASE WHEN BLD.FactNotOpen IS NULL THEN bld.AvailableArea ELSE 0 END) AS 	BnzjdjBldArea --在建、待建面积	
        from data_wide_mdm_building bld
        group by bld.ProjGUID
) mj on mj.ProjGUID=pp.p_projectId
WHERE   pp.Level = 2   
    AND pp.p_projectId IN (@ProjGUID)
END
ELSE
BEGIN
    select 
        [snapshot_time],
        [version],
        [项目],
        [BUGUID],
        [p_projectId],
        [管理主体],
        [片区],
        [合约销售额考核值集团版],
        [销售回款额考核制集团版],
        [合约销售额考核值内控版],
        [销售回款额考核值内控版],
        [从开盘至今的累计销售套数],
        [从开盘至今的累计销售面积],
        [从开盘至今的累计销售金额],
        [从开盘至今的累计回款金额],
        [本年至今的累计销售签约套数],
        [本年至今的累计销售签约面积],
        [本年至今的累计销售签约金额],
        [本年至今的累计销售签约集团版达成率],
        [本年至今的累计销售签约内控版达成率],
        [本年至今累计回款金额],
        [本年至今累计回款集团版达成率],
        [本年至今累计回款内控版达成率],
        [本年新开售面积],
        [在建待建面积],
        [本年期初库存面积签约],
        [截止当前库存签约面积签约口径],
        [截止当前库存签约金额签约口径],
        [本年期初库存去化情况库存去化率签约],
        [本年期初库存面积业绩],
        [截止当前库存签约面积业绩口径],
        [截止当前库存签约金额业绩口径],
        [本年期初库存去化情况库存去化率业绩],
        [实际签约金额],
        [业绩认定签约金额],
        [本年实际签约底价金额汇总],
        [本年业绩认定底价金额汇总],
        [货值变动率1],
        [货值变动率2],
        [延期付款变更率]
    from result_kh_zb_snapshot
    where [version] = @版本号
        and [p_projectId] in (@ProjGUID)
END