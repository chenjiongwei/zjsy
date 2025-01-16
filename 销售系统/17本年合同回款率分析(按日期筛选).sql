select * into #应收情况 from
(
	--应收款统计
	select 
	sf.projguid,
	--sf.lastdate,
	sum(sf.RmbAmount) as 应收总额,
	sum(sf.RmbYe) as 未收总额,
	sum(case when sf.itemtype in ('非贷款类房款','贷款类房款','补充协议款') then 1 end) as 应收笔数,
	sum(case when sf.itemtype in ('非贷款类房款','贷款类房款','补充协议款') then sf.Rmbamount end) as 应回款总额,
	sum(case when sf.itemtype in ('非贷款类房款','贷款类房款','补充协议款') then sf.RmbYe end) as 未回款总额,
	sum(case when sf.itemtype in ('非贷款类房款','贷款类房款') and  t.OrderType ='认购' AND t.ostatus='激活'  then sf.RmbYe end) as 认购房款未回款总额,
	sum(case when sf.itemtype in ('非贷款类房款','贷款类房款') and  t.ContractType ='草签' AND t.cstatus='激活'  then sf.RmbYe end) as 草签房款未回款总额,
	sum(case when sf.itemtype in ('非贷款类房款','贷款类房款') and  t.ContractType ='网签' AND t.cstatus='激活'    then sf.RmbYe end) as 签约房款未回款总额,

	sum(case when sf.itemtype in ('补充协议款') and  t.OrderType ='认购' AND  t.ostatus='激活' then sf.RmbYe end ) as 认购补协未回款总额,
	sum(case when sf.itemtype in ('补充协议款') and  t.ContractType ='草签'  AND t.cstatus='激活'    then sf.RmbYe end) as 草签补协未回款总额,
	sum(case when sf.itemtype in ('补充协议款') and  t.ContractType ='网签'  AND t.cstatus='激活'   then sf.RmbYe end) as 签约补协未回款总额
	from data_wide_s_fee sf 
	inner join data_wide_s_trade t on sf.tradeguid = t.TradeGUID and (t.ostatus='激活' or t.cstatus='激活' )
	where year(t.ZcOrderDate)<year(@date)
	--and t.TradeStatus ='激活' 
	group by sf.projguid
) tt

