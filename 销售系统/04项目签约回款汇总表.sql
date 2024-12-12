--ZSDC-04-项目签约回款汇总表-2024.8调整
IF @var_bbh ='实时' 
BEGIN

with 
	业绩情况 as 
	(
	select 
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
	from data_wide_s_trade st 
		left join data_wide_s_room sr on st.roomguid=sr.roomguid 
		left join data_wide_mdm_project pro on st.parentprojguid=pro.p_projectid
		where (st.cstatus='激活' or st.ostatus='激活')
		and st.projguid in (@projguid)
		group by 
		st.parentprojguid,
		st.parentprojname,
		pro.SpreadName
	),
回款情况 as 
	(
	select 
		st.parentprojguid,
		sum(sg.amount) as 本年已回款
	from data_wide_s_getin sg 
		inner join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
		where sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
		and isnull(sg.vouchstatus,'') !='作废'
		and year(sg.skdate)=year(getdate())
		and st.projguid in (@projguid)
		group by 
		st.parentprojguid
	),

--SELECT  TOP 10 * FROM data_wide_s_trade WHERE TradeStatus='关闭' AND CCloseReason ='退房'

退款情况 AS 
	(
	SELECT st.parentprojguid,
		   sum(sg.amount) as 本年已退款
	from data_wide_s_getin sg 
		inner join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and st.TradeStatus='关闭' AND  st.OCloseReason ='退房'
		where sg.itemtype in ('贷款类房款','非贷款类房款','补充协议款')
		and isnull(sg.vouchstatus,'') !='作废'
		and year(sg.skdate)=year(getdate())
        and sg.vouchtype='退款单'
		and st.projguid in (@projguid)
		group by 
		st.parentprojguid
	),


应收情况 as 
	(
	select 
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
	--往年草签未回款
	sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) < YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 往年已草签未网签按揭款,
	sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) < YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 往年已草签未网签非贷款类房款,
	sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) < YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 往年已草签未网签补充协议款,
	--半年草签未回款
	sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) = YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 本年已草签未网签按揭款,
	sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) = YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 本年已草签未网签非贷款类房款,
	sum(case when st.cstatus='激活' and st.CNetQsDate is null AND YEAR(st.x_InitialledDate) = YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 本年已草签未网签补充协议款,

	sum(case when st.cstatus='激活' and st.CNetQsDate is not null and datediff(dd,sf.lastdate,getdate())<0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已网签逾期非按揭款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null and datediff(dd,sf.lastdate,getdate())>=0 and sf.itemtype IN ('非贷款类房款','补充协议款') then sf.rmbye else 0 end) as 已网签未到期非按揭款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 已网签按揭款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 已网签非贷款类房款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 已网签补充协议款,
	--往年签约未回款
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) < YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 往年已网签按揭款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) < YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 往年已网签非贷款类房款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) < YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 往年已网签补充协议款,
	--本年签约未回款
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) = YEAR(getdate()) and sf.itemtype='贷款类房款' then sf.rmbye else 0 end) as 本年已网签按揭款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) = YEAR(getdate()) and sf.itemtype='非贷款类房款' then sf.rmbye else 0 end) as 本年已网签非贷款类房款, 
	sum(case when st.cstatus='激活' and st.CNetQsDate is not null AND YEAR(st.CNetQsDate) = YEAR(getdate()) and sf.itemtype='补充协议款' then sf.rmbye else 0 end) as 本年已网签补充协议款
	from data_wide_s_fee sf 
	inner join data_wide_s_trade st on sf.tradeguid=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
	where sf.itemtype in  ('贷款类房款','非贷款类房款','补充协议款')
	and sf.rmbye<>0
	and st.projguid in (@projguid)
	group by 
	st.parentprojguid
	),

销售计划 as 
	(
	select 
	mb.parentprojguid,
	sum(case when mb.year=year(getdate()) and mb.month=13 then mb.BudgetContractAmount else 0 end) as 本年签约指标,--系统录入的目标为万元单位
	sum(case when mb.year=year(getdate()) and mb.month=13 then mb.BudgetGetinAmount else 0 end) as 本年回款指标
	from data_wide_s_SalesBudget mb 
	where mb.projguid in (@projguid)
	group by 
	mb.parentprojguid
	)

