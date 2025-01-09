-- 06逾期待回款账龄分析
-- 2025-01-08 调整收款日期的取数口径

select 
fq.buguid,
fq.p_projectid,
pro.projname as 项目名称,
pro.SpreadName as 推广项目名称,
fq.projshortname as 分期名称,
sum(case when st.ContractType='网签' then sf.rmbye else 0 end) as 网签逾期待回款,	
sum(case when st.ContractType='网签' and datediff(dd,sf.lastdate,getdate())<=7 then sf.rmbye else 0 end) as 网签逾期7天内,
sum(case when st.ContractType='网签' and datediff(dd,sf.lastdate,getdate()) between 8 and 30 then sf.rmbye else 0 end) as 网签逾期7至30天,	
sum(case when st.ContractType='网签' and datediff(dd,sf.lastdate,getdate()) between 31 and 90 then sf.rmbye else 0 end) as 网签逾期30至90天,	
sum(case when st.ContractType='网签' and datediff(dd,sf.lastdate,getdate()) between 91 and 180 then sf.rmbye else 0 end) as 网签逾期90至180天,	
sum(case when st.ContractType='网签' and datediff(dd,sf.lastdate,getdate())>180 then sf.rmbye else 0 end) as 网签逾期180天以上,
sum(case when st.ContractType='草签' then sf.rmbye else 0 end) as 草签逾期待回款,	
sum(case when st.ContractType='草签' and datediff(dd,sf.lastdate,getdate())<=7 then sf.rmbye else 0 end) as 草签逾期7天内,
sum(case when st.ContractType='草签' and datediff(dd,sf.lastdate,getdate()) between 8 and 30 then sf.rmbye else 0 end) as 草签逾期7至30天,	
sum(case when st.ContractType='草签' and datediff(dd,sf.lastdate,getdate()) between 31 and 90 then sf.rmbye else 0 end) as 草签逾期30至90天,	
sum(case when st.ContractType='草签' and datediff(dd,sf.lastdate,getdate()) between 91 and 180 then sf.rmbye else 0 end) as 草签逾期90至180天,	
sum(case when st.ContractType='草签' and datediff(dd,sf.lastdate,getdate())>180 then sf.rmbye else 0 end) as 草签逾期180天以上
from data_wide_s_fee sf 
inner join data_wide_s_trade st on sf.tradeguid=st.tradeguid and st.cstatus='激活'
inner join data_wide_mdm_project fq on st.projguid=fq.p_projectid
inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
where sf.lastdate<getdate() AND sf.ItemType	IN ('非贷款类房款','贷款类房款','补充协议款')
and fq.p_projectid in (@projguid)
group by 
fq.buguid,
fq.p_projectid,
pro.projname,
pro.SpreadName,
fq.projshortname
order by 
pro.projname,
pro.SpreadName,
fq.projshortname