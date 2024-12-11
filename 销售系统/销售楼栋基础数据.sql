select
 bu.buname as 公司名称,bld.BUGUID,
 mdm2.x_area as 所属片区,	
 mdm2.x_ManagementSubject as 管理主体,	
 pro.SpreadName as 推广名称,	
 pro.projshortname as 项目名称,	
 fq.projshortname as 分期名称,
 (SELECT Name FROM mdm_StagePhaseType WHERE mdm_StagePhaseType.StagePhaseTypeGUID=fq.PhaseGUID)	as 分期阶段,	
 bld.Name as 楼栋名称,	bld.BuildArea,bld.AvailableArea,
 bld.BelongProductName as 一级业态,	
 bld.Product as 业态全称,	
 bld.ManagementAttributes as 经营属性,	
 CASE  When bld.BelongProductName like '%车%' THEN bld.CarNum ELSE bld.SetNum end as 户数,
 bpn.PlanNotNADI  as 预计拿地日期,	
 bpn.FactNotNADI  as 实际拿地日期,	
 bpn.PlanNotDYSTJ as 预计达预售条件日期,	
 bpn.FactNotDYSTJ as 实际达预售条件日期,		
 bpn.PlanNotOpen as 预计获得销许日期,	
 bpn.FactNotOpen as 实际获得销许日期,	
 bld.AvailableArea as 预计可售面积,	
 bld.TargetUnitPrice as 目标销售均价,
 mdm_BuildingRecord.x_TargetUnitPriceDescription as 目标销售均价说明,	
 bld.SaleAmount as 可售金额,	
 bpn.PlanAdmissionDate as 预计交付日期,	
 bpn.FactAdmissionDate as 实际交付日期,		
 case when xs.MasterBldGUID is not null then '是' else '否' end as 是否已开售,
 case when bldr.BuildingGUID IS null then '否' else '是' end as 是否已定价,

 xs.认购已售套数,	
 xs.认购已售面积,	
 xs.认购已售金额,
 
 xs1.实际签约套数,
 xs1.实际签约面积,
 xs1.实际签约金额,
 
 xs2.业绩认定口径已售套数,
 xs2.业绩认定口径已售面积,
 xs2.业绩认定口径已售金额
 
from mdm_Building bld
inner join mdm_BuildingRecord on  bld.buildingguid=mdm_BuildingRecord.buildingguid
inner join mdm_ProjectRecord on mdm_ProjectRecord.ProjectRecordGUID=mdm_BuildingRecord.ProjectRecordGUID and  mdm_ProjectRecord.IsExeVersion=1
inner join mdm_ProjectRecord mdm2 on mdm2.p_Projectid=mdm_ProjectRecord .ParentGUID and mdm2.IsExeVersion=1
left join
(
  select 
		BuildingGUID,
		max(case bpn.NodeCode when N'NADI' then PlanEndDate else null end) as PlanNotNADI,
		max(case bpn.NodeCode when N'NADI' then FactEndDate else null end) as FactNotNADI,
		max(case bpn.NodeCode when N'DYSTJ' then PlanEndDate else null end) as PlanNotDYSTJ,
		max(case bpn.NodeCode when N'DYSTJ' then FactEndDate else null end) as FactNotDYSTJ,
		max(case bpn.NodeCode when N'HQXSXKZ' then PlanEndDate else null end) as PlanNotOpen,
		max(case bpn.NodeCode when N'HQXSXKZ' then FactEndDate else null end) as FactNotOpen,
		max(case bpn.NodeCode when N'JF' then PlanEndDate else null end) as PlanAdmissionDate,
		max(case bpn.NodeCode when N'JF' then FactEndDate else null end) as FactAdmissionDate
  from p_Build2PlanNode bpn WITH ( NOLOCK )
  group by BuildingGUID
  having max(case bpn.NodeCode when N'DYSTJ' then FactEndDate else null end) is not null
) bpn on bld.BuildingGUID=bpn.BuildingGUID
left join 
(
	select 
	 bld.MasterBldGUID,
	 count(1) as 认购已售套数,	
	 sum(sr.bldarea) as 认购已售面积,	
	 sum(isnull(sc.CjRmbTotal,so.CjRmbTotal)) as 认购已售金额
	from s_trade st 
	left join s_order so on st.tradeguid=so.tradeguid and so.status='激活'
	left join s_contract sc on st.tradeguid=sc.tradeguid and sc.status='激活'
	left join s_room sr on st.roomguid=sr.roomguid
	left join s_Building bld on sr.bldguid=bld.bldguid
	where st.tradestatus='激活'
	group by 
	 bld.MasterBldGUID
) xs on bld.BuildingGUID=xs.MasterBldGUID
left join 
(
	select 
	 bld.MasterBldGUID,
	 count(1) as 实际签约套数,	
	 sum(sr.bldarea) as 实际签约面积,	
	 sum(sc.CjRmbTotal) as 实际签约金额
	from s_trade st 
	--left join s_order so on st.tradeguid=so.tradeguid and so.status='激活'
	right join s_contract sc on st.tradeguid=sc.tradeguid and sc.status='激活'
	left join s_room sr on st.roomguid=sr.roomguid
	left join s_Building bld on sr.bldguid=bld.bldguid
	where st.tradestatus='激活'
	group by 
	 bld.MasterBldGUID
) xs1 on bld.BuildingGUID=xs1.MasterBldGUID

left join 
(
	select 
	 bld.MasterBldGUID,
	 count(1) as 业绩认定口径已售套数,	
	 sum(sr.bldarea) as 业绩认定口径已售面积,	
	 sum(sc.CjRmbTotal) as 业绩认定口径已售金额
	from s_trade st 
	
	 OUTER APPLY(
                   -- 取最新的业绩认定表的记录
                   SELECT   TOP 1   x_YeJiPrice ,
                                    x_YeJiTime
                   FROM x_p_roomyeji ryj
                   WHERE   ryj.x_RoomGUID = st.RoomGUID AND x_zfbz='激活'
                   ORDER BY x_YeJiPrice DESC) yjrd
                   
	--left join s_order so on st.tradeguid=so.tradeguid and so.status='激活'
	right join s_contract sc on st.tradeguid=sc.tradeguid and sc.status='激活'
	left join s_room sr on st.roomguid=sr.roomguid
	left join s_Building bld on sr.bldguid=bld.bldguid
	where st.tradestatus='激活'
	and yjrd.x_YeJiTime is not null
	group by 
	 bld.MasterBldGUID
) xs2 on bld.BuildingGUID=xs2.MasterBldGUID

left join p_project fq on bld.StageGUID=fq.p_projectid 
left join p_project pro on fq.parentguid=pro.p_projectid
left join myBusinessUnit bu on bu.buguid = bld.buguid
left join  (select a.BuildingGUID  from mdm_building a 
where exists(select 1 from  s_room b WHERE a.StageGUID=b.ProjGUID and  b.RoomInfo LIKE CONCAT('%',a.RecordName, '%') and b.BldPrice <> 0)) bldr
on  bld.BuildingGUID=bldr.BuildingGUID

where bld.BUGUID in (@公司)


 