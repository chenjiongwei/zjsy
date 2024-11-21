--补充战略采购部分采购计划，待确认是否要挂在集团总部下，目前战略采购数据都是挂在 珠江股份  --20230815
--DECLARE @VAR_YEAR VARCHAR(4) = '2022';
--DROP TABLE #Base,#PL
SELECT 
	DISTINCT
	BUNAME,
	BU.BUGUID,
	PT.Name,
	PT.ProviderTypeGUID,
	PT.SecurityQuantity
INTO #Base 
FROM p_ProviderRecord Pr --考察记录
LEFT JOIN myBusinessUnit BU ON BU.BUGUID = Pr.BuGUID
LEFT JOIN p_ProviderType PT ON PT.ProviderTypeGUID = Pr.ProviderTypeGUID
LEFT JOIN p_provider P ON P.ProviderGUID = Pr.ProviderGUID
WHERE ISNULL(P.IsBlackList,0) <> 1
    AND P.Status = 2
    AND ((YEAR(Pr.KcDate) = @var_YEAR - 1 and convert(varchar(6),Pr.KcDate,112) >= convert(varchar(4),@var_YEAR - 1) + '12') 
    or (YEAR(Pr.KcDate) = @var_YEAR and convert(varchar(6),Pr.KcDate,112) <= convert(varchar(4),@var_YEAR) + '11'))
    AND Pr.KcGrade <> '不合格'
 --   AND BU.BUGUID ='2D08D5EA-6FF0-E311-9029-40F2E92B3FDD';

SELECT 
    a.CgPlanGUID,
    a.BUGUID,
    a.PlanStartDate,
    b.ProviderTypeGUIDList,
    a.x_IsEntrustBid 
INTO #PL 
from 
(
    /*select 
        cg_CgPlanPre.CgPlanGUID,
        --cg_CgPlanPre.BUGUID,
        CASE WHEN Manager in ('何熙平','龙小飞','徐永祯','黄志滔','周锦浩','徐挺','林浩哲','布雯雯','凌少莹')  THEN '2D08D5EA-6FF0-E311-9029-40F2E92B3FDD' ELSE cg_CgPlanPre.BUGUID END AS BUGUID,
        cg_CgPlanPre.PlanStartDate,
        ProviderTypeGUIDList = cast('<v>'+replace(cg_CgPlanPre.ProviderTypeGUIDList,',','</v><v>')+'</v>' as xml) 
    from
    cg_CgPlanPre
    */
   -- 获取采购计划和战略采购计划数据
   SELECT 
        cg_CgPlan.CgPlanGUID,
        -- 根据采购经理判断是否属于集团总部
        CASE 
            WHEN cg_CgPlan.Manager in ('何熙平','龙小飞','徐永祯','黄志滔','周锦浩','徐挺','林浩哲','布雯雯','凌少莹')  
            THEN '2D08D5EA-6FF0-E311-9029-40F2E92B3FDD' 
            ELSE cg_CgPlan.BUGUID 
        END AS BUGUID,
        cg_CgPlan.PlanStartDate,
        -- 将供应商类型列表转换为XML格式
        ProviderTypeGUIDList = cast('<v>' + replace(cg_CgPlan.ProviderTypeGUIDList,',','</v><v>') + '</v>' as xml),
        x_IsEntrustBid -- 是否珠实地产招采部采购
    FROM cg_CgPlan 
    -- 关联采购计划预审表
    INNER JOIN dbo.cg_CgPlanPre pre ON pre.CgPlanGUID = cg_CgPlan.CgPlanGUID
    -- 获取最新的采购方案
    OUTER APPLY (
        SELECT TOP 1 
            CgPlanGUID, 
            x_IsEntrustBid  
        FROM Cg_CgSolution  
        WHERE Cg_CgSolution.CgPlanGUID = cg_CgPlan.CgPlanGUID
        ORDER BY Cg_CgSolution.CreatedTime DESC 
    ) t
    WHERE pre.CgPlanState <> 5   and  isnull( t.x_IsEntrustBid,0) in ( @x_IsEntrustBid ) --去掉删掉的版本

    UNION ALL

    -- 获取战略采购计划数据
    SELECT 
        cg_TacticCgPlan.TacticCgPlanGUID,
        -- 根据采购经理判断是否属于集团总部
        CASE 
            WHEN cg_TacticCgPlan.Manager in ('何熙平','龙小飞','徐永祯','黄志滔','周锦浩','徐挺','林浩哲','布雯雯','凌少莹')  
            THEN '2D08D5EA-6FF0-E311-9029-40F2E92B3FDD' 
            ELSE cg_TacticCgPlan.BUGUID 
        END AS BUGUID,
        cg_TacticCgPlan.PlanStartDate,
        -- 将供应商类型转换为XML格式
        ProviderTypeGUIDList = cast('<v>' + replace(cg_TacticCgPlan.ProviderTypeGUID,',','</v><v>') + '</v>' as xml),
        x_IsEntrustBid -- 是否珠实地产招采部采购
    FROM cg_TacticCgPlan 
    -- 获取最新的采购方案
    OUTER APPLY (
        SELECT TOP 1 
            CgPlanGUID, 
            x_IsEntrustBid  
        FROM Cg_CgSolution 
        WHERE Cg_CgSolution.CgPlanGUID = cg_TacticCgPlan.TacticCgPlanGUID
        ORDER BY Cg_CgSolution.CreatedTime DESC 
    ) t
    where  1=1  and isnull( t.x_IsEntrustBid,0) in (@x_IsEntrustBid) --去掉删掉的版本
) a
outer apply (select ProviderTypeGUIDList = t.c.value('.','varchar(max)') from a.ProviderTypeGUIDList.nodes('/v') as t(c)) b
where b.ProviderTypeGUIDList <> ''
--AND a.BUGUID ='2D08D5EA-6FF0-E311-9029-40F2E92B3FDD';


