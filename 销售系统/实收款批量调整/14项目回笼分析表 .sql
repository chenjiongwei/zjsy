-- ZSDC-14- 项目回笼分析表 
-- 2025-01-08 调整收款日期的取数口径

select * into #应收情况 from
(
select 
sf.tradeguid,
sum(sf.RmbAmount) as 应收金额,
sum(case when sf.itemtype='贷款类房款' then sf.RmbAmount end) as 应收按揭金额,
sum(case when sf.itemtype='非贷款类房款' then sf.RmbAmount end) as 应收非按揭金额,
sum(sf.RmbYe) as 待收金额,
sum(case when sf.itemtype='贷款类房款' then sf.RmbYe end) as 待收按揭金额,
sum(case when sf.itemtype='非贷款类房款' then sf.RmbYe end) as 待收非按揭金额,
sum(case when sf.lastdate<@date then sf.RmbYe end) as 逾期待收金额,
sum(case when sf.lastdate<@date and sf.itemtype='贷款类房款' then sf.RmbYe end) as 逾期待收按揭金额,
sum(case when sf.lastdate<@date and sf.itemtype='非贷款类房款' then sf.RmbYe end) as 逾期待收非按揭金额
from data_wide_s_fee sf 
where sf.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
group by 
sf.tradeguid
) tt

select * into #实收情况 from
(
select 
sg.saleguid,
sum(sg.amount) as 实收金额
from data_wide_s_getin sg 
where sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
and isnull(sg.vouchstatus,'')<>'作废'
and sg.skdate<=@date
group by 
sg.saleguid
) tt

select * into #认购情况 from 
(
select 
so.projguid,
bld.ProductTypeName as 业态,
'往年' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ocjtotal,so.ccjtotal)) as 认购金额,
sum(sg.实收金额 ) AS 认购已回款,
sum(sf.待收金额) as 认购待回款
from data_wide_s_trade so 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=so.MasterBldGUID
left join #应收情况 sf on so.tradeguid=sf.tradeguid
left join #实收情况 sg on so.tradeguid=sg.saleguid
where year(so.ZcOrderDate)<year(@date)
and so.ZcOrderDate<=@date
and (so.ostatus='激活' or so.cstatus='激活')
group by 
so.projguid,
bld.ProductTypeName
union all 
select 
so.projguid,
bld.ProductTypeName as 业态,
'本年' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ocjtotal,so.ccjtotal)) as 认购金额,
sum(sg.实收金额 ) AS 认购已回款,
sum(sf.待收金额) as 认购待回款
from data_wide_s_trade so 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=so.MasterBldGUID
left join #应收情况 sf on so.tradeguid=sf.tradeguid
left join #实收情况 sg on so.tradeguid=sg.saleguid
where year(so.ZcOrderDate)=year(@date)
and so.ZcOrderDate<=@date
and (so.ostatus='激活' or so.cstatus='激活')
group by 
so.projguid,
bld.ProductTypeName
union all 
select 
so.projguid,
bld.ProductTypeName as 业态,
'全年' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ocjtotal,so.ccjtotal)) as 认购金额,
sum(sg.实收金额 ) AS 认购已回款,
sum(sf.待收金额) as 认购待回款
from data_wide_s_trade so 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=so.MasterBldGUID
left join #应收情况 sf on so.tradeguid=sf.tradeguid
left join #实收情况 sg on so.tradeguid=sg.saleguid
where so.ZcOrderDate<=@date
and (so.ostatus='激活' or so.cstatus='激活')
group by 
so.projguid,
bld.ProductTypeName
) tt

