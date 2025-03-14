-- 财务已售未结转
-- 20250310 已售未结转分析表的数，总实际成交金额，总已收金额，累计已结转金额这些都是要取含退补面积差
-- 增加交楼时间的筛选

-- 2.已售未结转
select 
    -- 基本信息
    pro.projname as 项目名称,
    pro.SpreadName as 推广项目名称, 
    fq.projshortname as 分期名称,
    fq.StagePhaseName as 分期阶段,
    sr.BldName as 楼栋,
    bld.PlanAdmissionDate as 预计交付日期, -- 改成取房间的预计交房日期
    bld.FactAdmissionDate as 实际交付日期, -- 改成取房间的实际交房日期
    
    -- 总体金额统计
    sum(sk.总已收房款) as 总已收房款,
    sum(isnull(st.BcAfterCTotal,st.ocjtotal)) as 总实际成交金额,
    sum(jz.结转金额) as 累计已结转金额,
    sum(isnull(isnull(st.BcAfterCTotal,st.ocjtotal),0)-isnull(jz.结转金额,0)) as 总已售未结货值,
    
    -- 销售状态统计
    sum(case when jz.tradeguid is null and st.CNetQsDate is not null and sk.总已收房款>=isnull(st.BcAfterCTotal,st.ocjtotal) 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 已网签已回全款,
    sum(case when jz.tradeguid is null and st.CNetQsDate is not null and isnull(sk.总已收房款,0)<isnull(isnull(st.BcAfterCTotal,st.ocjtotal),0) 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 已网签未回全款,
    sum(case when jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 已草签未网签,
    sum(case when jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 已认购未签约,
    sum(case when jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 已售未结货值小计,
    
    -- 本年预计交房统计
    sum(case when year(st.YjfDate)=year(@var_jfDate) and jz.tradeguid is null 
	         and st.CNetQsDate is not null and sk.总已收房款>=isnull(st.BcAfterCTotal,st.ocjtotal) 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已网签已回全款,
    sum(case when year(st.YjfDate)=year(@var_jfDate) and jz.tradeguid is null and st.CNetQsDate is not null 
	        and isnull(sk.总已收房款,0)<isnull(isnull(st.BcAfterCTotal,st.ocjtotal),0) 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已网签未回全款,
    sum(case when year(st.YjfDate)=year(@var_jfDate) and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已草签未网签,
    sum(case when year(st.YjfDate)=year(@var_jfDate) and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已认购未签约,
    sum(case when year(st.YjfDate)=year(@var_jfDate) and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已售未结货值小计,
    
    -- 明年预计交房统计
    sum(case when year(st.YjfDate)=year(@var_jfDate)+1 and jz.tradeguid is null and st.CNetQsDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已网签,
    sum(case when year(st.YjfDate)=year(@var_jfDate)+1 and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已草签未网签,
    sum(case when year(st.YjfDate)=year(@var_jfDate)+1 and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已认购未签约,
    sum(case when year(st.YjfDate)=year(@var_jfDate)+1 and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已售未结货值小计,
    
    -- 后年预计交房统计
    sum(case when year(st.YjfDate)=year(@var_jfDate)+2 and jz.tradeguid is null and st.CNetQsDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已网签,
    sum(case when year(st.YjfDate)=year(@var_jfDate)+2 and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已草签未网签,
    sum(case when year(st.YjfDate)=year(@var_jfDate)+2 and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已认购未签约,
    sum(case when year(st.YjfDate)=year(@var_jfDate)+2 and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已售未结货值小计,
    
    -- 后年之后预计交房统计
    sum(case when year(st.YjfDate)>year(@var_jfDate)+2 and jz.tradeguid is null and st.CNetQsDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已网签,
    sum(case when year(st.YjfDate)>year(@var_jfDate)+2 and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已草签未网签,
    sum(case when year(st.YjfDate)>year(@var_jfDate)+2 and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已认购未签约,
    sum(case when year(st.YjfDate)>year(@var_jfDate)+2 and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已售未结货值小计,
    
    -- 余货统计
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then 1 else 0 end) as 余货套数,
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.bldarea else 0 end) as 余货面积,
    case when sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.bldarea else 0 end)=0 then 0 
         else sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.DjTotal else 0 end)/
              sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.bldarea else 0 end) 
    end as 余货均价,
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.DjTotal else 0 end) as 余货金额
from data_wide_s_room sr
left join data_wide_s_trade st  on sr.roomguid=st.roomguid  and (st.cstatus='激活' or st.ostatus='激活')
left join 
(
    -- 结转金额统计
    select 
        tradeguid,
        sum(CarryoverAmount) as 结转金额
    from data_wide_s_CarryoverDetail 
    group by tradeguid
) jz on st.tradeguid=jz.tradeguid
left join 
(
    -- 房款统计，已包含补差款
    select 
        sg.saleguid,
        sum(sg.rmbamount) as 总已收房款
    from data_wide_s_getin sg
    where sg.itemtype in ('贷款类房款','非贷款类房款')
        and isnull(sg.vouchstatus,'')<>'作废'
    group by sg.saleguid
) sk on st.tradeguid=sk.saleguid
inner join data_wide_mdm_building bld on sr.MasterBldGUID=bld.BuildingGUID
inner join data_wide_mdm_project fq on sr.projguid=fq.p_projectid
inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
where fq.parentguid in (@projguid) 
group by
    pro.projname,
    pro.SpreadName,
    fq.projshortname,
    fq.StagePhaseName,
    sr.BldName,
    bld.PlanAdmissionDate,
    bld.FactAdmissionDate
