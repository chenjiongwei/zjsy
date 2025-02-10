--QGH-01-本年签约明细表
-- IF  @版本号='实时' 
-- BEGIN
    select
        null as snapshot_time,
        null as version,
        null as BUGUID,
        null as ParentProjGUID,
        r.ParentProjName AS 项目,
        convert(nvarchar(10),tr.CQsDate,111) AS 签约日期,
        convert(nvarchar(10),r.x_YeJiTime,111) AS 业绩认定日期,
        r.RoomGUID AS 房间编号,
        r.RoomInfo AS 房间信息,
        r.CjRmbTotal AS 成交总价,
        r.wndjTotal AS 往年最后一次定价金额,
        bld.TargetUnitPrice AS 目标均价,
        r.CjBldArea AS 签约面积
    from data_wide_s_room r
    LEFT JOIN data_wide_mdm_building bld WITH(NOLOCK) ON  r.MasterBldGUID =bld.BuildingGUID 
    inner JOIN  (
          select   CASE WHEN isnull(tr.x_InitialledDate,0)=0 and tr.CNetQsDate IS not null THEN  tr.CNetQsDate   
                     WHEN isnull(tr.x_InitialledDate,0)=0 and isnull(tr.CNetQsDate,0)=0 THEN NULL  
                   ELSE tr.x_InitialledDate END AS CQsDate, 
                   RoomGUID,tr.TradeStatus,tr.IsLast,tr.TradeGUID,tr.CCjBldArea,tr.CCjRoomTotal,CStatus
                 from   data_wide_s_Trade  tr WITH (NOLOCK)
    ) tr ON tr.RoomGUID = r.RoomGUID  AND  CStatus='激活' AND   tr.IsLast = 1
    where r.BUGUID in (@buguid) and r.ParentProjGUID in (@Projguid) and DATEDIFF(YEAR,tr.CQsDate,@tjDate)=0 
    and r.TopProductTypeName ='住宅' --只统计住宅	
    and r.BUName LIKE  '%后花园%'  AND  r.BldArea <> '1' AND r.DjTotal > 0	
-- END 
-- ELSE
-- BEGIN
--     select 
--         snapshot_time,
--         [version],
--         BUGUID,
--         ParentProjGUID,
--         项目,
--         签约日期,
--         业绩认定日期,
--         房间编号,
--         房间信息,
--         成交总价,
--         往年最后一次定价金额,
--         目标均价,
--         签约面积
--     from dbo.Result_YearlySignedRooms
--     where  [version] = @版本号
--         and BUGUID in (@buguid)
--         and ParentProjGUID in (@Projguid)
-- END