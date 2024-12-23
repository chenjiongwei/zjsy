SELECT * FROM
(SELECT SUM(招标总额)/10000 AS 招标总额
	,SUM(核采总额)/10000 AS 核采总额
	,SUM(非平台公司)/10000 AS 非平台公司招标总额
	,iif((SUM(核采总额)+SUM(招标总额)+SUM(非平台公司))<>0,SUM(核采总额)/(SUM(核采总额)+SUM(招标总额)+SUM(非平台公司)),0) * 100 AS 核采率
	,iif((SUM(核采总额)+SUM(招标总额)+SUM(非平台公司))<>0,SUM(核采总额)/(SUM(核采总额)+SUM(招标总额)+SUM(非平台公司)),0)  AS 核采率1
FROM (
	--平台公司
	SELECT SUM(VWB.WinBidPrice) AS 招标总额  --平台公司
		,0 AS 核采总额
		, 0 as 非平台公司
	FROM Cg_CgSolution CS
	--INNER JOIN Cg_CgPlanPre CP ON CS.CgPlanGUID = CP.CgPlanGUID
	INNER JOIN vcg_CgProcWinBid VWB ON CS.CgSolutionGUID = VWB.CgSolutionGUID
		AND VWB.IsWinBid = 1 -- 中标
	INNER JOIN cg_CgProcWinBid WB ON CS.CgSolutionGUID = WB.CgSolutionGUID
	WHERE CS.CgSolutionState <> - 1 -- 非作废
		AND CS.IsTacticCg = 0 -- 非战采
		AND WB.STATUS = 2 -- 定标已审核
		-- AND Year(CASE WHEN WB.ApproveTime is not null then WB.ApproveTime when CS.realEndTime is not null then CS.realEndTime  else CS.PlanEndTime end) = YEAR(GETDATE())
		AND convert(date,(CASE WHEN WB.ApproveTime is not null then WB.ApproveTime when CS.realEndTime is not null then CS.realEndTime  else CS.PlanEndTime end),23) between @var_begindate and @var_enddate
		AND CS.x_IsEntrustBid=1 

    UNION ALL
	--非平台公司
	SELECT  0 AS 招标总额  --平台公司
		,0 AS 核采总额
		,SUM(VWB.WinBidPrice) as 非平台公司
	FROM Cg_CgSolution CS
	--INNER JOIN Cg_CgPlanPre CP ON CS.CgPlanGUID = CP.CgPlanGUID
	INNER JOIN vcg_CgProcWinBid VWB ON CS.CgSolutionGUID = VWB.CgSolutionGUID
		AND VWB.IsWinBid = 1 -- 中标
	INNER JOIN cg_CgProcWinBid WB ON CS.CgSolutionGUID = WB.CgSolutionGUID
	WHERE CS.CgSolutionState <> - 1 -- 非作废
		AND CS.IsTacticCg = 0 -- 非战采
		AND WB.STATUS = 2 -- 定标已审核
		-- AND Year(CASE WHEN WB.ApproveTime is not null then WB.ApproveTime when CS.realEndTime is not null then CS.realEndTime  else CS.PlanEndTime end) = YEAR(GETDATE())
		AND convert(date,(CASE WHEN WB.ApproveTime is not null then WB.ApproveTime when CS.realEndTime is not null then CS.realEndTime  else CS.PlanEndTime end),23) between @var_begindate and @var_enddate
		AND (CS.x_IsEntrustBid<>1 or CS.x_IsEntrustBid is null)
	
	UNION ALL
	
	SELECT 0 AS 招标总额  --平台公司
		,SUM(HJ.x_OrderAmount) AS 核采总额
		,0 as 非平台公司
	FROM x_cg_ApprovePriceTacticOrder HJ
	WHERE x_Status = 2
		-- AND Year(HJ.x_ApplyDate) = YEAR(GETDATE())
		AND convert(date,HJ.x_ApproveTime,23) between @var_begindate and @var_enddate
		
	) T
) A
LEFT JOIN (SELECT @var_begindate AS var_begindate,@var_enddate AS var_enddate) time on 1=1