select * into #实收情况 FROM 
(
	select 
	sg.projguid,
	--sg.skdate,
	sum(sg.RmbAmount) as 实收总额,
	SUM(case when sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') AND year(sg.HKdate)<= YEAR(@date) then sg.RmbAmount end) AS 累计回款,
	sum(case when sg.itemtype='非贷款类房款' AND year(sg.HKdate)<= YEAR(@date) then sg.RmbAmount end) as 非贷款类房款实收金额,
	sum(case when sg.itemtype='贷款类房款' AND year(sg.HKdate)<= YEAR(@date)  then sg.RmbAmount end) as 贷款类房款实收金额,
	sum(case when sg.itemtype='补充协议款' AND year(sg.HKdate)<= YEAR(@date)  then sg.RmbAmount end) as 补充协议款实收金额,
	/*本年签约（网签）本年回款统计 tr.CNetQsDate 判断为本年，且回款也在本年 */
	SUM(case when year(sg.HKdate)=YEAR(@date) AND year(st.CNetQsDate)=YEAR(@date) and  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 本年网签本年回款金额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND year(st.CNetQsDate) < YEAR(@date) and  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 往年网签本年回款金额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND st.CNetQsDate IS NULL and  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 未网签本年回款金额,

	/*本年签约（含草签）取最早为本年回款统计 tr.CQsDate 判断为本年，且回款也在本年 */
	SUM(case when year(sg.HKdate)=YEAR(@date) AND year(isnull(st.CNetQsDate,st.CQsDate))=YEAR(@date) and  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 本年签约本年回款金额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND year(isnull(st.CNetQsDate,st.CQsDate)) < YEAR(@date) and  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 往年签约本年回款金额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND st.CQsDate IS NULL and  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 认购本年回款金额,

	/*本年累计回款按款项判断 */
	SUM(case when year(sg.HKdate)=YEAR(@date) AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 本年已回款总额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND  sg.itemtype = '非贷款类房款' then sg.RmbAmount end) AS 本年非贷款已回款总额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND  sg.itemtype = '贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) AS 本年公积金已回款总额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND  sg.itemtype = '贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) AS 本年按揭已回款总额,
	SUM(case when year(sg.HKdate)=YEAR(@date) AND  sg.itemtype = '补充协议款'  then sg.RmbAmount end) AS 本年补协已回款总额,

	/*本年1月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=1 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 一月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=1 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 一月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=1 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 一月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=1 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 一月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=1 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 一月补充协议累计实收,

	/*本年2月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=2 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 二月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=2 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 二月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=2 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 二月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=2 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 二月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=2 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 二月补充协议累计实收,

	/*本年3月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=3 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 三月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=3 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 三月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=3 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 三月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=3 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 三月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=3 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 三月补充协议累计实收,

	/*本年4月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=4 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 四月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=4 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 四月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=4 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 四月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=4 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 四月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=4 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 四月补充协议累计实收,

	/*本年5月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=5 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 五月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=5 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 五月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=5 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 五月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=5 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 五月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=5 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 五月补充协议累计实收,

	/*本年6月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=6 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 六月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=6 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 六月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=6 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 六月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=6 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 六月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=6 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 六月补充协议累计实收,

	/*本年7月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=7 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 七月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=7 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 七月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=7 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 七月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=7 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 七月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=7 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 七月补充协议累计实收,

	/*本年8月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=8 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 八月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=8 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 八月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=8 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 八月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=8 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 八月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=8 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 八月补充协议累计实收,

	/*本年9月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=9 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 九月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=9 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 九月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=9 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 九月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=9 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 九月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=9 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 九月补充协议累计实收,

	/*本年10月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=10 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 十月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=10 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 十月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=10 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 十月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=10 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 十月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=10 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 十月补充协议累计实收,


	/*本年11月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=11 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 十一月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=11 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 十一月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=11 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 十一月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=11 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 十一月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=11 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 十一月补充协议累计实收,

	/*本年12月回款 */
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=12 AND  sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) as 十二月累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=12 AND  sg.itemtype ='非贷款类房款' then sg.RmbAmount  end) as 十二月非贷款累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=12 AND  sg.itemtype ='贷款类房款' and sg.itemname like '%公积金%' then sg.RmbAmount end) as 十二月公积金累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=12 AND sg.itemtype ='贷款类房款' and sg.itemname like '%按揭%' then sg.RmbAmount end) as 十二月按揭累计实收,
	sum(case when year(sg.HKdate)=YEAR(@date) and month(sg.HKdate)=12 AND sg.itemtype ='补充协议款'  then sg.RmbAmount  end) as 十二月补充协议累计实收

	from (
	select 
		g.projguid,g.vouchstatus,g.SaleGUID,
		g.itemtype,
		g.itemname ,
		g.skdate,
		g.RmbAmount,
	   CASE 
			WHEN g.VouchType ='退款单' THEN  isnull (g.rzdate, g.KpDate)
			WHEN g.VouchType ='转账单' THEN  g.KpDate
			WHEN g.VouchType ='换票单' THEN  g.SkDate
			WHEN g.VouchType ='收款单' THEN 
			CASE 
					WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  NOT LIKE '%POS%' THEN g.SkDate
					WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  LIKE '%POS%'  AND  pp.ProjName IN ('珠江花玙苑','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心')  AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
					WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  LIKE '%POS%'  AND  pp.ProjName IN ('珠江花玙苑','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心')  AND wd.x_NextWorkDate IS  NULL THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
					WHEN YEAR(g.SkDate) >= 2024 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName  IN ('珠江海珠里','珠江嘉园','时光荟','同嘉路项目','钟落潭项目')   THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
					
					WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  NOT LIKE '%POS%' THEN g.SkDate
					WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江花玙苑','花屿花城','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','同嘉路项目','钟落潭项目','珠江海珠里','珠江嘉园','时光荟') THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
					WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江金悦','中侨中心') AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
					WHEN YEAR(g.SkDate) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江金悦','中侨中心') AND  wd.x_NextWorkDate IS  NULL THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)
			ELSE g.SkDate END ELSE g.SkDate END AS HKdate
				 /*
					项目名称	回款规则
					珠江·花屿花城	工作日+1
					珠实·西关都荟	工作日+1
					珠江广钢花城	工作日+1
					白云湖项目	工作日+1
					珠江花城	工作日+1
					同嘉路项目	工作日+1
					钟落潭项目	工作日+1
					珠江西湾里	工作日+1
					中侨中心	工作日+1
					珠江海珠里	自然日+1
					珠江嘉园	自然日+1
					时光荟	自然日+1
					其他项目均等于收款日期
				 */ 
	from data_wide_s_getin g 
	INNER JOIN dbo.data_wide_mdm_Project p ON p.p_projectId = g.ProjGUID
	INNER JOIN data_wide_mdm_Project pp  ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2	
	LEFT JOIN data_wide_s_Holiday wd ON CONVERT(VARCHAR ,DATEADD(DAY, 1, g.SkDate) ,23)  = CONVERT(VARCHAR,wd.x_vacationDate,23)
	where   isnull(g.vouchstatus,'')<>'作废' AND  g.VouchType NOT IN ( 'POS机单', '划拨单', '放款单' )
	) sg 
	LEFT join data_wide_s_trade st on sg.SaleGUID=st.tradeguid   AND  st.IsLast = 1 
