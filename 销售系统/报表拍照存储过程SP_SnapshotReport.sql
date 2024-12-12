USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[SP_SnapshotReport]    Script Date: 2024/12/11 11:40:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
存储过程功能说明:拍照报表,用于定时生成报表数据快照

插入表说明:
1. 考核指标完成情况 (result_kh_zb_snapshot)
2. 本年业绩认定房源明细 (result_room_yjrd_snapshot) 
3. 本年签约房源明细 (Result_YearlySignedRooms)
4. 项目签约回款汇总表 (Result_ProjectSigningPaymentSummary)
5. 房源台账明细表(全表) (Result_RoomLedgerDetail)
6. 未收款项明细表(含逾期款) (Result_UnpaidAmountDetail)
7. 实收款项明细表(全表)-含回款到账日期 (Result_ReceivedPaymentDetail)
8. 本年至今回笼金额明细表 (Result_ThisYearGetAmountDetail)
*/

-- 创建存储过程
ALTER   PROCEDURE [dbo].[SP_SnapshotReport]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage nvarchar(4000);
    DECLARE @SnapshotTime datetime = GETDATE();
    DECLARE @VersionNo varchar(50) = CONVERT(varchar(10), @SnapshotTime, 112);
    DECLARE @ExecuteMode varchar(50) = 'AUTO';
    
    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '01-ZSDC-01-考核指标完成情况 ',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        -- 01-ZSDC-01-考核指标完成情况 
        -- 插入数据
        INSERT INTO [dbo].[result_kh_zb_snapshot] (
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
        )
        SELECT 
            GETDATE() AS snapshot_time,
            CONVERT(VARCHAR(10),GETDATE(),23) AS version,
            CASE WHEN ISNULL(pp.SpreadName, '') <> '' THEN ISNULL(pp.SpreadName, '') ELSE pp.ProjName END AS 项目,
            pp.BUGUID,
            pp.p_projectId,
            pp.x_ManagementSubject AS 管理主体,
            pp.x_area AS 片区,
            xst.BudgetContractAmount AS 合约销售额考核值集团版,
            xst.BudgetGetinAmount AS 销售回款额考核制集团版,
            NULL AS 合约销售额考核值内控版,
            NULL AS 销售回款额考核值内控版,
            con.LjCCCount AS 从开盘至今的累计销售套数,
            con.LjCCjBldArea AS 从开盘至今的累计销售面积,
            con.LjCCjRoomTotal AS 从开盘至今的累计销售金额,
            gg.LjRmbAmount AS 从开盘至今的累计回款金额,
            con.BnCCCount AS 本年至今的累计销售签约套数,
            con.BnCCjBldArea AS 本年至今的累计销售签约面积,
            con.BnCCjRoomTotal AS 本年至今的累计销售签约金额,
            CASE WHEN ISNULL(xst.BudgetContractAmount,0) = 0 THEN 0 ELSE ISNULL(con.BnCCjRoomTotal,0)/ISNULL(xst.BudgetContractAmount,0) END AS 本年至今的累计销售签约集团版达成率,
            NULL AS 本年至今的累计销售签约内控版达成率,
            gg.BnRmbAmount AS 本年至今累计回款金额,
            CASE WHEN ISNULL(xst.BudgetGetinAmount,0) = 0 THEN 0 ELSE ISNULL(gg.BnRmbAmount,0)/ISNULL(xst.BudgetGetinAmount,0) END AS 本年至今累计回款集团版达成率,
            NULL AS 本年至今累计回款内控版达成率,
            qcch.BnxksBldArea AS 本年新开售面积,
            mj.BnzjdjBldArea AS 在建待建面积,
            qcch.BnQcchBldArea_QY AS 本年期初库存面积签约,
            qcch.BnQCchCCjBldArea_QY AS 截止当前库存签约面积签约口径,
            qcch.BnQCchCCjRoomTotal_QY AS 截止当前库存签约金额签约口径,
            CASE WHEN ISNULL(qcch.BnQcchBldArea_QY,0) = 0 THEN 0 ELSE ISNULL(qcch.BnQCchCCjBldArea_QY,0)/ISNULL(qcch.BnQcchBldArea_QY,0) END AS 本年期初库存去化情况库存去化率签约,
            qcch.BnQcchBldArea_YJ AS 本年期初库存面积业绩,
            qcch.BnQCchCCjBldArea_YJ AS 截止当前库存签约面积业绩口径,
            qcch.BnQCchCCjRoomTotal_YJ AS 截止当前库存签约金额业绩口径,
            CASE WHEN ISNULL(qcch.BnQcchBldArea_YJ,0) = 0 THEN 0 ELSE ISNULL(qcch.BnQCchCCjBldArea_YJ,0)/ISNULL(qcch.BnQcchBldArea_YJ,0) END AS 本年期初库存去化情况库存去化率业绩,
            bd.sjqy AS 实际签约金额,
            bd.yjrdqy AS 业绩认定签约金额,
            bd.BnsjqyMoney AS 本年实际签约底价金额汇总,
            bd.BnyjMoney AS 本年业绩认定底价金额汇总,
            CASE WHEN bd.BnsjqyMoney = 0 THEN 0 ELSE (bd.sjqy-bd.BnsjqyMoney)/bd.BnsjqyMoney END AS 货值变动率1,
            CASE WHEN bd.BnyjMoney = 0 THEN 0 ELSE (bd.yjrdqy-bd.BnyjMoney)/bd.BnyjMoney END AS 货值变动率2,
            CASE WHEN ISNULL(con.BnCCCount,0) = 0 THEN 0 ELSE ISNULL(con.yqbgCount,0) * 1.0/ISNULL(con.BnCCCount,0) END AS 延期付款变更率
        FROM data_wide_mdm_Project pp
       LEFT JOIN(SELECT    ParentProjGUID AS ProjGUID ,
                    SUM(ISNULL(BudgetContractAmount, 0)) AS BudgetContractAmount ,
                    SUM(ISNULL(BudgetGetinAmount, 0)) AS BudgetGetinAmount
            FROM  data_wide_s_SalesBudget
            WHERE [YEAR] = YEAR(GETDATE()) AND   MONTH = 13
            GROUP BY ParentProjGUID
        ) xst ON pp.p_projectId = xst.ProjGUID
        INNER     JOIN(SELECT    r.ParentProjGUID AS ProjGUID ,
                            -- SUM(ISNULL(tr.CCjBldArea, 0)) AS LjCCjBldArea ,
                            SUM(ISNULL(r.bldarea, 0)) AS LjCCjBldArea ,
                            SUM(ISNULL(tr.CCjTotal, 0)) / 10000.0 AS LjCCjRoomTotal ,
                            COUNT(r.RoomGUID) AS LjCCCount,
                            -- SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  ) AS       ZzBnCCjBldArea ,
                            SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(r.bldarea, 0) ELSE  0  END  ) AS       ZzBnCCjBldArea ,
                            SUM(CASE WHEN r.TopProductTypeName ='住宅' AND DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0  THEN  ISNULL(tr.CCjRoomTotal, 0)   ELSE  0 END  ) AS ZzBnCCjRoomTotal ,
                            CASE WHEN  SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  ) =0  THEN 0 ELSE SUM(CASE WHEN r.TopProductTypeName ='住宅' AND DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0  THEN  ISNULL(tr.CCjRoomTotal, 0)   ELSE  0 END  ) / SUM(CASE WHEN r.TopProductTypeName ='住宅' AND  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  )  END  AS ZzBnCCjAvgPrice,
                            --SUM(CASE WHEN  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(tr.CCjBldArea, 0) ELSE  0  END  ) AS BnCCjBldArea ,
                            SUM(CASE WHEN  DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0 THEN   ISNULL(r.bldarea, 0) ELSE  0  END  ) AS BnCCjBldArea ,
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
                    
                -- SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,tr.CQsDate, GETDATE() )  =0  THEN  tr.CCjBldArea ELSE  0 END  ) AS BnQCchCCjBldArea_QY,
                SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,tr.CQsDate, GETDATE() )  =0  THEN  r.bldarea ELSE  0 END  ) AS BnQCchCCjBldArea_QY,
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
                        
                -- SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,r.x_YeJiTime, GETDATE() )  =0  THEN  tr.CCjBldArea ELSE  0 END  ) AS BnQCchCCjBldArea_YJ,
                SUM(CASE WHEN (DATEDIFF(YEAR, bld.FactNotOpen,GETDATE())> =1 )  and   DATEDIFF(YEAR,r.x_YeJiTime, GETDATE() )  =0  THEN  r.bldarea ELSE  0 END  ) AS BnQCchCCjBldArea_YJ,
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
        WHERE pp.Level = 2   
            --AND pp.p_projectId IN(@ProjGUID)


        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '01-ZSDC-01-考核指标完成情况 '
            AND StartTime = @SnapshotTime;

    END TRY

    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '01-本年业绩认定房源明细'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '01-本年业绩认定房源明细 ',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        --01-本年业绩认定房源明细
        -- 插入数据
        INSERT INTO [dbo].[result_room_yjrd_snapshot] (
            [snapshot_time],
            [version],
            [buguid],
            [projguid],
            [项目],
            [签约日期],
            [业绩认定日期],
            [房间编号],
            [房间信息],
            [成交总价],
            [往年最后一次定价金额],
            [目标均价],
            [签约面积]
        )
        SELECT 
            GETDATE() AS snapshot_time,
            CONVERT(VARCHAR(10),GETDATE(),23) AS version,
            r.BUGUID AS buguid,
            r.ParentProjGUID AS projguid,
            r.ParentProjName AS 项目,
            CONVERT(nvarchar(10), tr.CQsDate, 111) AS 签约日期,
            CONVERT(nvarchar(10), r.x_YeJiTime, 111) AS 业绩认定日期,
            r.RoomGUID AS 房间编号,
            r.RoomInfo AS 房间信息,
            r.CjRmbTotal AS 成交总价,
            r.wndjTotal AS 往年最后一次定价金额,
            bld.TargetUnitPrice AS 目标均价,
            r.CjBldArea AS 签约面积
        FROM data_wide_s_room r
        LEFT JOIN data_wide_mdm_building bld WITH(NOLOCK) 
            ON r.MasterBldGUID = bld.BuildingGUID 
        INNER JOIN data_wide_s_Trade tr WITH(NOLOCK)
            ON tr.RoomGUID = r.RoomGUID 
            AND CStatus = '激活' 
            AND tr.IsLast = 1
        WHERE DATEDIFF(YEAR, r.x_YeJiTime, GETDATE()) = 0
            AND r.TopProductTypeName = '住宅';
        

        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '01-本年业绩认定房源明细'
            AND StartTime = @SnapshotTime;

    END TRY
    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '01-本年业绩认定房源明细'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '01-本年签约房源明细',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        --01-本年签约房源明细
        -- 插入数据
        INSERT INTO Result_YearlySignedRooms (
            snapshot_time,
            [version],
            BUGUID,
            ParentProjGUID,
            项目,
            签约日期,
            业绩认定日期,
            房间编号,
            房间信息,
            成交总价,
            往年最后一次定价金额,
            目标均价,
            签约面积
        )
        select
            GETDATE() AS SnapshotTime,
            CONVERT(VARCHAR(10),GETDATE(),23) AS Version,
            r.BUGUID AS BUGUID,
            r.ParentProjGUID AS ProjGUID,
            r.ParentProjName AS ProjectName,
            convert(nvarchar(10),tr.CQsDate,111) AS SignDate,
            convert(nvarchar(10),r.x_YeJiTime,111) AS PerformanceDate,
            r.RoomGUID,
            r.RoomInfo,
            r.CjRmbTotal AS TotalPrice,
            r.wndjTotal AS LastYearPrice,
            bld.TargetUnitPrice,
            r.CjBldArea AS SignedArea
        from data_wide_s_room r
        LEFT JOIN data_wide_mdm_building bld WITH(NOLOCK) ON  r.MasterBldGUID =bld.BuildingGUID 
        inner JOIN  (
            select   CASE WHEN isnull(tr.x_InitialledDate,0)=0 and tr.CNetQsDate IS not null THEN  tr.CNetQsDate   
                        WHEN isnull(tr.x_InitialledDate,0)=0 and isnull(tr.CNetQsDate,0)=0 THEN NULL  
                    ELSE tr.x_InitialledDate END AS CQsDate, 
                    RoomGUID,tr.TradeStatus,tr.IsLast,tr.TradeGUID,tr.CCjBldArea,tr.CCjRoomTotal,CStatus
                    from   data_wide_s_Trade  tr WITH (NOLOCK)
        ) tr ON tr.RoomGUID = r.RoomGUID  AND  CStatus='激活' AND   tr.IsLast = 1
        where DATEDIFF(YEAR,tr.CQsDate,GETDATE())=0 
        and r.TopProductTypeName ='住宅' --只统计住宅	      

        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '01-本年签约房源明细'
            AND StartTime = @SnapshotTime;

    END TRY
    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '01-本年签约房源明细'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '02-zsdc-04-项目签约回款汇总表',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        --02-zsdc-04-项目签约回款汇总表
        -- 创建临时表并插入数据
        -- 1. 业绩情况临时表
        IF OBJECT_ID('tempdb..#业绩情况') IS NOT NULL DROP TABLE #业绩情况
        SELECT 
            sr.buguid,
            st.parentprojguid,
            st.parentprojname,
            pro.SpreadName,
            sum(case when st.cstatus='激活' and year(sr.x_yejitime)=year(getdate()) and isnull(st.producttypename,'')<>'车位' then 1 else 0 end) as 本年业绩认定非车位套数,
            sum(case when st.cstatus='激活' and year(sr.x_yejitime)=year(getdate()) and st.producttypename='车位' then 1 else 0 end) as 本年业绩认定车位套数,
            sum(case when st.cstatus='激活' and year(sr.x_yejitime)=year(getdate()) then st.ccjtotal else 0 end) as 本年业绩认定成交金额,
            sum(case when st.cstatus='激活' AND sr.x_yejitime IS NULL and year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) and isnull(st.producttypename,'')<>'车位'  then 1 else 0 end) as 本年已签约非车位套数,
            sum(case when st.cstatus='激活' AND sr.x_yejitime IS NULL and year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) and st.producttypename='车位'   then 1 else 0 end) as 本年已签约车位套数,
            sum(case when st.cstatus='激活' AND sr.x_yejitime IS NULL and year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) then st.ccjtotal else 0 end) as 本年已签约成交金额,
            sum(case when st.ostatus='激活' and isnull(st.producttypename,'')<>'车位' then 1 else 0 end) as 认购未签约非车位套数,		
            sum(case when st.ostatus='激活' and st.producttypename='车位' then 1 else 0 end) as 认购未签约车位套数,	
            sum(case when st.ostatus='激活' then st.ocjtotal else 0 end) as 认购未签约成交金额,	
            sum(case when st.ostatus='激活' and datediff(dd,isnull(st.x_YjInitialledDate,st.yqydate),getdate())<0 and isnull(st.producttypename,'')<>'车位' then 1 else 0 end) as 认购未签约逾期非车位套数,		
            sum(case when st.ostatus='激活' and datediff(dd,isnull(st.x_YjInitialledDate,st.yqydate),getdate())<0 and st.producttypename='车位' then 1 else 0 end) as 认购未签约逾期车位套数,	
            sum(case when st.ostatus='激活' and datediff(dd,isnull(st.x_YjInitialledDate,st.yqydate),getdate())<0 then st.ocjtotal else 0 end) as 认购未签约逾期成交金额,		
            sum(case when st.ostatus='激活' and datediff(dd,isnull(st.x_YjInitialledDate,st.yqydate),getdate())>=0 and isnull(st.producttypename,'')<>'车位' then 1 else 0 end) as 认购未签约未到期非车位套数,		
            sum(case when st.ostatus='激活' and datediff(dd,isnull(st.x_YjInitialledDate,st.yqydate),getdate())>=0 and st.producttypename='车位' then 1 else 0 end) as 认购未签约未到期车位套数,	
            sum(case when st.ostatus='激活' and datediff(dd,isnull(st.x_YjInitialledDate,st.yqydate),getdate())>=0 then st.ocjtotal else 0 end) as 认购未签约未到期成交金额
        INTO #业绩情况
        FROM data_wide_s_trade st 
        LEFT JOIN data_wide_s_room sr on st.roomguid=sr.roomguid 
        LEFT JOIN data_wide_mdm_project pro on st.parentprojguid=pro.p_projectid
        WHERE (st.cstatus='激活' or st.ostatus='激活')
            --and st.projguid in (@projguid)
        GROUP BY 
            sr.BUGUID,
            st.parentprojguid,
            st.parentprojname,
            pro.SpreadName

        -- 2. 回款情况临时表
        IF OBJECT_ID('tempdb..#回款情况') IS NOT NULL DROP TABLE #回款情况
        SELECT 
            st.parentprojguid,
            sum(sg.amount) as 本年已回款
        INTO #回款情况
        FROM data_wide_s_getin sg 
        INNER JOIN data_wide_s_trade st on sg.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
        WHERE sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
            and isnull(sg.vouchstatus,'') !='作废'
            and year(sg.skdate)=year(getdate())
            --and st.projguid in (@projguid)
        GROUP BY 
            st.parentprojguid

        -- 3. 退款情况临时表
        IF OBJECT_ID('tempdb..#退款情况') IS NOT NULL DROP TABLE #退款情况
        SELECT 
            st.parentprojguid,
            sum(sg.amount) as 本年已退款
        INTO #退款情况
        FROM data_wide_s_getin sg 
        INNER JOIN data_wide_s_trade st on sg.SaleGUID=st.tradeguid and st.TradeStatus='关闭' AND st.OCloseReason ='退房'
        WHERE sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
            and isnull(sg.vouchstatus,'') !='作废'
            and year(sg.skdate)=year(getdate())
            and sg.vouchtype='退款单'
            --and st.projguid in (@projguid)
        GROUP BY 
            st.parentprojguid

        -- 4. 应收情况临时表
        IF OBJECT_ID('tempdb..#应收情况') IS NOT NULL DROP TABLE #应收情况
        SELECT 
            st.parentprojguid,
            sum(case when datediff(dd,sf.lastdate,getdate())<0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 逾期非按揭款,
            sum(case when datediff(dd,sf.lastdate,getdate())>=0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 未到期非按揭款,
            sum(case when sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 按揭款,
            sum(case when sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 非贷款类房款,
            sum(case when sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 补充协议款,
            sum(case when st.ostatus='激活' and datediff(dd,sf.lastdate,getdate())<0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已认购未签约逾期非按揭款,
            sum(case when st.ostatus='激活' and datediff(dd,sf.lastdate,getdate())>=0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已认购未签约未到期非按揭款,
            sum(case when st.ostatus='激活' and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 已认购未签约按揭款,
            sum(case when st.ostatus='激活' and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 已认购未签约非贷款类房款,
            sum(case when st.ostatus='激活' and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 已认购未签约补充协议款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null and datediff(dd,sf.lastdate,getdate())<0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已草签未网签逾期非按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null and datediff(dd,sf.lastdate,getdate())>=0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已草签未网签未到期非按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 已草签未网签按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 已草签未网签非贷款类房款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 已草签未网签补充协议款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) < YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 往年已草签未网签按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) < YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 往年已草签未网签非贷款类房款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) < YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 往年已草签未网签补充协议款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) = YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 本年已草签未网签按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) = YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 本年已草签未网签非贷款类房款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) = YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 本年已草签未网签补充协议款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null and datediff(dd,sf.lastdate,getdate())<0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已网签逾期非按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null and datediff(dd,sf.lastdate,getdate())>=0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已网签未到期非按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 已网签按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 已网签非贷款类房款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 已网签补充协议款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) < YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 往年已网签按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) < YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 往年已网签非贷款类房款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) < YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 往年已网签补充协议款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) = YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 本年已网签按揭款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) = YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 本年已网签非贷款类房款,
            sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) = YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 本年已网签补充协议款
        INTO #应收情况
        FROM data_wide_s_fee sf 
        INNER JOIN data_wide_s_trade st on sf.tradeguid=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
        WHERE sf.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
            and sf.rmbye<>0
            --and st.projguid in (@projguid)
        GROUP BY 
            st.parentprojguid

        -- 5. 销售计划临时表
        IF OBJECT_ID('tempdb..#销售计划') IS NOT NULL DROP TABLE #销售计划
        SELECT 
            mb.parentprojguid,
            sum(case when mb.year=year(getdate()) and mb.month=13 then mb.BudgetContractAmount else 0 end) as 本年签约指标,
            sum(case when mb.year=year(getdate()) and mb.month=13 then mb.BudgetGetinAmount else 0 end) as 本年回款指标
        INTO #销售计划
        FROM data_wide_s_SalesBudget mb 
        --WHERE mb.projguid in (@projguid)
        GROUP BY mb.parentprojguid

        -- 插入最终结果到结果表
        INSERT INTO Result_ProjectSigningPaymentSummary (
            SnapshotTime,
            VersionNo,
            BUGUID,
            ProjGUID,
            项目名称,
            项目推广名称,
            本年签约指标集团版,
            本年签约指标内控版,
            本年业绩认定非车位套数,
            本年业绩认定车位套数,
            本年业绩认定成交金额,
            本年签约完成率集团版,
            本年签约完成率内控版,
            本年已签约非车位套数,
            本年已签约车位套数,
            本年已签约成交金额,
            认购未签约非车位套数,
            认购未签约车位套数,
            认购未签约成交金额,
            认购未签约逾期非车位套数,
            认购未签约逾期车位套数,
            认购未签约逾期成交金额,
            认购未签约未到期非车位套数,
            认购未签约未到期车位套数,
            认购未签约未到期成交金额,
            本年回款指标集团版,
            本年回款指标内控版,
            本年已回款,
            本年已退款,
            本年回款完成率集团版,
            本年回款完成率内控版,
            逾期非按揭款,
            未到期非按揭款,
            按揭款,
            补充协议款,
            非贷款类房款,
            已认购未签约逾期非按揭款,
            已认购未签约未到期非按揭款,
            已认购未签约按揭款,
            已认购未签约非贷款类房款,
            已认购未签约补充协议款,
            已草签未网签逾期非按揭款,
            已草签未网签未到期非按揭款,
            已草签未网签按揭款,
            已草签未网签非贷款类房款,
            已草签未网签补充协议款,
            往年已草签未网签按揭款,
            往年已草签未网签非贷款类房款,
            往年已草签未网签补充协议款,
            本年已草签未网签按揭款,
            本年已草签未网签非贷款类房款,
            本年已草签未网签补充协议款,
            已网签逾期非按揭款,
            已网签未到期非按揭款,
            已网签按揭款,
            已网签非贷款类房款,
            已网签补充协议款,
            往年已网签按揭款,
            往年已网签非贷款类房款,
            往年已网签补充协议款,
            本年已网签按揭款,
            本年已网签非贷款类房款,
            本年已网签补充协议款
        )
        SELECT 
            GETDATE() AS SnapshotTime,
            CONVERT(VARCHAR(10),GETDATE(),23) AS VersionNo,
            st.buguid AS BUGUID,
            st.parentprojguid AS ProjGUID,
            st.parentprojname as 项目名称,
            st.SpreadName as 项目推广名称,
            isnull(mb.本年签约指标,0) as 本年签约指标集团版,
            0 as 本年签约指标内控版,
            isnull(st.本年业绩认定非车位套数,0) as 本年业绩认定非车位套数,
            isnull(st.本年业绩认定车位套数,0) as 本年业绩认定车位套数,
            isnull(st.本年业绩认定成交金额,0)*0.0001 as 本年业绩认定成交金额,
            isnull((st.本年业绩认定成交金额*0.0001)/(nullif(mb.本年签约指标,0)),0) as 本年签约完成率集团版,
            0 as 本年签约完成率内控版,
            isnull(st.本年已签约非车位套数,0) as 本年已签约非车位套数,
            isnull(st.本年已签约车位套数,0) as 本年已签约车位套数,
            isnull(st.本年已签约成交金额,0)*0.0001 as 本年已签约成交金额,
            isnull(st.认购未签约非车位套数,0) as 认购未签约非车位套数,		
            isnull(st.认购未签约车位套数,0) as 认购未签约车位套数,	
            isnull(st.认购未签约成交金额,0)*0.0001 as 认购未签约成交金额,	
            isnull(st.认购未签约逾期非车位套数,0) as 认购未签约逾期非车位套数,		
            isnull(st.认购未签约逾期车位套数,0) as 认购未签约逾期车位套数,	
            isnull(st.认购未签约逾期成交金额,0)*0.0001 as 认购未签约逾期成交金额,		
            isnull(st.认购未签约未到期非车位套数,0) as 认购未签约未到期非车位套数,		
            isnull(st.认购未签约未到期车位套数,0) as 认购未签约未到期车位套数,	
            isnull(st.认购未签约未到期成交金额,0)*0.0001 as 认购未签约未到期成交金额,
            isnull(mb.本年回款指标,0) as 本年回款指标集团版,
            0 as 本年回款指标内控版,	
            isnull(sg.本年已回款,0)*0.0001 as 本年已回款,
            isnull(tk.本年已退款,0)*0.0001 AS 本年已退款,
            isnull(sg.本年已回款*0.0001/nullif(mb.本年回款指标,0),0) as 本年回款完成率集团版,
            0 as 本年回款完成率内控版,	
            isnull(sf.逾期非按揭款,0)*0.0001 as 逾期非按揭款, 
            isnull(sf.未到期非按揭款,0)*0.0001 as 未到期非按揭款, 
            isnull(sf.按揭款,0)*0.0001 as 按揭款,  
            isnull(sf.补充协议款,0)*0.0001 as 补充协议款, 
            isnull(sf.非贷款类房款,0)*0.0001 as 非贷款类房款, 
            isnull(sf.已认购未签约逾期非按揭款,0)*0.0001 as 已认购未签约逾期非按揭款, 
            isnull(sf.已认购未签约未到期非按揭款,0)*0.0001 as 已认购未签约未到期非按揭款, 
            isnull(sf.已认购未签约按揭款,0)*0.0001 as 已认购未签约按揭款, 
            isnull(sf.已认购未签约非贷款类房款,0)*0.0001 as 已认购未签约非贷款类房款, 
            isnull(sf.已认购未签约补充协议款,0)*0.0001 as 已认购未签约补充协议款,
            isnull(sf.已草签未网签逾期非按揭款,0)*0.0001 as 已草签未网签逾期非按揭款, 
            isnull(sf.已草签未网签未到期非按揭款,0)*0.0001 as 已草签未网签未到期非按揭款, 
            isnull(sf.已草签未网签按揭款,0)*0.0001 as 已草签未网签按揭款, 
            isnull(sf.已草签未网签非贷款类房款,0)*0.0001 as 已草签未网签非贷款类房款, 
            isnull(sf.已草签未网签补充协议款,0)*0.0001 as 已草签未网签补充协议款, 
            isnull(sf.往年已草签未网签按揭款,0)*0.0001 as 往年已草签未网签按揭款, 
            isnull(sf.往年已草签未网签非贷款类房款,0)*0.0001 as 往年已草签未网签非贷款类房款, 
            isnull(sf.往年已草签未网签补充协议款,0)*0.0001 as 往年已草签未网签补充协议款, 
            isnull(sf.本年已草签未网签按揭款,0)*0.0001 as 本年已草签未网签按揭款, 
            isnull(sf.本年已草签未网签非贷款类房款,0)*0.0001 as 本年已草签未网签非贷款类房款, 
            isnull(sf.本年已草签未网签补充协议款,0)*0.0001 as 本年已草签未网签补充协议款, 
            isnull(sf.已网签逾期非按揭款,0)*0.0001 as 已网签逾期非按揭款, 
            isnull(sf.已网签未到期非按揭款,0)*0.0001 as 已网签未到期非按揭款, 
            isnull(sf.已网签按揭款,0)*0.0001 as 已网签按揭款, 
            isnull(sf.已网签非贷款类房款,0)*0.0001 as 已网签非贷款类房款,
            isnull(sf.已网签补充协议款,0)*0.0001 as 已网签补充协议款,
            isnull(sf.往年已网签按揭款,0)*0.0001 as 往年已网签按揭款, 
            isnull(sf.往年已网签非贷款类房款,0)*0.0001 as 往年已网签非贷款类房款,
            isnull(sf.往年已网签补充协议款,0)*0.0001 as 往年已网签补充协议款,
            isnull(sf.本年已网签按揭款,0)*0.0001 as 本年已网签按揭款, 
            isnull(sf.本年已网签非贷款类房款,0)*0.0001 as 本年已网签非贷款类房款,
            isnull(sf.本年已网签补充协议款,0)*0.0001 as 本年已网签补充协议款
        FROM #业绩情况 st
        LEFT JOIN #回款情况 sg on st.parentprojguid=sg.parentprojguid
        LEFT JOIN #应收情况 sf on st.parentprojguid=sf.parentprojguid
        LEFT JOIN #销售计划 mb on st.parentprojguid=mb.parentprojguid
        LEFT JOIN #退款情况 tk on st.parentprojguid=tk.parentprojguid;
        
        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '02-zsdc-04-项目签约回款汇总表'
            AND StartTime = @SnapshotTime;

        -- 清理临时表
        DROP TABLE #业绩情况
        DROP TABLE #回款情况
        DROP TABLE #退款情况
        DROP TABLE #应收情况
        DROP TABLE #销售计划

    END TRY
    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '02-zsdc-04-项目签约回款汇总表'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '03-ZSDC-01-房源台账明细表(全表)',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        --03-ZSDC-01-房源台账明细表(全表)
        -- 插入数据        
        INSERT INTO [dbo].[Result_RoomLedgerDetail](
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
        )
        SELECT  
                GETDATE() AS SnapshotTime,
                CONVERT(VARCHAR(10),GETDATE(),23) AS VersionNo,

                p.BUGUID,
                p.p_projectId,
                (CASE WHEN r.TopProductTypeName IN ('住宅', '车位', '其他', '办公') THEN r.TopProductTypeName  
                                WHEN r.TopProductTypeName = '商业' AND  r.ProductTypeName = '公寓' THEN '公寓'  
                                WHEN r.TopProductTypeName = '商业' AND  r.ProductTypeName <> '公寓' THEN '商业'  
                WHEN r.TopProductTypeName IS NULL THEN  '其他'  
                            END) as ProductType,

                p.p_projectId ,  
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
                    
                CASE WHEN ISNULL(tr.x_InitialledDate,0)=0 AND tr.CNetQsDate IS NOT NULL THEN  tr.CNetQsDate   
                        WHEN ISNULL(tr.x_InitialledDate,0)=0 AND ISNULL(tr.CNetQsDate,0)=0 THEN NULL  
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
                ISNULL(SsAj,0.00) AS 按揭放款金额, 
                ISNULL(CGjjTotal,OGjjTotal ) AS 公积金贷款金额 ,  
                ISNULL(ssgjj,0.00) AS 公积金放款金额,
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
                ss2.je AS 首期实收金额,
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
                ISNULL(ISNULL(tr.CCjTotal, tr.OCjTotal), 0)+ISNULL(tr.BcTotal, 0) + ISNULL(tr.FsBcTotal, 0) AS 面积补差后实际成交金额,  
                CASE WHEN (ISNULL(tr.CCjTotal, tr.OCjTotal) >0 
                AND ISNULL(ISNULL(tr.CCjTotal, tr.OCjTotal), 0)+ISNULL(tr.BcTotal, 0) + 
                ISNULL(tr.FsBcTotal, 0)-ISNULL(gg.getRmbAmount,0)=0 ) 
                THEN '已收齐' ELSE '' END AS 是否已收齐房款,  
                CASE WHEN ISNULL(gg.getRmbAmount,0)-ISNULL(bcg.getRmbAmount,0) - 
                ISNULL(tr.CCjTotal, tr.OCjTotal) = 0 
                THEN '已收齐' ELSE '' END AS 不含补差房款是否已收齐,  
                CASE WHEN ISNULL(gg.getRmbAmount,0) >=  ISNULL (YS.YSRmbAmount,0) 
                AND ISNULL (YS.YSRmbAmount,0) !=0  THEN '已收齐' ELSE '' END AS 房款是否收齐,  
                CASE WHEN ISNULL(bcg.getRmbAmount,0) >= ISNULL(buchaYS.bcYS,0) 
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
                ISNULL(ISNULL(tr.CProjectTeam, tr.OProjectTeam),
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
                tr.AgeStage AS 年龄段 ,
                tr.ccjbldarea as 合同单面积,
                tr.ocjbldarea as 认购单面积
        FROM    dbo.data_wide_mdm_Project p WITH (NOLOCK )  
        INNER JOIN data_wide_mdm_Project pp WITH (NOLOCK ) 
        ON p.ParentGUID = pp.p_projectId AND pp.Level = 2  
        INNER JOIN data_wide_s_Room r WITH (NOLOCK ) ON p.p_projectId = r.ProjGUID  
        -- LEFT JOIN p_hhyroom x ON x.RoomGUID = r.RoomGUID  
        LEFT JOIN data_wide_dws_s_roomexpand vrr WITH (NOLOCK ) ON vrr.RoomGUID = r.RoomGUID  
        --LEFT JOIN  data_wide_s_SaleHsData  shd on  Status = '激活' shd ON   shd.RoomGUID =r.RoomGUID  
        LEFT JOIN data_wide_s_Trade tr  WITH (NOLOCK ) 
        ON tr.RoomGUID = r.RoomGUID AND tr.TradeStatus = '激活' AND   tr.IsLast = 1  
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
        WHERE ItemType = '非贷款类房款' AND  ItemName LIKE '%补差%'  GROUP BY TradeGUID ) AS buchaYS ON buchaYS.TradeGUID = tr.TradeGUID   
        --补差实收金额  
        LEFT JOIN  (  
        SELECT g.SaleGUID, SUM(ISNULL( g.RmbAmount,0)) AS  getRmbAmount  
        FROM  dbo.data_wide_s_Getin g   
        WHERE  g.VouchStatus <> '作废' AND g.ItemType IN ('非贷款类房款') AND IsFk = 1 AND ItemName LIKE '%补差%'  
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
                            WHERE ItemType = '代收费用' AND ItemName LIKE '%维修%'  
            GROUP BY  TradeGUID  
        ) AS p5 ON p5.TradeGUID = tr.TradeGUID  
        --新增实收金额和实收日期20241030       
        LEFT JOIN 
        (  SELECT    
            SaleGUID ,
            ItemName,
            SUM(RmbAmount) je,
            CASE WHEN SUM(RmbAmount)>0 THEN MAX(SkDate) END rq    
        FROM  data_wide_s_Getin WITH (NOLOCK )  
        WHERE  VouchStatus='激活' 
        GROUP BY  SaleGUID , ItemName )ss2 ON ss2.SaleGUID=tr.TradeGUID AND ss2.ItemName=p2.ItemName
        LEFT JOIN 
        (  SELECT    
            SaleGUID ,
            ItemName,
            SUM(RmbAmount) je,
            CASE WHEN SUM(RmbAmount)>0 THEN MAX(SkDate) END rq    
        FROM  data_wide_s_Getin WITH (NOLOCK )  
        WHERE  VouchStatus='激活' 
        GROUP BY  SaleGUID , ItemName )ss3 ON ss3.SaleGUID=tr.TradeGUID AND ss3.ItemName=p3.ItemName
        LEFT JOIN 
        (  SELECT    
            SaleGUID ,
            ItemName,
            SUM(RmbAmount) je,
            CASE WHEN SUM(RmbAmount)>0 THEN MAX(SkDate) END rq    
        FROM  data_wide_s_Getin WITH (NOLOCK )  
        WHERE  VouchStatus='激活' 
        GROUP BY  SaleGUID , ItemName )ss4 ON ss4.SaleGUID=tr.TradeGUID AND ss4.ItemName=p4.ItemName

        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '03-ZSDC-01-房源台账明细表(全表)'
            AND StartTime = @SnapshotTime;

    END TRY

    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '03-ZSDC-01-房源台账明细表(全表)'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '04-ZSDC-06-未收款项明细表（含逾期款）',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        --04-ZSDC-06-未收款项明细表（含逾期款）
        -- 插入数据
        INSERT INTO Result_UnpaidAmountDetail (
            SnapshotTime,
            VersionNo,
            ProjGUID,
            项目推广名,
            分区名称,
            楼栋名称,
            单元,
            房号,
            房源唯一编码,
            房间全名,
            客户名称,
            销售状态,
            预售建筑面积,
            预售套内面积,
            认购日期,
            草签日期,
            签约日期,
            网签日期,
            付款方式名称,
            成交总价,
            销售员,
            所属团队,
            联系电话,
            地址,
            款项名称,
            款项类型,
            按揭银行,
            应交款,
            欠款,
            已交款,
            付款期限,
            逾期天数,
            已产生滞纳金,
            结转金额,
            未收滞纳金,
            累计已减免滞纳金,
            参考滞纳金
        )
        SELECT 
            GETDATE() AS SnapshotTime,
            CONVERT(VARCHAR(10),GETDATE(),23) AS VersionNo,
            f.ProjGUID AS ProjGUID,
            CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END,
            p.ProjShortName,
            f.BldName,
            f.UnitNo,
            f.ShortRoomInfo,
            f.RoomGUID,
            f.RoomInfo,
            ISNULL(tr.OCstAllName, tr.CCstAllName),
            CASE WHEN tr.CStatus = '激活' AND tr.ContractType = '网签' THEN '网签' 
                WHEN tr.CStatus = '激活' AND tr.ContractType = '草签' THEN '草签' 
                ELSE '认购' END,
            r.YsBldArea,
            r.YsTnArea,
            tr.ZcOrderDate,
            tr.x_InitialledDate,
            tr.CQsDate,
            tr.CNetQsDate,
            ISNULL(tr.CPayForm, tr.OPayForm),
            ISNULL(tr.CCjTotal, tr.OCjTotal),
            ISNULL(tr.CZygw, tr.OZygw),
            ISNULL(tr.CProjectTeam, tr.OProjectTeam),
            ISNULL(tr.CCstAllTel, tr.OCstAllTel),
            ISNULL(tr.CAddress, tr.OAddress),
            f.ItemName,
            f.ItemType,
            ISNULL(tr.CAjBank, tr.OAjBank),
            f.RmbAmount,
            f.RmbYe,
            ISNULL(f.RmbAmount, 0) + ISNULL(f.RmbDsAmount, 0) - ISNULL(f.RmbYe, 0),
            f.LastDate,
            CASE WHEN f.LastDate < GETDATE() THEN DATEDIFF(DAY,f.LastDate,GETDATE()) ELSE 0 END,
            CASE WHEN f.ItemName ='滞纳金' THEN f.RmbAmount END,
            NULL,
            NULL,
            f.JmLateFee,
            znj.参考滞纳金
        FROM    data_wide_s_Fee f WITH  (NOLOCK )
        INNER JOIN dbo.data_wide_mdm_Project p WITH  (NOLOCK ) ON p.p_projectId = f.ProjGUID
        INNER JOIN data_wide_mdm_Project pp WITH  (NOLOCK ) ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
        LEFT JOIN data_wide_s_Trade tr WITH  (NOLOCK ) ON tr.RoomGUID = f.RoomGUID AND tr.IsLast = 1 and f.TradeGUID =tr.TradeGUID
        INNER JOIN dbo.data_wide_s_Room r WITH  (NOLOCK ) ON r.RoomGUID = f.RoomGUID
        left join 
        (
            select 
                tradeguid,
                ysitemnameguid,
                SUM(fineamount1) AS 参考滞纳金 
            FROM data_wide_s_s_Cwfx 
            group by 
                tradeguid,
                ysitemnameguid
        ) znj on f.ItemNameGUID=znj.ysitemnameguid and f.TradeGUID=znj.tradeguid
        -- LEFT  JOIN data_wide_dws_s_roomexpand rex ON rex.RoomGUID =r.RoomGUID
        WHERE    ISNULL(f.RmbYe, 0) > 0 
            AND  tr.TradeStatus ='激活';        

        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '04-ZSDC-06-未收款项明细表（含逾期款）'
            AND StartTime = @SnapshotTime;

    END TRY

    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '05-ZSDC-05-实收款项明细表（全表）-含回款到账日期'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    BEGIN TRY
        
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '05-ZSDC-05-实收款项明细表（全表）-含回款到账日期',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        --05-ZSDC-05-实收款项明细表（全表）-含回款到账日期
        -- 插入数据
        INSERT INTO Result_ReceivedPaymentDetail (
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
            回款日期,
            开票日期,
            票据类型,
            凭证类型,
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
            放款银行,
            首次结转日期,
            入账日期
        )
        SELECT 
            GETDATE() AS SnapshotTime,
            CONVERT(VARCHAR(10),GETDATE(),23) AS VersionNo,
            g.ProjGUID AS ProjGUID,
            g.SkDate AS SkDate,
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
            g.SkDate AS 收款日期 ,
            CASE 
                WHEN g.VouchType ='退款单' THEN  ISNULL (g.rzdate, g.KpDate)
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
                ELSE g.SkDate END 
                ELSE g.SkDate END AS    HKdate,	
            g.KpDate AS 开票日期 ,
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
            NULL AS 放款银行,
            tr.HtCarryoverDate as 首次结转日期,
            g.rzdate as 入账日期
        FROM    dbo.data_wide_s_Getin g WITH(NOLOCK)
        INNER JOIN dbo.data_wide_mdm_Project p WITH(NOLOCK)ON p.p_projectId = g.ProjGUID
        INNER JOIN data_wide_mdm_Project pp WITH(NOLOCK)ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
        LEFT JOIN data_wide_s_Holiday wd ON CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)  = CONVERT(VARCHAR,wd.x_vacationDate,23)
        LEFT JOIN dbo.data_wide_s_Trade tr WITH(NOLOCK)ON tr.TradeGUID = g.SaleGUID  AND  tr.IsLast = 1 --调整为左连接取出诚意金房款
        WHERE   
            g.VouchStatus <> '作废' 
            AND  g.VouchType NOT IN ('POS机单','划拨单','放款单')
            AND g.SkDate BETWEEN DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0) AND DATEADD(MILLISECOND, -3, DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()) + 1, 0));

        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '05-ZSDC-05-实收款项明细表（全表）-含回款到账日期'
            AND StartTime = @SnapshotTime;

    END TRY

    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '05-ZSDC-05-实收款项明细表（全表）-含回款到账日期'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

    -- 2024-12-11 增加本年至今回笼金额明细表拍照
    BEGIN TRY
        -- 记录开始执行
        INSERT INTO [dbo].[SnapshotExecutionLog] (
            SnapshotName,
            ExecuteMode,
            StartTime,
            VersionNo,
            Status
        )
        VALUES (
            '01-ZSDC-本年至今回笼金额明细表',
            @ExecuteMode,
            @SnapshotTime,
            @VersionNo,
            'Started'
        );

        -- 执行数据插入
        INSERT INTO Result_ThisYearGetAmountDetail (
            [SnapshotTime],
            [VersionNo],
            [公司GUID],
            [ProjGUID],
            [项目名称],
            [分期名称],
            [房间信息],
            [签约日期],
            [单据类型],
            [款项类型],
            [款项名称],
            [收款日期],
            [交款人],
            [本年至今回笼金额]
        )  
        SELECT 
            GETDATE() AS SnapshotTime,
            CONVERT(VARCHAR(10), GETDATE(), 23) AS VersionNo,
            st.BUGUID AS 公司GUID,
            g.ParentProjGUID AS ProjGUID,                    -- 父级项目GUID
            g.ParentProjName AS 项目名称,                    -- 父级项目名称
            g.ProjName AS 分期名称,                          -- 项目名称
            g.RoomInfo AS 房间信息, 
            CONVERT(NVARCHAR(10), st.CQsDate, 111) AS 签约日期,
            v.vouchtype AS 单据类型,
            g.ItemType AS 款项类型,
            g.ItemName AS 款项名称,
            g.SkDate AS 收款日期,
            g.Jkr AS 交款人,
            ISNULL(g.RmbAmount, 0) / 10000.0 AS 本年至今回笼金额  -- 本年至今回笼金额
        FROM data_wide_s_Getin g WITH(NOLOCK)
            LEFT JOIN data_wide_s_Voucher v WITH(NOLOCK) 
                ON g.VouchGUID = v.VouchGUID
            INNER JOIN data_wide_s_trade st 
                ON g.SaleGUID = st.tradeguid 
                AND (st.cstatus = '激活' OR st.ostatus = '激活')
        WHERE g.VouchStatus <> '作废' 
            AND g.ItemType IN ('贷款类房款', '非贷款类房款', '补充协议款')  -- and g.ItemName !='诚意金'
            AND DATEDIFF(YEAR, ISNULL(g.SkDate, 0), GETDATE()) = 0;        -- and st.BUGUID in (@buguid) and g.ParentProjGUID in (@Projguid) 

        -- 记录执行成功
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = '01-ZSDC-本年至今回笼金额明细表'
            AND StartTime = @SnapshotTime;
    END TRY

    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();
        
        -- 记录执行失败
        UPDATE [dbo].[SnapshotExecutionLog]
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = '01-ZSDC-本年至今回笼金额明细表'
            AND StartTime = @SnapshotTime;

        -- 抛出异常
        THROW;
    END CATCH

END;


