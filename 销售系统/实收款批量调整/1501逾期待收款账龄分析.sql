-- 1501 逾期待收款账龄分析表
-- 2025-01-08 调整收款日期的取数口径
SELECT 
	sc.projname AS 项目,
	SUM(sf.rmbYe) AS 逾期待回款,
	SUM(CASE WHEN DATEDIFF(dd,sf.lastdate,@date)<=7 THEN sf.rmbYe END) AS 逾期7天,
	SUM(CASE WHEN DATEDIFF(dd,sf.lastdate,@date) BETWEEN 8 AND 30 THEN sf.rmbYe END) AS 逾期30天,
	SUM(CASE WHEN DATEDIFF(dd,sf.lastdate,@date) BETWEEN 31 AND 90 THEN sf.rmbYe END) AS 逾期90天,
	SUM(CASE WHEN DATEDIFF(dd,sf.lastdate,@date) BETWEEN 91 AND 180 THEN sf.rmbYe END) AS 逾期180天,
	SUM(CASE WHEN DATEDIFF(dd,sf.lastdate,@date) >180 THEN sf.rmbYe END) AS 逾期180天以上
FROM data_wide_s_fee sf
INNER JOIN data_wide_s_trade sc ON sf.TradeGUID=sc.tradeguid AND sc.cStatus='激活' and sc.ContractType = '网签'
WHERE sf.rmbYe>0 AND sf.lastdate<@date AND sc.ProjGUID in (@ProjGUID) and sf.itemtype in ('非贷款类房款','贷款类房款')
GROUP BY
	sc.projname