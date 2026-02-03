-- 财务已售未结转
-- 20250310 已售未结转分析表的数，总实际成交金额，总已收金额，累计已结转金额这些都是要取含退补面积差
-- 增加日期筛选条件

-- declare @var_EndDate datetime = getdate()

-- 2.已售未结转
select 
    -- 基本信息
    pro.projname as 项目名称,
	pro.p_projectId AS 项目GUID,
    pro.SpreadName as 推广项目名称, 
    fq.projshortname as 分期名称,
    fq.StagePhaseName as 分期阶段,
    sr.BldName as 楼栋,
    bld.PlanAdmissionDate as 预计交付日期, -- 改成取房间的预计交房日期
    bld.FactAdmissionDate as 实际交付日期, -- 改成取房间的实际交房日期
    
    -- 总体金额统计
    sum( isnull(sk.总已收房款,0) ) as 总已收房款,
    sum( case when datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 then isnull(st.BcAfterCTotal,st.ocjtotal) else  0  end ) as 总实际成交金额,
    
    sum( case when datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 then 
         case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else  0  end ) as 总实际成交面积,
    sum( isnull(jz.结转金额,0)) as 累计已结转金额,
    sum( case when datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 and jz.tradeguid is not null then 
         case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else  0  end ) as  累计已结转面积,

    sum( case when datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 then isnull(st.BcAfterCTotal,st.ocjtotal) else  0  end - isnull(jz.结转金额,0) ) as 总已售未结货值,
    sum( case when datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
         then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else  0 end  ) - 
    sum( case when datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 and jz.tradeguid is not null then 
         case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else  0  end ) as 总已售未结面积,
    -- 实时的已售未结转货值、面积 统计 不受查询时间影响
    sum( isnull(st.BcAfterCTotal,st.ocjtotal) - isnull(jzNow.结转金额实时,0) ) as 总已售未结货值_实时,
    sum( case when st.tradeguid is not null then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end ) - 
    sum( case when jzNow.tradeguid is not null then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else  0  end ) as 总已售未结面积_实时,
    
    -- 销售状态统计
    sum(case when jz.tradeguid is null and st.CNetQsDate is not null and sk.总已收房款>=isnull(st.BcAfterCTotal,st.ocjtotal) 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then isnull(st.BcAfterCTotal,st.ocjtotal)  else 0 end) as 已网签已回全款,
    sum(case when jz.tradeguid is null and st.CNetQsDate is not null and sk.总已收房款>=isnull(st.BcAfterCTotal,st.ocjtotal) 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end) as 已网签已回全款面积,          
    sum(case when jz.tradeguid is null and st.CNetQsDate is not null and isnull(sk.总已收房款,0)<isnull(isnull(st.BcAfterCTotal,st.ocjtotal),0) 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then isnull(st.BcAfterCTotal,st.ocjtotal)  else 0 end) as 已网签未回全款,
    sum(case when jz.tradeguid is null and st.CNetQsDate is not null and isnull(sk.总已收房款,0)<isnull(isnull(st.BcAfterCTotal,st.ocjtotal),0) 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end) as 已网签未回全款面积,
    sum(case when jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then isnull(st.BcAfterCTotal,st.ocjtotal)  else 0 end) as 已草签未网签,
    sum(case when jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end) as 已草签未网签面积,
    sum(case when jz.tradeguid is null and st.ostatus='激活' 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then isnull(st.BcAfterCTotal,st.ocjtotal)  else 0 end) as 已认购未签约,
    sum(case when jz.tradeguid is null and st.ostatus='激活' 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end) as 已认购未签约面积,
    sum(case when jz.tradeguid is null 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then isnull(st.BcAfterCTotal,st.ocjtotal)  else 0 end) as 已售未结货值小计,
    sum(case when jz.tradeguid is null 
             and datediff(day,isnull(st.CQsDate,st.OQsDate),@var_EndDate) >=0 
             then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end) as 已售未结面积小计,

    -- 本年预计交房统计
    sum(case when year(st.YjfDate)=year(@var_EndDate) and jz.tradeguid is null 
	         and st.CNetQsDate is not null and sk.总已收房款>=isnull(st.BcAfterCTotal,st.ocjtotal) 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已网签已回全款,
    sum(case when year(st.YjfDate)=year(@var_EndDate) and jz.tradeguid is null and st.CNetQsDate is not null 
	        and isnull(sk.总已收房款,0)<isnull(isnull(st.BcAfterCTotal,st.ocjtotal),0) 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已网签未回全款,
    sum(case when year(st.YjfDate)=year(@var_EndDate) and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已草签未网签,
    sum(case when year(st.YjfDate)=year(@var_EndDate) and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已认购未签约,
    sum(case when year(st.YjfDate)=year(@var_EndDate) and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 本年预计交房已售未结货值小计,
    
    -- 明年预计交房统计
    sum(case when year(st.YjfDate)=year(@var_EndDate)+1 and jz.tradeguid is null and st.CNetQsDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已网签,
    sum(case when year(st.YjfDate)=year(@var_EndDate)+1 and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已草签未网签,
    sum(case when year(st.YjfDate)=year(@var_EndDate)+1 and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已认购未签约,
    sum(case when year(st.YjfDate)=year(@var_EndDate)+1 and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 明年预计交房已售未结货值小计,
    
    -- 后年预计交房统计
    sum(case when year(st.YjfDate)=year(@var_EndDate)+2 and jz.tradeguid is null and st.CNetQsDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已网签,
    sum(case when year(st.YjfDate)=year(@var_EndDate)+2 and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已草签未网签,
    sum(case when year(st.YjfDate)=year(@var_EndDate)+2 and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已认购未签约,
    sum(case when year(st.YjfDate)=year(@var_EndDate)+2 and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年预计交房已售未结货值小计,
    
    -- 后年之后预计交房统计
    sum(case when year(st.YjfDate)>year(@var_EndDate)+2 and jz.tradeguid is null and st.CNetQsDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已网签,
    sum(case when year(st.YjfDate)>year(@var_EndDate)+2 and jz.tradeguid is null and st.CNetQsDate is null and st.x_InitialledDate is not null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已草签未网签,
    sum(case when year(st.YjfDate)>year(@var_EndDate)+2 and jz.tradeguid is null and st.ostatus='激活' 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已认购未签约,
    sum(case when year(st.YjfDate)>year(@var_EndDate)+2 and jz.tradeguid is null 
             then isnull(st.BcAfterCTotal,st.ocjtotal) else 0 end) as 后年之后预计交房已售未结货值小计,
    
    -- 余货统计
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then 1 else 0 end) as 余货套数,
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.bldarea else 0 end) as 余货面积,
    case when sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.bldarea else 0 end)=0 then 0 
         else sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.DjTotal else 0 end)/
              sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.bldarea else 0 end) 
    end as 余货均价,
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)>0 then sr.DjTotal else 0 end) as 余货金额,
    -- 未定价的余货统计
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)=0 then 1 else 0 end) as 余货套数未定价,
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)=0 then sr.bldarea else 0 end) as 余货面积未定价,
    max(case when st.tradeguid is null and isnull(sr.DjTotal,0)=0 then bld.TargetUnitPrice else 0 end) as 余货均价未定价,
    sum(case when st.tradeguid is null and isnull(sr.DjTotal,0)=0 then isnull(bld.TargetUnitPrice,0)* isnull(sr.bldarea ,0) else 0 end) as 余货金额未定价
from data_wide_s_room sr
left join data_wide_s_trade st  on sr.roomguid=st.roomguid  and (st.cstatus='激活' or st.ostatus='激活')
left join 
(
    -- 结转金额统计
    select 
        tradeguid,
        --sum( isnull(CarryoverAmount,0) ) as 结转金额实时,
        sum( isnull(BldArea,0) ) as 结转面积,
        sum( isnull(CarryoverAmount,0) ) as 结转金额
    from data_wide_s_CarryoverDetail
    where datediff(day, CarryoverDate ,@var_EndDate) >=0 
    group by tradeguid
) jz on st.tradeguid=jz.tradeguid
left join 
(
    -- 结转金额统计
    select 
        tradeguid,
        sum( isnull(BldArea,0) ) as 结转面积实时,
        sum( isnull(CarryoverAmount,0) ) as 结转金额实时
    from data_wide_s_CarryoverDetail
    group by tradeguid
) jzNow on st.tradeguid=jzNow.tradeguid
left join 
(
    -- 房款统计，已包含补差款
    select 
        sg.saleguid,
        sum(sg.rmbamount) as 总已收房款
    from data_wide_s_getin sg
    where sg.itemtype in ('贷款类房款','非贷款类房款')
        and isnull(sg.vouchstatus,'')<>'作废'
        and datediff(day,SkDate,@var_EndDate) >=0
    group by sg.saleguid
) sk on st.tradeguid=sk.saleguid
inner join data_wide_mdm_building bld on sr.MasterBldGUID=bld.BuildingGUID
inner join data_wide_mdm_project fq on sr.projguid=fq.p_projectid
inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
where 1=1 --AND fq.parentguid ='E7F3528E-DA69-4688-8FFB-08D945781665'
AND fq.parentguid in (@projguid) 
group by
    pro.projname,
	pro.p_projectId,
    pro.SpreadName,
    fq.projshortname,
    fq.StagePhaseName,
    sr.BldName,
    bld.PlanAdmissionDate,
    bld.FactAdmissionDate
order by
    pro.projname,
    fq.projshortname,
    sr.BldName