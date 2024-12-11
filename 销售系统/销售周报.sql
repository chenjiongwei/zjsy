USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_项目销售周报]    Script Date: 2024/12/11 14:08:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_s_项目销售周报]      
 (      
 @var_proj VARCHAR(MAX),              
 @var_enddate DATETIME      
 )                  
AS                  
BEGIN  

set  @var_enddate=convert(varchar(10),@var_enddate,120)+' 23:59:59' 

select tt.* into  #来访来电 from 
(
select 
op.projguid,
'本周新增' as 周期,
sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
from data_wide_s_Opportunity op
where op.status<>'丢失'
and datediff(ww,op.FirstGjDate-1,@var_enddate-1)=0
group by 
op.projguid
union all
select 
op.projguid,
'本月' as 周期,
sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
from data_wide_s_Opportunity op
where op.status<>'丢失'
and datediff(mm,op.FirstGjDate,@var_enddate)=0
group by 
op.projguid
union all
select 
op.projguid,
'本年' as 周期,
sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
from data_wide_s_Opportunity op
where op.status<>'丢失'
and datediff(yy,op.FirstGjDate,@var_enddate)=0
group by 
op.projguid
union all
select 
op.projguid,
'全盘' as 周期,
sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
from data_wide_s_Opportunity op
where op.status<>'丢失'
group by 
op.projguid
) tt

select tt.* into  #认购情况 from  
(
select 
so.projguid,
so.TopProductTypeName as 业态,
'本周新增' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ocjbldarea,so.ccjbldarea)) as 认购面积,
sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
from data_wide_s_trade so 
where (so.ostatus='激活' or so.cstatus='激活')
and datediff(ww,so.ZcOrderDate-1,@var_enddate-1)=0
group by 
so.projguid,
so.TopProductTypeName
UNION ALL 
select 
so.projguid,
so.TopProductTypeName as 业态,
'本月' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ocjbldarea,so.ccjbldarea)) as 认购面积,
sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
from data_wide_s_trade so 
where (so.ostatus='激活' or so.cstatus='激活')
and datediff(mm,so.ZcOrderDate,@var_enddate)=0
group by 
so.projguid,
so.TopProductTypeName
UNION ALL 
select 
so.projguid,
so.TopProductTypeName as 业态,
'本年' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ocjbldarea,so.ccjbldarea)) as 认购面积,
sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
from data_wide_s_trade so 
where (so.ostatus='激活' or so.cstatus='激活')
and datediff(yy,so.ZcOrderDate,@var_enddate)=0
group by 
so.projguid,
so.TopProductTypeName
UNION ALL 
select 
so.projguid,
so.TopProductTypeName as 业态,
'全盘' as 周期,
sum(1) as 认购套数,	
sum(isnull(so.ccjbldarea,so.ocjbldarea)) as 认购面积,
sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
from data_wide_s_trade so 
where (so.ostatus='激活' or so.cstatus='激活')
group by 
so.projguid,
so.TopProductTypeName
) tt

select tt.* into  #认购退房情况 from 
(
select 
tf.projguid,
tf.TopProductTypeName as 业态,
'本周新增' as 周期,
sum(1) as 认购退房套数,	
sum(tf.ocjbldarea) as 认购退房面积,
sum(tf.ocjtotal) as 认购退房金额
from data_wide_s_trade tf 
where year(tf.ZcOrderDate)=year(@var_enddate)
and datediff(ww,tf.ocloseDate-1,@var_enddate-1)=0
and tf.oclosereason='退房'
group by 
tf.projguid,
tf.TopProductTypeName
UNION ALL 
select 
tf.projguid,
tf.TopProductTypeName as 业态,
'本月' as 周期,
sum(1) as 认购退房套数,	
sum(tf.ocjbldarea) as 认购退房面积,
sum(tf.ocjtotal) as 认购退房金额
from data_wide_s_trade tf 
where year(tf.ZcOrderDate)=year(@var_enddate)
and datediff(mm,tf.ocloseDate,@var_enddate)=0
and tf.oclosereason='退房'
group by 
tf.projguid,
tf.TopProductTypeName
UNION ALL 
select 
tf.projguid,
tf.TopProductTypeName as 业态,
'本年' as 周期,
sum(1) as 认购退房套数,	
sum(tf.ocjbldarea) as 认购退房面积,
sum(tf.ocjtotal) as 认购退房金额
from data_wide_s_trade tf 
where year(tf.ZcOrderDate)=year(@var_enddate)
and datediff(yy,tf.ocloseDate,@var_enddate)=0
and tf.oclosereason='退房'
group by 
tf.projguid,
tf.TopProductTypeName
UNION ALL 
select 
tf.projguid,
tf.TopProductTypeName as 业态,
'全盘' as 周期,
sum(1) as 认购退房套数,	
sum(tf.ocjbldarea) as 认购退房面积,
sum(tf.ocjtotal) as 认购退房金额
from data_wide_s_trade tf 
where year(tf.ZcOrderDate)=year(@var_enddate)
and tf.oclosereason='退房'
group by 
tf.projguid,
tf.TopProductTypeName
) tt