--((st.cstatus='激活' or st.ostatus='激活') or (st.OCloseReason in ('换房','退房') and  st.OStatus='关闭'))
	--where isnull(sg.vouchstatus,'')<>'作废'
	group by sg.projguid
) tt

 select 
    fq.buguid,
    --fq.p_projectid,
	pro.p_projectid,
    pro.projname as 项目名称,
	--CASE WHEN ISNULL(pro.SpreadName, '') = '' THEN pro.ProjName ELSE pro.SpreadName END AS 项目推广名 ,
    pro.SpreadName as 推广项目名称,
    --fq.projshortname as 分期名称,
    isnull(sum(sf.应回款总额),0)*0.0001 as 应回款总额,	
    isnull(sum(sf.未回款总额),0)*0.0001 as 未回款总额,
	isnull(sum(sf.认购房款未回款总额),0)*0.0001 as 认购房款未回款总额,
	isnull(sum(sf.草签房款未回款总额),0)*0.0001 as 草签房款未回款总额,
	isnull(sum(sf.签约房款未回款总额),0)*0.0001 as 签约房款未回款总额,
	isnull(sum(sf.认购补协未回款总额),0)*0.0001 as 认购补协未回款总额,
	isnull(sum(sf.草签补协未回款总额),0)*0.0001 as 草签补协未回款总额,
	isnull(sum(sf.签约补协未回款总额),0)*0.0001 as 签约补协未回款总额,
	
	isnull(sum(sg.累计回款),0)*0.0001 as 累计回款,
	isnull(sum(sg.非贷款类房款实收金额),0)*0.0001 as 非贷款类房款实收金额,
	isnull(sum(sg.贷款类房款实收金额),0)*0.0001 as 贷款类房款实收金额,
	isnull(sum(sg.补充协议款实收金额),0)*0.0001 as 补充协议款实收金额,

	isnull(sum(sg.本年网签本年回款金额),0)*0.0001 as 本年网签本年回款金额,
	isnull(sum(sg.往年网签本年回款金额),0)*0.0001 as 往年网签本年回款金额,
	isnull(sum(sg.本年网签本年回款金额),0)*0.0001+isnull(sum(sg.往年网签本年回款金额),0)*0.0001 AS 网签回款小计,
	isnull(sum(sg.未网签本年回款金额),0)*0.0001 as 未网签本年回款金额,
	isnull(sum(sg.本年网签本年回款金额),0)*0.0001+isnull(sum(sg.往年网签本年回款金额),0)*0.0001+isnull(sum(sg.未网签本年回款金额),0)*0.0001 AS 网签回款合计,


	isnull(sum(sg.本年签约本年回款金额),0)*0.0001 as 本年签约本年回款金额,
	isnull(sum(sg.往年签约本年回款金额),0)*0.0001 as 往年签约本年回款金额,
	isnull(sum(sg.本年签约本年回款金额),0)*0.0001 + isnull(sum(sg.往年签约本年回款金额),0)*0.0001 AS 签约回款小计,
	isnull(sum(sg.认购本年回款金额),0)*0.0001 as 认购本年回款金额,
	isnull(sum(sg.本年签约本年回款金额),0)*0.0001 + isnull(sum(sg.往年签约本年回款金额),0)*0.0001 + isnull(sum(sg.认购本年回款金额),0)*0.0001 AS 签约回款合计,

	isnull(sum(sg.本年已回款总额),0)*0.0001 as 本年已回款总额,
	isnull(sum(sg.本年非贷款已回款总额),0)*0.0001 as 本年非贷款已回款总额,
	isnull(sum(sg.本年公积金已回款总额),0)*0.0001 as 本年公积金已回款总额,
	isnull(sum(sg.本年按揭已回款总额),0)*0.0001 as 本年按揭已回款总额,
	isnull(sum(sg.本年补协已回款总额),0)*0.0001 as 本年补协已回款总额,

	isnull(sum(sg.一月累计实收),0)*0.0001 as 一月累计实收,
	isnull(sum(sg.一月非贷款累计实收),0)*0.0001 as 一月非贷款累计实收,
	isnull(sum(sg.一月公积金累计实收),0)*0.0001 as 一月公积金累计实收,
	isnull(sum(sg.一月按揭累计实收),0)*0.0001 as 一月按揭累计实收,
	isnull(sum(sg.一月补充协议累计实收),0)*0.0001 as 一月补充协议累计实收,

	isnull(sum(sg.二月累计实收),0)*0.0001 as 二月累计实收,
	isnull(sum(sg.二月非贷款累计实收),0)*0.0001 as 二月非贷款累计实收,
	isnull(sum(sg.二月公积金累计实收),0)*0.0001 as 二月公积金累计实收,
	isnull(sum(sg.二月按揭累计实收),0)*0.0001 as 二月按揭累计实收,
	isnull(sum(sg.二月补充协议累计实收),0)*0.0001 as 二月补充协议累计实收,

	isnull(sum(sg.三月累计实收),0)*0.0001 as 三月累计实收,
	isnull(sum(sg.三月非贷款累计实收),0)*0.0001 as 三月非贷款累计实收,
	isnull(sum(sg.三月公积金累计实收),0)*0.0001 as 三月公积金累计实收,
	isnull(sum(sg.三月按揭累计实收),0)*0.0001 as 三月按揭累计实收,
	isnull(sum(sg.三月补充协议累计实收),0)*0.0001 as 三月补充协议累计实收,

	isnull(sum(sg.四月累计实收),0)*0.0001 as 四月累计实收,
	isnull(sum(sg.四月非贷款累计实收),0)*0.0001 as 四月非贷款累计实收,
	isnull(sum(sg.四月公积金累计实收),0)*0.0001 as 四月公积金累计实收,
	isnull(sum(sg.四月按揭累计实收),0)*0.0001 as 四月按揭累计实收,
	isnull(sum(sg.四月补充协议累计实收),0)*0.0001 as 四月补充协议累计实收,

	isnull(sum(sg.五月累计实收),0)*0.0001 as 五月累计实收,
	isnull(sum(sg.五月非贷款累计实收),0)*0.0001 as 五月非贷款累计实收,
	isnull(sum(sg.五月公积金累计实收),0)*0.0001 as 五月公积金累计实收,
	isnull(sum(sg.五月按揭累计实收),0)*0.0001 as 五月按揭累计实收,
	isnull(sum(sg.五月补充协议累计实收),0)*0.0001 as 五月补充协议累计实收,

	isnull(sum(sg.六月累计实收),0)*0.0001 as 六月累计实收,
	isnull(sum(sg.六月非贷款累计实收),0)*0.0001 as 六月非贷款累计实收,
	isnull(sum(sg.六月公积金累计实收),0)*0.0001 as 六月公积金累计实收,
	isnull(sum(sg.六月按揭累计实收),0)*0.0001 as 六月按揭累计实收,
	isnull(sum(sg.六月补充协议累计实收),0)*0.0001 as 六月补充协议累计实收,

	isnull(sum(sg.七月累计实收),0)*0.0001 as 七月累计实收,
	isnull(sum(sg.七月非贷款累计实收),0)*0.0001 as 七月非贷款累计实收,
	isnull(sum(sg.七月公积金累计实收),0)*0.0001 as 七月公积金累计实收,
	isnull(sum(sg.七月按揭累计实收),0)*0.0001 as 七月按揭累计实收,
	isnull(sum(sg.七月补充协议累计实收),0)*0.0001 as 七月补充协议累计实收,

	isnull(sum(sg.八月累计实收),0)*0.0001 as 八月累计实收,
	isnull(sum(sg.八月非贷款累计实收),0)*0.0001 as 八月非贷款累计实收,
	isnull(sum(sg.八月公积金累计实收),0)*0.0001 as 八月公积金累计实收,
	isnull(sum(sg.八月按揭累计实收),0)*0.0001 as 八月按揭累计实收,
	isnull(sum(sg.八月补充协议累计实收),0)*0.0001 as 八月补充协议累计实收,

	isnull(sum(sg.九月累计实收),0)*0.0001 as 九月累计实收,
	isnull(sum(sg.九月非贷款累计实收),0)*0.0001 as 九月非贷款累计实收,
	isnull(sum(sg.九月公积金累计实收),0)*0.0001 as 九月公积金累计实收,
	isnull(sum(sg.九月按揭累计实收),0)*0.0001 as 九月按揭累计实收,
	isnull(sum(sg.九月补充协议累计实收),0)*0.0001 as 九月补充协议累计实收,

	isnull(sum(sg.十月累计实收),0)*0.0001 as 十月累计实收,
	isnull(sum(sg.十月非贷款累计实收),0)*0.0001 as 十月非贷款累计实收,
	isnull(sum(sg.十月公积金累计实收),0)*0.0001 as 十月公积金累计实收,
	isnull(sum(sg.十月按揭累计实收),0)*0.0001 as 十月按揭累计实收,
	isnull(sum(sg.十月补充协议累计实收),0)*0.0001 as 十月补充协议累计实收,

	isnull(sum(sg.十一月累计实收),0)*0.0001 as 十一月累计实收,
	isnull(sum(sg.十一月非贷款累计实收),0)*0.0001 as 十一月非贷款累计实收,
	isnull(sum(sg.十一月公积金累计实收),0)*0.0001 as 十一月公积金累计实收,
	isnull(sum(sg.十一月按揭累计实收),0)*0.0001 as 十一月按揭累计实收,
	isnull(sum(sg.十一月补充协议累计实收),0)*0.0001 as 十一月补充协议累计实收,

	isnull(sum(sg.十二月累计实收),0)*0.0001 as 十二月累计实收,
	isnull(sum(sg.十二月非贷款累计实收),0)*0.0001 as 十二月非贷款累计实收,
	isnull(sum(sg.十二月公积金累计实收),0)*0.0001 as 十二月公积金累计实收,
	isnull(sum(sg.十二月按揭累计实收),0)*0.0001 as 十二月按揭累计实收,
	isnull(sum(sg.十二月补充协议累计实收),0)*0.0001 as 十二月补充协议累计实收

from  #实收情况 sg 
left join #应收情况 sf on sf.projguid=sg.projguid
inner join data_wide_mdm_project fq on sg.projguid=fq.p_projectid
inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
where fq.parentguid in (@projguid)
group by 
fq.buguid,
pro.projname,
pro.SpreadName,
pro.p_projectid
order by 
pro.projname

drop table #应收情况,#实收情况