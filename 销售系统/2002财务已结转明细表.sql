--一张是已结转明细表（按交楼起止日期筛选）
select  
    pro.projname as 项目名称,
    pro.SpreadName as 推广项目名称, 
    fq.projshortname as 分期名称,
    fq.StagePhaseName as 分期阶段,
    sr.BldName as 楼栋,
    -- bld.PlanAdmissionDate as 预计交付日期,
    -- bld.FactAdmissionDate as 实际交付日期,
    sr.YjfDate as 预计交付日期, --合同对应的应交房日期
    sr.SjjfDate as 实际交付日期, -- 合同对应的入伙服务中的实际交房日期
    sr.roomguid as 房间GUID,
    sr.roominfo as 房间信息,
    case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end as 房间建筑面积,-- 交易单对应的房间的建筑面积，有实测取实测，没有实测取预测；包含主房间的面积补差；
    st.OQsDate as 认购日期,
    st.CQsDate as 签约日期,
    st.CNetQsDate as 网签日期,
    st.tzffSdate as 通知发放开始日期,
    st.tzffDdate as 通知发放结束日期,
    isnull(st.CCstAllName,st.OCstAllName) 客户名称,
    isnull(st.BcAfterCTotal,isnull(st.ccjtotal,st.ocjtotal)) as 实际成交金额,
    sk.总已收房款 as 已收房款,
    jz.结转日期 as 结转日期,
    jz.结转金额 as 结转金额,
    case when  jz.tradeguid is not null then case when ISNULL(sr.ScBldArea,0) <> 0  THEN  isnull(sr.ScBldArea,0) ELSE  isnull(sr.YsBldArea,0) end else 0 end as 结转面积
from data_wide_s_room sr with (nolock)
left join data_wide_s_trade st with (nolock) 
    on sr.roomguid=st.roomguid 
    and (st.cstatus='激活' or st.ostatus='激活')
inner join 
(
    -- 结转金额统计
    select 
        tradeguid,
        max(CarryoverDate) as 结转日期, -- 最后一笔的结转日期（结转单分成了销售结转单和补差款结转单）
        sum(CarryoverAmount) as 结转金额
    from data_wide_s_CarryoverDetail with (nolock)
    group by tradeguid
) jz on st.tradeguid=jz.tradeguid
left join 
(
    -- 房款统计，已包含补差款
    select 
        sg.saleguid,
        sum(sg.rmbamount) as 总已收房款
    from data_wide_s_getin sg with (nolock)
    where sg.itemtype in ('贷款类房款','非贷款类房款')
        and isnull(sg.vouchstatus,'')<>'作废'
    group by sg.saleguid
) sk on st.tradeguid=sk.saleguid
inner join data_wide_mdm_building bld with (nolock)  on sr.MasterBldGUID=bld.BuildingGUID
inner join data_wide_mdm_project fq with (nolock)   on sr.projguid=fq.p_projectid
inner join data_wide_mdm_project pro with (nolock)  on fq.parentguid=pro.p_projectid
where isnull(st.BcAfterCTotal,st.ocjtotal) > 0 
    and isnull(jz.结转金额,0) <> 0 
    and fq.parentguid in (@projguid) 
    and jz.结转日期 between @var_jzSdate and @var_jzEdate
    -- and sr.YjfDate between @var_jfSdate and @var_jfEdate
order by pro.projname, sr.roominfo