 --新增《采购过程履约评价情况统计表》，输出 经办人，采购过程名称、项目名称、定标完成时间、履约评价阶段，完成本阶段时间。

SELECT   
       a.BUGUID,
       ProjectNameList AS 项目名称,
       Manager AS 经办人,
       SolutionName AS 采购过程名称,
       WinBidProviderGUIDlist,
       nd.RealEndDate 定标完成时间,
       pft.PgName AS 履约评估名称,
       pft.StageName AS 履约评价阶段,
       pft.RealEndDate 完成本阶段时间
FROM data_wide_cg_CgSolution a
    INNER JOIN
    (
        SELECT SolutionGUID,
               SolutionStepName,
               PlanEndDate,
               RealEndDate
        FROM data_wide_cg_CgSolutionNode
        WHERE SolutionStepName = '定标'
              AND RealEndDate IS NOT NULL
    ) nd
        ON a.CgSolutionGUID = nd.SolutionGUID
    OUTER APPLY
(
    SELECT TOP 1
           pf.PgName,
           pf.ProviderGUID,
           pf.StageName,
           pf.RealEndDate
    FROM data_wide_cg_PgPerformTacticAgr pf
    WHERE CHARINDEX(CONVERT(VARCHAR(36), pf.ProviderGUID), a.WinBidProviderGUIDlist) >= 1
    ORDER BY RealEndDate DESC
) pft
WHERE 1 = 1 AND  WinBidProviderGUIDlist IS NOT NULL  AND  a.BUGUID IN (@var_buguid)

/*
-- 宽表中增加中标供应商GUID列表
SELECT 
    CgSolutionGUID,
    ProviderGUIDlist,-- 中标供应商GUID列表
    COUNT(DISTINCT([ProviderRecordGUID])) AS [WinBidProviderCount],  -- 中标供应商数量
    SUM(ISNULL([WinBidPrice], 0)) AS [WinBidAmount]
FROM (
    SELECT  
        CgSolutionGUID,
        ProviderRecordGUID,
        WinBidPrice,
        IsWinBid,
        (SELECT STUFF(
            (SELECT DISTINCT ',' + CONVERT(VARCHAR(50), a.ProviderGUID)
            FROM cg_CgProcReturnBidProvider a 
            WHERE a.CgSolutionGUID = prbp.CgSolutionGUID 
                AND a.[IsWinBid] = 1
            FOR XML PATH('')),
            1, 1, ''
        )) AS ProviderGUIDlist
    FROM [dbo].[cg_CgProcReturnBidProvider] prbp
) AS ProcReturnBidProvider 
WHERE [IsWinBid] = 1
GROUP BY CgSolutionGUID,ProviderGUIDlist
*/

INSERT INTO rp_release_result_12267_11600_temp (
    buquid,
    本日认购套数新,
    本日认购面积新,
    本日认购金额新,
    本日签约套数,
    本日签约面积,
    本日签约金额,
    本月认购金额,
    本月实际签约金额,
    本年认购面积,
    本年认购金额,
    全口径本年签约金额,
    累计未签金额,
    月度任务完成率,
    年度目标完成率,
    披露口径本年签约金额,
    逾期未签金额,
    rp_buname,
    rp_type,
    rp_parentguid,
    rp_levelcode
) VALUES (
    '11b11db4-e907-4f1f-8835-b9daab6e1f23',
    408,
    3.6873,
    7.0238,
    519,
    4.8134,
    9.8935,
    198.7007,
    149.4766,
    1568.1113,
    2866.3896,
    2802.5736,
    97.4701,
    56,
    76,
    2989.4766,
    23.31,
    '保利发展集团',
    1,
    'zb',
    NULL,
    NULL
)