-- 15已网签按揭待回笼分析表
-- 2025-01-08 调整收款日期的取数口径

WITH 未回款分析 AS 
(
	SELECT 
	    pro.spreadname as 推广项目,
	    sc.projname AS 项目,
		sc.projcode AS 项目编码,
		sc.ProjGUID,
		sf.rmbYe AS 未收金额,
		CASE WHEN sf.lastdate<@date THEN '是' ELSE '否' END AS 是否逾期,
		CASE 
			WHEN sf.itemname LIKE '%首期%' THEN '首期'
			WHEN sf.itemtype='非贷款类房款' THEN '非贷款类房款'
			WHEN sf.itemtype='贷款类房款' THEN '贷款类房款'
		END AS 款项类型,
		CASE WHEN sf.itemname='公积金' THEN '公积金' WHEN sf.itemtype='贷款类房款' THEN '商贷' END AS 贷款类型,
		sc.ajServiceProc AS 商贷未回款原因,
		sc.gjjServiceProc AS 公积金未回款原因
	FROM data_wide_s_fee sf
	INNER JOIN data_wide_s_trade sc ON sf.TradeGUID=sc.tradeguid AND sc.cStatus='激活' and sc.ContractType = '网签'
	left join data_wide_mdm_project pro on sc.parentprojguid=pro.p_projectid
	WHERE sf.rmbYe>0 AND sc.ProjGUID IN (@ProjGUID) and sf.itemtype in ('非贷款类房款','贷款类房款')
)

SELECT 
  tt.推广项目,
	tt.项目,
	tt.ProjGUID,
	SUM(tt.未收金额) AS 已签约待回款,
	SUM(CASE WHEN tt.是否逾期='是' THEN tt.未收金额 END) AS 逾期待回款,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.款项类型='首期' THEN tt.未收金额 END) AS 逾期首付分期,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.款项类型='非贷款类房款' THEN tt.未收金额 END) AS 逾期全款,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.款项类型='贷款类房款' THEN tt.未收金额 END) AS 逾期按揭,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' THEN tt.未收金额 END) AS 逾期商贷,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='网签资料不齐' THEN tt.未收金额 END) AS 逾期商贷网签资料不齐,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='揭资料不齐' THEN tt.未收金额 END) AS 逾期商贷按揭资料不齐,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='按揭资料待送审' THEN tt.未收金额 END) AS 逾期商贷按揭资料待送审,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='按揭资料待送审' THEN tt.未收金额 END) AS 逾期商贷审核中,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='拒贷' THEN tt.未收金额 END) AS 逾期商贷拒贷,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='审核通过预告预抵押' THEN tt.未收金额 END) AS 逾期商贷审核通过预告预抵押,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='预告预抵押后待放款' THEN tt.未收金额 END) AS 逾期商贷预告预抵押后待放款,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' THEN tt.未收金额 END) AS 逾期公积金,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='网签资料不齐' THEN tt.未收金额 END) AS 逾期公积金网签资料不齐,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='按揭资料不齐' THEN tt.未收金额 END) AS 逾期公积金按揭资料不齐,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='按揭资料待送审' THEN tt.未收金额 END) AS 逾期公积金按揭资料待送审,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='审核中' THEN tt.未收金额 END) AS 逾期公积金审核中,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='拒贷' THEN tt.未收金额 END) AS 逾期公积金拒贷,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='审核通过预告预抵押' THEN tt.未收金额 END) AS 逾期公积金审核通过预告预抵押,
	SUM(CASE WHEN tt.是否逾期='是' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='预告预抵押后待放款' THEN tt.未收金额 END) AS 逾期公积金预告预抵押后待放款,
	SUM(CASE WHEN tt.是否逾期='否' THEN tt.未收金额 END) AS 未到期待回款,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.款项类型='首期' THEN tt.未收金额 END) AS 未到期首付分期,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.款项类型='非贷款类房款' THEN tt.未收金额 END) AS 未到期全款,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.款项类型='贷款类房款' THEN tt.未收金额 END) AS 未到期按揭,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' THEN tt.未收金额 END) AS 未到期商贷,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='网签资料不齐' THEN tt.未收金额 END) AS 未到期商贷网签资料不齐,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='揭资料不齐' THEN tt.未收金额 END) AS 未到期商贷按揭资料不齐,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='按揭资料待送审' THEN tt.未收金额 END) AS 未到期商贷按揭资料待送审,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='按揭资料待送审' THEN tt.未收金额 END) AS 未到期商贷审核中,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='拒贷' THEN tt.未收金额 END) AS 未到期商贷拒贷,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='审核通过预告预抵押' THEN tt.未收金额 END) AS 未到期商贷审核通过预告预抵押,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='商贷' AND tt.商贷未回款原因='预告预抵押后待放款' THEN tt.未收金额 END) AS 未到期商贷预告预抵押后待放款,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' THEN tt.未收金额 END) AS 未到期公积金,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='网签资料不齐' THEN tt.未收金额 END) AS 未到期公积金网签资料不齐,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='按揭资料不齐' THEN tt.未收金额 END) AS 未到期公积金按揭资料不齐,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='按揭资料待送审' THEN tt.未收金额 END) AS 未到期公积金按揭资料待送审,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='审核中' THEN tt.未收金额 END) AS 未到期公积金审核中,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='拒贷' THEN tt.未收金额 END) AS 未到期公积金拒贷,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='审核通过预告预抵押' THEN tt.未收金额 END) AS 未到期公积金审核通过预告预抵押,
	SUM(CASE WHEN tt.是否逾期='否' AND tt.贷款类型='公积金' AND tt.公积金未回款原因='预告预抵押后待放款' THEN tt.未收金额 END) AS 未到期公积金预告预抵押后待放款
FROM 未回款分析 tt
GROUP BY
	tt.项目,
	tt.项目编码,
	tt.ProjGUID,
	tt.推广项目
ORDER BY
	tt.项目编码