select 
    null as SnapshotTime,
    null as VersionNo,
    null as BUGUID,
    null as ProjGUID,
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
	isnull(sg.本年已回款,0)*0.0001 as 本年已回款,isnull(tk.本年已退款,0)*0.0001 AS 本年已退款,
	isnull(sg.本年已回款*0.0001/nullif(mb.本年回款指标,0),0) as 本年回款完成率集团版,
	0 as 本年回款完成率内控版,	
	isnull(sf.逾期非按揭款,0)*0.0001 as 逾期非按揭款, 
	isnull(sf.未到期非按揭款,0)*0.0001 as 未到期非按揭款, 
	isnull(sf.按揭款,0)*0.0001 as 按揭款,  isnull(sf.补充协议款,0)*0.0001 as 补充协议款, isnull(sf.非贷款类房款,0)*0.0001 as 非贷款类房款, 
	isnull(sf.已认购未签约逾期非按揭款,0)*0.0001 as 已认购未签约逾期非按揭款, 
	isnull(sf.已认购未签约未到期非按揭款,0)*0.0001 as 已认购未签约未到期非按揭款, 
	isnull(sf.已认购未签约按揭款,0)*0.0001 as 已认购未签约按揭款, isnull(sf.已认购未签约非贷款类房款,0)*0.0001 as 已认购未签约非贷款类房款, isnull(sf.已认购未签约补充协议款,0)*0.0001 as 已认购未签约补充协议款,
	isnull(sf.已草签未网签逾期非按揭款,0)*0.0001 as 已草签未网签逾期非按揭款, 
	isnull(sf.已草签未网签未到期非按揭款,0)*0.0001 as 已草签未网签未到期非按揭款, 
	isnull(sf.已草签未网签按揭款,0)*0.0001 as 已草签未网签按揭款, isnull(sf.已草签未网签非贷款类房款,0)*0.0001 as 已草签未网签非贷款类房款, isnull(sf.已草签未网签补充协议款,0)*0.0001 as 已草签未网签补充协议款, 
	isnull(sf.往年已草签未网签按揭款,0)*0.0001 as 往年已草签未网签按揭款, isnull(sf.往年已草签未网签非贷款类房款,0)*0.0001 as 往年已草签未网签非贷款类房款, isnull(sf.往年已草签未网签补充协议款,0)*0.0001 as 往年已草签未网签补充协议款, 
	isnull(sf.本年已草签未网签按揭款,0)*0.0001 as 本年已草签未网签按揭款, isnull(sf.本年已草签未网签非贷款类房款,0)*0.0001 as 本年已草签未网签非贷款类房款, isnull(sf.本年已草签未网签补充协议款,0)*0.0001 as 本年已草签未网签补充协议款, 
	isnull(sf.已网签逾期非按揭款,0)*0.0001 as 已网签逾期非按揭款, 
	isnull(sf.已网签未到期非按揭款,0)*0.0001 as 已网签未到期非按揭款, 
	isnull(sf.已网签按揭款,0)*0.0001 as 已网签按揭款, isnull(sf.已网签非贷款类房款,0)*0.0001 as 已网签非贷款类房款,isnull(sf.已网签补充协议款,0)*0.0001 as 已网签补充协议款,
	isnull(sf.往年已网签按揭款,0)*0.0001 as 往年已网签按揭款, isnull(sf.往年已网签非贷款类房款,0)*0.0001 as 往年已网签非贷款类房款,isnull(sf.往年已网签补充协议款,0)*0.0001 as 往年已网签补充协议款,
	isnull(sf.本年已网签按揭款,0)*0.0001 as 本年已网签按揭款, isnull(sf.本年已网签非贷款类房款,0)*0.0001 as 本年已网签非贷款类房款,isnull(sf.本年已网签补充协议款,0)*0.0001 as 本年已网签补充协议款
from 业绩情况 st 
left join 回款情况 sg on st.parentprojguid=sg.parentprojguid
left join 应收情况 sf on st.parentprojguid=sf.parentprojguid
left join 销售计划 mb on st.parentprojguid=mb.parentprojguid
left join 退款情况 tk on st.parentprojguid=tk.parentprojguid

END
ELSE 
BEGIN
select 
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
from dbo.Result_ProjectSigningPaymentSummary
where VersionNo = @var_bbh
   and ProjGUID in (select distinct parentguid from data_wide_mdm_project where p_projectid in (@projguid))

END