-- DECLARE @date datetime =getdate() 
select 
tt.项目,
tt.项目推广名称,
tt.分期,
tt.业态,
isnull(tt.年初可售余货套数,0) as 年初可售余货套数,
isnull(tt.年初可售余货面积,0) as 年初可售余货面积,
isnull(tt.年初可售余货货值,0)*0.0001 as 年初可售余货货值,
isnull(tt.本年新供货套数,0) as 本年新供货套数,
isnull(tt.本年新供货面积,0) as 本年新供货面积,
isnull(tt.本年新供货货值,0)*0.0001 as 本年新供货货值,
isnull(tt.年初可售余货套数,0)+isnull(tt.本年新供货套数,0) as 年初至今总可售套数,
isnull(tt.年初可售余货面积,0)+isnull(tt.本年新供货面积,0) as 年初至今总可售面积,
(isnull(tt.年初可售余货货值,0)+isnull(tt.本年新供货货值,0))*0.0001 as 年初至今总可售货值,
isnull(tt.本年认购套数,0) as 本年认购套数,
isnull(tt.本年认购面积,0) as 本年认购面积,
isnull(tt.本年认购货值,0)*0.0001 as 本年认购货值,
-- isnull(tt.本年认购套数/nullif(isnull(tt.年初可售余货套数,0)+isnull(tt.本年新供货套数,0),0),0) as 套数去化率,
case when  (isnull(tt.年初可售余货套数,0) + isnull(tt.本年新供货套数,0) ) =0  then  0  else isnull(tt.本年认购套数,0) * 1.0 / (isnull(tt.年初可售余货套数,0)+isnull(tt.本年新供货套数,0) ) end as 套数去化率,
isnull(tt.本年认购面积/nullif(isnull(tt.年初可售余货面积,0)+isnull(tt.本年新供货面积,0),0),0) as 面积去化率,
isnull(tt.本年认购货值/nullif(isnull(tt.年初可售余货货值,0)+isnull(tt.本年新供货货值,0),0),0) as 货值去化率
from 
(
    select 
    sr.ParentProjName as 项目,
    pro.SpreadName as 项目推广名称,
    sr.ProjName as 分期,
    bld.ProductTypeName as 业态,
    sum(case when (year(so.ZcOrderDate)=year(@date) or so.ZcOrderDate is null) and year(bld.FactNotOpen)<year(@date) then 1 else 0 end) as 年初可售余货套数,
    sum(case when (year(so.ZcOrderDate)=year(@date) or so.ZcOrderDate is null) and year(bld.FactNotOpen)<year(@date) then sr.bldarea else 0 end) as 年初可售余货面积,
    sum(case when (year(so.ZcOrderDate)=year(@date) or so.ZcOrderDate is null) and year(bld.FactNotOpen)<year(@date) then sr.DjTotal else 0 end) as 年初可售余货货值,
    sum(case when year(bld.FactNotOpen)=year(@date) then 1 else 0 end) as 本年新供货套数,
    sum(case when year(bld.FactNotOpen)=year(@date) then sr.bldarea else 0 end) as 本年新供货面积,
    sum(case when year(bld.FactNotOpen)=year(@date) then sr.DjTotal else 0 end) as 本年新供货货值,
    sum(case when year(bld.FactNotOpen)<=year(@date) and year(so.ZcOrderDate)=year(@date) then 1 else 0 end) as 本年认购套数,
    sum(case when year(bld.FactNotOpen)<=year(@date) and year(so.ZcOrderDate)=year(@date) then so.ocjbldarea else 0 end) as 本年认购面积,
    sum(case when year(bld.FactNotOpen)<=year(@date) and year(so.ZcOrderDate)=year(@date) then isnull(so.ocjTotal,so.ccjTotal) else 0 end) as 本年认购货值
    from data_wide_s_room sr 
    left join data_wide_mdm_building bld on sr.MasterBldGUID=bld.BuildingGUID
    left join data_wide_s_trade so on sr.roomguid=so.roomguid and (so.ostatus='激活' or so.cstatus='激活')
    left join data_wide_mdm_project pro on sr.parentprojguid=pro.p_projectid
    where sr.projguid in (@projguid)
    group by 
    sr.ParentProjName,
    pro.SpreadName,
    sr.ProjName,
    bld.ProductTypeName
) tt