select tt.* into  #签约情况 from 
(
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'本周新增' as 周期,
sum(1) as 净签约套数,	
sum(sc.ccjbldarea) as 净签约面积,
sum(sc.ccjtotal) as 净签约金额,
sum(case when yq.tradeguid is not null then 1 else 0 end) as 延期付款净签约套数
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
left join 
(
select 
yq.tradeguid
from data_wide_s_SaleModiApply yq
where yq.applytype in ('延期付款','延期付款(签约)')
and yq.ApplyStatus='已执行' 
--and yq.SaleType='签约'
group by 
yq.tradeguid
) yq on sc.tradeguid=yq.tradeguid
where sc.cstatus='激活'
and datediff(ww,sr.x_YeJiTime-1,@var_enddate-1)=0
group by 
sc.projguid,
sc.TopProductTypeName
UNION ALL 
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'本月' as 周期,
sum(1) as 净签约套数,	
sum(sc.ccjbldarea) as 净签约面积,
sum(sc.ccjtotal) as 净签约金额,
sum(case when yq.tradeguid is not null then 1 else 0 end) as 延期付款净签约套数
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
left join 
(
select 
yq.tradeguid
from data_wide_s_SaleModiApply yq
where yq.applytype in ('延期付款','延期付款(签约)')
and yq.ApplyStatus='已执行' 
--and yq.SaleType='签约'
group by 
yq.tradeguid
) yq on sc.tradeguid=yq.tradeguid
where sc.cstatus='激活'
and datediff(mm,sr.x_YeJiTime,@var_enddate)=0
group by 
sc.projguid,
sc.TopProductTypeName
UNION ALL 
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'本年' as 周期,
sum(1) as 净签约套数,	
sum(sc.ccjbldarea) as 净签约面积,
sum(sc.ccjtotal) as 净签约金额,
sum(case when yq.tradeguid is not null then 1 else 0 end) as 延期付款净签约套数
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
left join 
(
select 
yq.tradeguid
from data_wide_s_SaleModiApply yq
where yq.applytype in ('延期付款','延期付款(签约)')
and yq.ApplyStatus='已执行' 
--and yq.SaleType='签约'
group by 
yq.tradeguid
) yq on sc.tradeguid=yq.tradeguid
where sc.cstatus='激活'
and datediff(yy,sr.x_YeJiTime,@var_enddate)=0
group by 
sc.projguid,
sc.TopProductTypeName
UNION ALL 
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'全盘' as 周期,
sum(1) as 净签约套数,	
sum(sc.ccjbldarea) as 净签约面积,
sum(sc.ccjtotal) as 净签约金额,
sum(case when yq.tradeguid is not null then 1 else 0 end) as 延期付款净签约套数
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
left join 
(
select 
yq.tradeguid
from data_wide_s_SaleModiApply yq
where yq.applytype in ('延期付款','延期付款(签约)')
and yq.ApplyStatus='已执行' 
--and yq.SaleType='签约'
group by 
yq.tradeguid
) yq on sc.tradeguid=yq.tradeguid
where sc.cstatus='激活'
and sr.x_YeJiTime is not null
group by 
sc.projguid,
sc.TopProductTypeName
) tt

select tt.* into  #签约重售情况 from 
(
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'本周新增' as 周期,
sum(1) as 签约重售套数,	
sum(sc.ccjbldarea) as 签约重售面积,
sum(sc.ccjtotal) as 签约重售金额
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
where sc.cstatus='激活'
and year(sr.x_YeJiTime)<year(@var_enddate)
and datediff(ww,isnull(sc.x_InitialledDate,sc.CNetQsDate)-1,@var_enddate-1)=0
group by 
sc.projguid,
sc.TopProductTypeName
UNION ALL 
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'本月' as 周期,
sum(1) as 签约重售套数,	
sum(sc.ccjbldarea) as 签约重售面积,
sum(sc.ccjtotal) as 签约重售金额
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
where sc.cstatus='激活'
and year(sr.x_YeJiTime)<year(@var_enddate)
and datediff(mm,isnull(sc.x_InitialledDate,sc.CNetQsDate),@var_enddate)=0
group by 
sc.projguid,
sc.TopProductTypeName
UNION ALL 
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'本年' as 周期,
sum(1) as 签约重售套数,	
sum(sc.ccjbldarea) as 签约重售面积,
sum(sc.ccjtotal) as 签约重售金额
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
where sc.cstatus='激活'
and year(sr.x_YeJiTime)<year(@var_enddate)
and datediff(yy,isnull(sc.x_InitialledDate,sc.CNetQsDate),@var_enddate)=0
group by 
sc.projguid,
sc.TopProductTypeName
UNION ALL 
select 
sc.projguid,
sc.TopProductTypeName as 业态,
'全盘' as 周期,
sum(1) as 签约重售套数,	
sum(sc.ccjbldarea) as 签约重售面积,
sum(sc.ccjtotal) as 签约重售金额
from data_wide_s_trade sc
left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
where sc.cstatus='激活'
and year(sr.x_YeJiTime)<year(@var_enddate)
and year(isnull(sc.x_InitialledDate,sc.CNetQsDate))>=year(@var_enddate)
group by 
sc.projguid,
sc.TopProductTypeName
) tt