select * into #签约情况 from 
(
select 
sc.projguid,
bld.ProductTypeName as 业态,
'往年' as 周期,
sum(1) as 网签套数,	
sum(sc.ccjtotal) as 网签金额,
sum(sf.应收非按揭金额) as 网签非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.应收按揭金额 end) as 网签按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.应收按揭金额 end) as 网签按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.应收按揭金额 end) as 网签按揭纯公积金贷金额,
sum(sg.实收金额 ) AS 网签已回款,
sum(sf.待收金额) as 网签待回款金额,
sum(sf.待收非按揭金额) as 网签待回款非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.待收按揭金额 end) as 网签待回款按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.待收按揭金额 end) as 网签待回款按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.待收按揭金额 end) as 网签待回款按揭纯公积金贷金额,
sum(sf.逾期待收金额) as 网签逾期待回款金额,
sum(sf.逾期待收非按揭金额) as 网签逾期待回款非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭纯公积金贷金额
from data_wide_s_trade sc 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=sc.MasterBldGUID
left join #应收情况 sf on sc.tradeguid=sf.tradeguid
left join #实收情况 sg on sc.tradeguid=sg.saleguid
where year(sc.CNetQsDate)<year(@date)
and sc.CNetQsDate<=@date
and sc.cstatus='激活'
group by 
sc.projguid,
bld.ProductTypeName
union all 
select 
sc.projguid,
bld.ProductTypeName as 业态,
'本年' as 周期,
sum(1) as 网签套数,	
sum(sc.ccjtotal) as 网签金额,
sum(sf.应收非按揭金额) as 网签非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.应收按揭金额 end) as 网签按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.应收按揭金额 end) as 网签按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.应收按揭金额 end) as 网签按揭纯公积金贷金额,
sum(sg.实收金额 ) AS 网签已回款,
sum(sf.待收金额) as 网签待回款金额,
sum(sf.待收非按揭金额) as 网签待回款非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.待收按揭金额 end) as 网签待回款按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.待收按揭金额 end) as 网签待回款按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.待收按揭金额 end) as 网签待回款按揭纯公积金贷金额,
sum(sf.逾期待收金额) as 网签逾期待回款金额,
sum(sf.逾期待收非按揭金额) as 网签逾期待回款非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭纯公积金贷金额
from data_wide_s_trade sc 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=sc.MasterBldGUID
left join #应收情况 sf on sc.tradeguid=sf.tradeguid
left join #实收情况 sg on sc.tradeguid=sg.saleguid
where year(sc.CNetQsDate)=year(@date)
and sc.CNetQsDate<=@date
and sc.cstatus='激活'
group by 
sc.projguid,
bld.ProductTypeName
union all 
select 
sc.projguid,
bld.ProductTypeName as 业态,
'全年' as 周期,
sum(1) as 网签套数,	
sum(sc.ccjtotal) as 网签金额,
sum(sf.应收非按揭金额) as 网签非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.应收按揭金额 end) as 网签按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.应收按揭金额 end) as 网签按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.应收按揭金额 end) as 网签按揭纯公积金贷金额,
sum(sg.实收金额 ) AS 网签已回款,
sum(sf.待收金额) as 网签待回款金额,
sum(sf.待收非按揭金额) as 网签待回款非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.待收按揭金额 end) as 网签待回款按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.待收按揭金额 end) as 网签待回款按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.待收按揭金额 end) as 网签待回款按揭纯公积金贷金额,
sum(sf.逾期待收金额) as 网签逾期待回款金额,
sum(sf.逾期待收非按揭金额) as 网签逾期待回款非按揭金额,
sum(case when sc.cLoanOption='商业贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭纯商贷金额,
sum(case when sc.cLoanOption='组合贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭组合贷金额,
sum(case when sc.cLoanOption='公积金贷款' then sf.逾期待收按揭金额 end) as 网签逾期待回款按揭纯公积金贷金额
from data_wide_s_trade sc 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=sc.MasterBldGUID
left join #应收情况 sf on sc.tradeguid=sf.tradeguid
left join #实收情况 sg on sc.tradeguid=sg.saleguid
where sc.CNetQsDate<=@date
and sc.cstatus='激活'
group by 
sc.projguid,
bld.ProductTypeName
) tt

select * into #草签情况 from 
(
select 
sc.projguid,
	bld.ProductTypeName as 业态,
	'往年' as 周期,
	sum(1) as 草签未网签套数,	
	sum(sc.ccjtotal) as 草签未网签金额,
	sum(sg.实收金额) as 草签未网签房源已回款金额,
	sum(sf.待收金额) as 草签未网签房源待回款,
	sum(sf.逾期待收金额) as 草签未网签已逾期待回款
from data_wide_s_trade sc 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=sc.MasterBldGUID
left join #应收情况 sf on sc.tradeguid=sf.tradeguid
left join #实收情况 sg on sc.tradeguid=sg.saleguid
where year(sc.x_InitialledDate)<year(@date)
and sc.x_InitialledDate<=@date
and sc.cstatus='激活' AND sc.ContractType ='草签'  
group by 
sc.projguid,
bld.ProductTypeName
union all 
select 
	sc.projguid,
	bld.ProductTypeName as 业态,
	'本年' as 周期,
	sum(1) as 草签未网签套数,	
	sum(sc.ccjtotal) as 草签未网签金额,
	sum(sg.实收金额) as 草签未网签房源已回款金额,
	sum(sf.待收金额) as 草签未网签房源待回款,
	sum(sf.逾期待收金额) as 草签未网签已逾期待回款
from data_wide_s_trade sc 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=sc.MasterBldGUID
left join #应收情况 sf on sc.tradeguid=sf.tradeguid
left join #实收情况 sg on sc.tradeguid=sg.saleguid
where year(sc.x_InitialledDate)=year(@date)
and sc.x_InitialledDate<=@date
and sc.cstatus='激活' AND sc.ContractType ='草签'  
group by 
sc.projguid,
bld.ProductTypeName
union all 
select 
	sc.projguid,
	bld.ProductTypeName as 业态,
	'全年' as 周期,
	sum(1) as 草签未网签套数,	
	sum(sc.ccjtotal) as 草签未网签金额,
	sum(sg.实收金额) as 草签未网签房源已回款金额,
	sum(sf.待收金额) as 草签未网签房源待回款,
	sum(sf.逾期待收金额) as 草签未网签已逾期待回款
from data_wide_s_trade sc 
INNER JOIN data_wide_mdm_building bld ON bld.BuildingGUID=sc.MasterBldGUID
left join #应收情况 sf on sc.tradeguid=sf.tradeguid
left join #实收情况 sg on sc.tradeguid=sg.saleguid
where sc.x_InitialledDate<=@date
and sc.cstatus='激活' AND sc.ContractType ='草签'  
group by 
sc.projguid,
bld.ProductTypeName
) tt

SELECT
pro.projname as 项目名称,
pro.SpreadName as 推广项目名称,
fq.projshortname as 分期名称,
zq.排序,
zq.周期,
zt.业态,
isnull(sum(so.认购套数),0) as 认购套数,	
isnull(sum(so.认购金额),0)*0.0001 as 认购金额,
isnull(sum(so.认购已回款),0)*0.0001 as 认购已回款,
isnull(sum(so.认购待回款),0)*0.0001 as 认购待回款,
isnull(sum(sc.网签套数),0) as 网签套数,	
isnull(sum(sc.网签金额),0)*0.0001 as 网签金额,
isnull(sum(sc.网签非按揭金额),0)*0.0001 as 网签非按揭金额,
isnull(sum(sc.网签按揭纯商贷金额),0)*0.0001 as 网签按揭纯商贷金额,
isnull(sum(sc.网签按揭组合贷金额),0)*0.0001 as 网签按揭组合贷金额,
isnull(sum(sc.网签按揭纯公积金贷金额),0)*0.0001 as 网签按揭纯公积金贷金额,
isnull(sum(sc.网签已回款),0)*0.0001 as 网签已回款,
isnull(sum(sc.网签待回款金额),0)*0.0001 as 网签待回款金额,
isnull(sum(sc.网签待回款非按揭金额),0)*0.0001 as 网签待回款非按揭金额,
isnull(sum(sc.网签待回款按揭纯商贷金额),0)*0.0001 as 网签待回款按揭纯商贷金额,
isnull(sum(sc.网签待回款按揭组合贷金额),0)*0.0001 as 网签待回款按揭组合贷金额,
isnull(sum(sc.网签待回款按揭纯公积金贷金额),0)*0.0001 as 网签待回款按揭纯公积金贷金额,
isnull(sum(sc.网签逾期待回款金额),0)*0.0001 as 网签逾期待回款金额,
isnull(sum(sc.网签逾期待回款非按揭金额),0)*0.0001 as 网签逾期待回款非按揭金额,
isnull(sum(sc.网签逾期待回款按揭纯商贷金额),0)*0.0001 as 网签逾期待回款按揭纯商贷金额,
isnull(sum(sc.网签逾期待回款按揭组合贷金额),0)*0.0001 as 网签逾期待回款按揭组合贷金额,
isnull(sum(sc.网签逾期待回款按揭纯公积金贷金额),0)*0.0001 as 网签逾期待回款按揭纯公积金贷金额,

isnull(sum(cq.草签未网签套数),0) as 草签未网签套数,	
isnull(sum(cq.草签未网签金额),0)*0.0001 as 草签未网签金额,
isnull(sum(cq.草签未网签房源已回款金额),0)*0.0001 as 草签未网签房源已回款金额,
isnull(sum(cq.草签未网签房源待回款),0)*0.0001 as 草签未网签房源待回款,
isnull(sum(cq.草签未网签已逾期待回款),0)*0.0001 as 草签未网签已逾期待回款
from 
(
select 
bld.StageGuid as projguid,
bld.ProductTypeName as 业态
from data_wide_mdm_building bld 
where bld.ProductTypeName is not null
and bld.StageGuid in (@projguid)
group by 
bld.StageGuid,
bld.ProductTypeName
) zt
left join (select '1' as 排序,'往年' as 周期 union select '2','本年' union select '3','全年') zq on 1=1
left join #认购情况 so on zt.projguid=so.projguid and zt.业态=so.业态 and zq.周期=so.周期
left join #签约情况 sc on zt.projguid=sc.projguid and zt.业态=sc.业态 and zq.周期=sc.周期
left join #草签情况 cq on zt.projguid=cq.projguid and zt.业态=cq.业态 and zq.周期=cq.周期
inner join data_wide_mdm_project fq on zt.projguid=fq.p_projectid
inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
group by 
zq.排序,
zq.周期,
zt.业态,
pro.projname,
pro.SpreadName,
fq.projshortname

drop table #认购情况,#签约情况,#应收情况,#实收情况