SELECT 
	B.BUGUID
	,B.BUNAME AS 公司
	,B.ProviderTypeGUID
	,B.Name AS 供应商类别
	,ISNULL(B.SecurityQuantity,0) AS 安全储备量
	,ISNULL(Total_CNT.HG_CNT,0) AS 合格供方数量
	,ISNULL(Total_CNT.DKC_CNT,0) AS 准供方数量
	,ISNULL(B.SecurityQuantity,0) - ISNULL(Total_CNT.HG_CNT,0) AS 缺口数量
	,ISNULL(PL_YEAR.CNT,0) AS 年度合计采购计划数量
	,B.the_month AS 年月
	,ISNULL(PL_YM.CNT,0) AS 计划采购数量
	,ISNULL(sum(B_HG_YM.CNT),0) AS 截止年月合格供方数量
	,NULL AS 计划拓展数量
	,ISNULL(YM_CNT.CNT,0) AS 实际拓展数量
FROM 
(
    SELECT * FROM 
    (
        select 
            distinct the_month 
        from data_dim_date 
        where (the_year = @var_YEAR - 1 and the_month >= convert(varchar(4),@var_YEAR - 1) + '12') 
        or (the_year = @var_YEAR and the_month <= convert(varchar(4),@var_YEAR) + '11')
    ) YM
    ,#Base B
) B-- ON YM.the_month = B.the_month-- and b.BUGUID = '2D08D5EA-6FF0-E311-9029-40F2E92B3FDD' and b.ProviderTypeGUID = 'B4AACFFD-0620-4374-8C31-08DA39DA9881'
LEFT JOIN (
    SELECT 
        BU.BUGUID,
        Pr.ProviderTypeGUID,
        SUM(CASE WHEN Pr.KcGrade = '合格' THEN 1 ELSE 0 END) HG_CNT,
        SUM(CASE WHEN Pr.KcGrade = '待考察' THEN 1 ELSE 0 END) DKC_CNT 
    FROM p_ProviderRecord Pr 
    LEFT JOIN myBusinessUnit BU ON BU.BUGUID = Pr.BuGUID
    LEFT JOIN p_ProviderType PT ON PT.ProviderTypeGUID = Pr.ProviderTypeGUID
    LEFT JOIN p_provider P ON P.ProviderGUID = Pr.ProviderGUID
    WHERE ISNULL(P.IsBlackList,0) <> 1
    AND P.Status = 2
    AND Pr.KcGrade <> '不合格'
    group by BU.BUGUID,Pr.ProviderTypeGUID
) Total_CNT ON Total_CNT.BUGUID = B.BUGUID AND Total_CNT.ProviderTypeGUID = B.ProviderTypeGUID
LEFT JOIN 
(
    SELECT 
        BUGUID,
        ProviderTypeGUIDList,
        COUNT(*) CNT
    FROM #PL
    WHERE YEAR(PlanStartDate) = @var_YEAR
    GROUP BY BUGUID,ProviderTypeGUIDList
) PL_YEAR ON PL_YEAR.BUGUID = B.BUGUID AND PL_YEAR.ProviderTypeGUIDList = B.ProviderTypeGUID
LEFT JOIN 
(
    SELECT 
        BUGUID,
        ProviderTypeGUIDList,
        CONVERT(VARCHAR(6),PlanStartDate,112) PlanStartDate,
        COUNT(*) CNT
    FROM #PL
    GROUP BY BUGUID,ProviderTypeGUIDList,CONVERT(VARCHAR(6),PlanStartDate,112)
) PL_YM ON PL_YM.BUGUID = B.BUGUID AND PL_YM.ProviderTypeGUIDList = B.ProviderTypeGUID AND PL_YM.PlanStartDate = B.the_month
LEFT JOIN 
(
    SELECT 
        BU.BUGUID,
        Pr.ProviderTypeGUID,
        CONVERT(VARCHAR(6),Pr.KcDate,112) KcDate,
        COUNT(DISTINCT P.ProviderGUID) CNT 
    FROM p_ProviderRecord Pr 
    LEFT JOIN myBusinessUnit BU ON BU.BUGUID = Pr.BuGUID
    LEFT JOIN p_ProviderType PT ON PT.ProviderTypeGUID = Pr.ProviderTypeGUID
    LEFT JOIN p_provider P ON P.ProviderGUID = Pr.ProviderGUID
    WHERE ISNULL(P.IsBlackList,0) <> 1
    AND P.Status = 2
    AND Pr.KcGrade = '合格'
    group by BU.BUGUID,Pr.ProviderTypeGUID,CONVERT(VARCHAR(6),Pr.KcDate,112)
) B_HG_YM ON B_HG_YM.BUGUID = B.BUGUID AND B_HG_YM.ProviderTypeGUID = B.ProviderTypeGUID AND B_HG_YM.KcDate <= B.the_month
LEFT JOIN (SELECT BU.BUGUID,Pr.ProviderTypeGUID,CONVERT(VARCHAR(6),Pr.KcDate,112) KcDate,COUNT(DISTINCT P.ProviderGUID) CNT FROM p_ProviderRecord Pr 
LEFT JOIN myBusinessUnit BU ON BU.BUGUID = Pr.BuGUID
LEFT JOIN p_ProviderType PT ON PT.ProviderTypeGUID = Pr.ProviderTypeGUID
LEFT JOIN p_provider P ON P.ProviderGUID = Pr.ProviderGUID
WHERE ISNULL(P.IsBlackList,0) <> 1
    AND P.Status = 2
    AND Pr.KcGrade = '合格'
group by BU.BUGUID,Pr.ProviderTypeGUID,CONVERT(VARCHAR(6),Pr.KcDate,112)) YM_CNT ON YM_CNT.BUGUID = B.BUGUID AND YM_CNT.ProviderTypeGUID = B.ProviderTypeGUID AND YM_CNT.KcDate = B.the_month
--WHERE B.BUGUID IS NOT NULL AND B.ProviderTypeGUID IS NOT NULL
group by 
    B.BUGUID
	,B.BUNAME
	,B.ProviderTypeGUID
	,B.Name
	,ISNULL(B.SecurityQuantity,0)
	,ISNULL(Total_CNT.HG_CNT,0)
	,ISNULL(Total_CNT.DKC_CNT,0)
	,ISNULL(B.SecurityQuantity,0) - ISNULL(Total_CNT.HG_CNT,0)
	,ISNULL(PL_YEAR.CNT,0)
	,B.the_month
	,ISNULL(PL_YM.CNT,0)
	,ISNULL(YM_CNT.CNT,0)
order by 年月
DROP TABLE #Base,#PL;