select tt.* into  #实收情况 from 
(
select 
st.projguid,
st.TopProductTypeName as 业态,
'本周新增' as 周期,
sum(case when st.cstatus='激活' and year(st.cqsdate)=year(@var_enddate) then sg.amount else 0 end) as 本年签约回款,
sum(case when st.cstatus='激活' and year(st.cqsdate)<year(@var_enddate) then sg.amount else 0 end) as 往年签约回款,
sum(case when st.ostatus='激活' then sg.amount else 0 end) as 认购未签约回款
from data_wide_s_getin sg 
inner join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
where sg.vouchstatus<>'作废'
and sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
and datediff(ww,sg.skdate-1,@var_enddate-1)=0
group by 
st.projguid,
st.TopProductTypeName
union all 
select 
st.projguid,
st.TopProductTypeName as 业态,
'本月' as 周期,
sum(case when st.cstatus='激活' and year(st.cqsdate)=year(@var_enddate) then sg.amount else 0 end) as 本年签约回款,
sum(case when st.cstatus='激活' and year(st.cqsdate)<year(@var_enddate) then sg.amount else 0 end) as 往年签约回款,
sum(case when st.ostatus='激活' then sg.amount else 0 end) as 认购未签约回款
from data_wide_s_getin sg 
inner join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
where sg.vouchstatus<>'作废'
and sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
and datediff(mm,sg.skdate,@var_enddate)=0
group by 
st.projguid,
st.TopProductTypeName
union all 
select 
st.projguid,
st.TopProductTypeName as 业态,
'本年' as 周期,
sum(case when st.cstatus='激活' and year(st.cqsdate)=year(@var_enddate) then sg.amount else 0 end) as 本年签约回款,
sum(case when st.cstatus='激活' and year(st.cqsdate)<year(@var_enddate) then sg.amount else 0 end) as 往年签约回款,
sum(case when st.ostatus='激活' then sg.amount else 0 end) as 认购未签约回款
from data_wide_s_getin sg 
inner join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
where sg.vouchstatus<>'作废'
and sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
and datediff(yy,sg.skdate,@var_enddate)=0
group by 
st.projguid,
st.TopProductTypeName
union all 
select 
st.projguid,
st.TopProductTypeName as 业态,
'全盘' as 周期,
sum(case when st.cstatus='激活' and year(st.cqsdate)=year(@var_enddate) then sg.amount else 0 end) as 本年签约回款,
sum(case when st.cstatus='激活' and year(st.cqsdate)<year(@var_enddate) then sg.amount else 0 end) as 往年签约回款,
sum(case when st.ostatus='激活' then sg.amount else 0 end) as 认购未签约回款
from data_wide_s_getin sg 
inner join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
where sg.vouchstatus<>'作废'
and sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
group by 
st.projguid,
st.TopProductTypeName
) tt

select
zt.projguid,
zt.业态,
zq.排序,
zq.周期,
lf.来访统计,
lf.来电统计,
so.认购套数,	
so.认购面积,
so.认购金额,
so.预选套数,	
so.预选面积,
so.预选金额,
tf.认购退房套数,	
tf.认购退房面积,
tf.认购退房金额,
sc.净签约套数,	
sc.净签约面积,
sc.净签约金额,
sc.延期付款净签约套数,
cs.签约重售套数,	
cs.签约重售面积,
cs.签约重售金额,
sg.本年签约回款,
sg.往年签约回款,
sg.认购未签约回款
from 
(
select 
fq.p_projectId as ProjGUID,
isnull(sr.TopProductTypeName,'住宅') as 业态
from data_wide_mdm_Project fq 
left join data_wide_s_room sr on fq.p_projectId=sr.ProjGUID
where (fq.p_projectId in (SELECT AllItem FROM fn_split_new(@var_proj,',')) or @var_proj='00000000-0000-0000-0000-000000000000')
group by 
fq.p_projectId,
isnull(sr.TopProductTypeName,'住宅')
) zt
left join (select '1' as 排序,'本周新增' as 周期 union select '2','本月' union select '3','本年' union select '4','全盘') zq on 1=1
left join #来访来电 lf on zt.projguid=lf.projguid and zq.周期=lf.周期
left join #认购情况 so on zt.projguid=so.projguid and zt.业态=so.业态 and zq.周期=so.周期
left join #认购退房情况 tf on zt.projguid=tf.projguid and zt.业态=tf.业态 and zq.周期=tf.周期
left join #签约情况 sc on zt.projguid=sc.projguid and zt.业态=sc.业态 and zq.周期=sc.周期
left join #签约重售情况 cs on zt.projguid=cs.projguid and zt.业态=cs.业态 and zq.周期=cs.周期
left join #实收情况 sg on zt.projguid=sg.projguid and zt.业态=sg.业态 and zq.周期=sg.周期

drop table #来访来电,#认购情况,#认购退房情况,#签约情况,#签约重售情况,#实收情况

END












