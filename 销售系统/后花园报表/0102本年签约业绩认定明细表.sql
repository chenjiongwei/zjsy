--QGH-02-本年签约业绩认定明细表
-- IF  @版本号='实时' 
-- BEGIN
    select
        null as [snapshot_time],
        null as [version],
        null as [buguid],
        null as [projguid],
        r.ParentProjName AS 项目,
        convert(nvarchar(10),tr.CQsDate,111) AS 签约日期,
        convert(nvarchar(10),r.x_YeJiTime,111) AS 业绩认定日期,
        r.RoomGUID AS 房间编号,
        r.RoomInfo AS 房间信息,
        r.CjRmbTotal AS 成交总价,
        case when DATEDIFF(YEAR,bld.FactNotOpen,@tjDate)=0  then bld.TargetUnitPrice * r.CjBldArea 
             when r.wndjTotal IS not null then r.wndjTotal  else 0 end as 往年最后一次定价金额,
        --r.wndjTotal AS 往年最后一次定价金额,
        bld.TargetUnitPrice AS 目标均价,
        r.CjBldArea AS 签约面积
    from data_wide_s_room r
    LEFT JOIN data_wide_mdm_building bld WITH(NOLOCK) ON  r.MasterBldGUID =bld.BuildingGUID 
    inner JOIN data_wide_s_Trade tr WITH(NOLOCK)ON tr.RoomGUID = r.RoomGUID  AND  CStatus='激活' AND   tr.IsLast = 1
    where r.BUGUID in (@buguid) and r.ParentProjGUID in (@Projguid) and DATEDIFF(YEAR,r.x_YeJiTime,@tjDate)=0
    and r.TopProductTypeName ='住宅'
     and r.BUName LIKE  '%后花园%'  AND  r.BldArea <> '1' AND r.DjTotal > 0	
-- END;
-- ELSE
-- BEGIN
--     select 
--         [snapshot_time],
--         [version],
--         [buguid],
--         [projguid],
--         [项目],
--         [签约日期],
--         [业绩认定日期],
--         [房间编号],
--         [房间信息],
--         [成交总价],
--         [往年最后一次定价金额],
--         [目标均价],
--         [签约面积]
--     from [dbo].[result_room_yjrd_snapshot]
--     where [version] = @版本号
--     and [buguid] in (@buguid)
--     and [projguid] in (@Projguid)

-- END