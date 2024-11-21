-- 判断是否首开
SELECT ISNULL(p1.projguid, p.projguid) projguid,
       MIN(o.qsdate) stdate 
INTO #sk
FROM s_order o
     LEFT JOIN p_project p ON o.projguid = p.projguid
     LEFT JOIN p_project p1 ON p.parentcode = p1.projcode
                               AND p1.applysys LIKE '%0101%'
WHERE o.status = '激活'
      OR o.closereason = '转签约'
GROUP BY ISNULL(p1.projguid, p.projguid);

-- 获取项目业绩区分信息
SELECT DISTINCT
       f.projguid,
       f.是否录入合作业绩,
       f.是否本月首开,
       f.推广名,
       y.stdate,
       CASE
           WHEN f.存量增量 = '新增量' AND f.是否本月首开 = '是' THEN '①新增量首开'
           WHEN f.存量增量 = '新增量' AND f.是否本月首开 <> '是' THEN '②新增量续销'
           WHEN f.存量增量 = '增量' THEN '③增量续销'
           WHEN f.存量增量 = '存量' AND f.projguid <> '7125EDA8-FCC1-E711-80BA-E61F13C57837' THEN '④存量续销'
           ELSE '⑤上海世博'
       END 业绩区分
INTO #re1
FROM vmdm_projectflag f
     LEFT JOIN #sk y ON f.projguid = y.projguid;


SELECT a.projguid,
       a.产品类型,
       b.qxdate,
       SUM(ISNULL(b.本月认购金额, 0)) AS 本月认购金额
INTO #brrg
FROM (
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 1
) a
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          --AND DATEDIFF(dd, b.qxdate, GETDATE()) = 0
GROUP BY a.projguid,
         a.产品类型,
         b.qxdate

--判断如果qxdate日期是本月1日，就直接取本月认购金额为本日认购金额
SELECT projguid,
       产品类型,
       qxdate,
       本月认购金额 AS 今日本月认购金额,
       LAG(本月认购金额) OVER(PARTITION BY projguid, 产品类型 ORDER BY qxdate) 昨日本月认购金额,
       CASE 
           WHEN DAY(qxdate) = 1 THEN ISNULL(本月认购金额, 0)
           ELSE ISNULL(本月认购金额, 0) - ISNULL(LAG(本月认购金额) OVER(PARTITION BY projguid, 产品类型 ORDER BY qxdate), 0)
       END AS 本日认购金额
FROM #brrg


-- 获取成交数据
SELECT a.projguid,
       sk.stdate skdate,
       SUM(CASE
           WHEN DAY(GETDATE()) = 1 THEN ISNULL(b.本月认购金额, 0)
           ELSE ISNULL(b.本月认购金额, 0) - ISNULL(c.本月认购金额, 0)
       END) 本日认购金额
INTO #yj
FROM (
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0
    UNION
    SELECT projguid,
           产品类型,
           首推日期
    FROM S_08ZYXSQYJB_HHZTSYJ_daily
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 1
) a
LEFT JOIN #sk sk ON a.projguid = sk.projguid
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily b ON a.projguid = b.projguid
                                          AND a.产品类型 = b.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(b.首推日期, '')
                                          AND DATEDIFF(dd, b.qxdate, GETDATE()) = 0
LEFT JOIN S_08ZYXSQYJB_HHZTSYJ_daily c ON a.projguid = c.projguid
                                          AND a.产品类型 = c.产品类型
                                          AND ISNULL(a.首推日期, '') = ISNULL(c.首推日期, '')
                                          AND DATEDIFF(dd, c.qxdate, GETDATE()) = 1
GROUP BY a.projguid,
         sk.stdate;

-- 计算业绩结果
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(本日认购金额) / 10000 本日认购金额,
       SUM(CASE
           WHEN r.是否录入合作业绩 = '是' THEN 本日认购金额
           ELSE 0
       END) / 10000 合作业绩,
       SUM(CASE
           WHEN r.业绩区分 LIKE '%续销%' THEN 本日认购金额
           ELSE 0
       END) / 10000 续销业绩
INTO #yjresult
FROM #yj y
     LEFT JOIN #re1 r ON y.projguid = r.projguid;

-- 获取本日来访数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)) lf
INTO #lf
FROM s_YHJVisitNum l
     LEFT JOIN #re1 r ON l.managementProjectGuid = r.projguid
WHERE DATEDIFF(dd, bizdate, GETDATE()) = 0
      AND r.业绩区分 LIKE '%续销%';

-- 获取上周来访数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(CASE 
           WHEN DATEPART(WEEKDAY, bizdate) BETWEEN 2 AND 6 
           THEN ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)
           ELSE 0 
       END) / 5 lfsz,
       SUM(CASE
           WHEN DATEPART(WEEKDAY, bizdate) IN (1,7)
           THEN ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)
           ELSE 0
       END) /5 lfsz_weekend
INTO #lfsz
FROM s_YHJVisitNum l
     LEFT JOIN #re1 r ON l.managementProjectGuid = r.projguid
WHERE bizdate BETWEEN DATEADD(WEEK, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)) 
                  AND DATEADD(DAY, 6, DATEADD(WEEK, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)))
      AND r.业绩区分 LIKE '%续销%';

-- 获取上上周来访数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(CASE 
           WHEN DATEPART(WEEKDAY, bizdate) BETWEEN 2 AND 6 
           THEN ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)
           ELSE 0 
       END) / 5 lfssz,
       SUM(CASE
           WHEN DATEPART(WEEKDAY, bizdate) IN (1,7)
           THEN ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)
           ELSE 0
       END) / 5  lfssz_weekend
INTO #lfssz
FROM s_YHJVisitNum l
     LEFT JOIN #re1 r ON l.managementProjectGuid = r.projguid
WHERE 
   bizdate BETWEEN DATEADD(WEEK, -2, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))
                  AND DATEADD(DAY, 6, DATEADD(WEEK, -2, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)))
      AND r.业绩区分 LIKE '%续销%'

/*
-- 获取三季度来访数据
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       SUM(CASE 
           WHEN DATEPART(WEEKDAY, bizdate) BETWEEN 2 AND 6 
           THEN ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)
           ELSE 0 
       END) Q3lfsvisitNum,
       SUM(CASE
           WHEN DATEPART(WEEKDAY, bizdate) IN (1,7)
           THEN ISNULL(newVisitNum, 0) + ISNULL(oldVisitNum, 0)
           ELSE 0
       END) Q3lfsvisitNum_weekend
INTO #Q3lfs
FROM s_YHJVisitNum l
     LEFT JOIN #re1 r ON l.managementProjectGuid = r.projguid
WHERE 
   bizdate BETWEEN DATEFROMPARTS(YEAR(GETDATE()), 7, 1) -- Q3 start
                  AND DATEFROMPARTS(YEAR(GETDATE()), 9, 30) -- Q3 end
      AND r.业绩区分 LIKE '%续销%' */


-- 计算上周业绩
SELECT a.buguid,
       (a.本年签约金额 - b.本年签约金额) / 50000 本周金额
INTO #szyj
FROM (
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本年签约金额) 本年签约金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily y
         LEFT JOIN #re1 r ON y.projguid = r.projguid
    WHERE DATEDIFF(dd, y.qxdate, DATEADD(DAY, 4, DATEADD(WEEK, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0)))) = 0
          AND r.业绩区分 LIKE '%续销%'
) a
LEFT JOIN (
    SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
           SUM(本年签约金额) 本年签约金额
    FROM S_08ZYXSQYJB_HHZTSYJ_daily y
         LEFT JOIN #re1 r ON y.projguid = r.projguid
    WHERE DATEDIFF(dd, y.qxdate, DATEADD(WEEK, -1, DATEADD(WEEK, DATEDIFF(WEEK, 0, GETDATE()), 0))) = 1
          AND r.业绩区分 LIKE '%续销%'
) b ON a.buguid = b.buguid;





-- 获取首开项目信息
SELECT '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' buguid,
       projguid,
       推广名,
       是否录入合作业绩,
       CASE
           WHEN stdate IS NOT NULL THEN '已开'
           ELSE '未开'
       END 状态
INTO #skxx
FROM #re1
WHERE 是否本月首开 = '是';

-- 拼接首开项目字符串
SELECT t1.buguid,
       jkr = STUFF((
           SELECT ',' + 推广名 + '(' + 状态 + ')'
           FROM #skxx t
           WHERE buguid = t1.buguid
           FOR XML PATH('')
       ), 1, 1, '')
INTO #skxm
FROM #skxx t1
     LEFT JOIN #skxx fk ON t1.buguid = fk.buguid
GROUP BY t1.buguid;

-- 汇总结果

-- 判断当前日期是否为工作日
if (DATEPART(WEEKDAY, GETDATE()) BETWEEN 2 AND 6)
begin
        SELECT bu.buguid,
            ISNULL(l.lf, 0) 续销来访,
            ISNULL(ls.lfsz, 0) 上周来访,
            ISNULL(l.lf, 0) - ISNULL(ls.lfsz, 0) 差异上周,
            CONVERT(VARCHAR(10), CAST(CAST(
                CASE
                    WHEN ISNULL(ls.lfsz, 0) > 0 THEN (ISNULL(l.lf, 0) - ISNULL(ls.lfsz, 0)) * 1.00 / ISNULL(ls.lfsz, 0)
                    ELSE 0
                END AS DECIMAL(18, 2)) * 100 AS INT)) 对比上周,
            ISNULL(lss.lfssz, 0) 上上周来访,
            ISNULL(l.lf, 0) - ISNULL(lss.lfssz, 0) 差异上上周,
            CONVERT(VARCHAR(10), CAST(CAST(
                CASE
                    WHEN ISNULL(lss.lfssz, 0) > 0 THEN (ISNULL(l.lf, 0) - ISNULL(lss.lfssz, 0)) * 1.00 / ISNULL(lss.lfssz, 0)
                    ELSE 0
                END AS DECIMAL(18, 2)) * 100 AS INT)) 对比上上周,
            CAST(y.本日认购金额 AS DECIMAL(18, 2)) 本日认购金额,
            CAST(y.合作业绩 AS DECIMAL(18, 2)) 合作业绩,
            CAST(y.续销业绩 AS DECIMAL(18, 2)) 续销业绩,
            CAST(sz.本周金额 AS DECIMAL(18, 2)) 上周金额,
            CONVERT(VARCHAR(10), CAST(CAST(
                CASE
                    WHEN ISNULL(sz.本周金额, 0) > 0 THEN (ISNULL(y.本日认购金额, 0) - ISNULL(sz.本周金额, 0)) * 1.00 / ISNULL(sz.本周金额, 0)
                    ELSE 0
                END AS DECIMAL(18, 2)) * 100 AS INT)) 对比上周业绩,
            sk.jkr 首开项目
        INTO #result
        FROM mybusinessunit bu
            LEFT JOIN #lf l ON bu.buguid = l.buguid
            LEFT JOIN #lfsz ls ON bu.buguid = ls.buguid
            LEFT JOIN #lfssz lss ON bu.buguid = lss.buguid
            LEFT JOIN #yjresult y ON bu.buguid = y.buguid
            LEFT JOIN #szyj sz ON bu.buguid = sz.buguid
            LEFT JOIN #skxm sk ON bu.buguid = sk.buguid
        WHERE bu.buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23'

		-- 输出最终结果
        SELECT buguid,
        '工作日' as DayType,
        续销来访,
        CASE
            WHEN 对比上周 >= 0 THEN '提升' + 对比上周 + '%'
            ELSE '下降' + CONVERT(VARCHAR(10), ABS(对比上周)) + '%'
        END 对比上周来访,
        CASE
            WHEN 对比上上周 >= 0 THEN '提升' + 对比上上周 + '%'
            ELSE '下降' + CONVERT(VARCHAR(10), ABS(对比上上周)) + '%'
        END 对比上上周来访,
        本日认购金额,
        合作业绩,
        续销业绩,
        CASE
            WHEN 对比上周业绩 >= 0 THEN '提升' + 对比上周业绩 + '%'
            ELSE '下降' + CONVERT(VARCHAR(10), ABS(对比上周业绩)) + '%'
        END 对比上周业绩,
        首开项目
        FROM #result;
END
ELSE
--当前日期是周末
BEGIN
        SELECT bu.buguid,
            ISNULL(l.lf, 0) 续销来访,
            ISNULL(ls.lfsz_weekend, 0) 上周来访, -- 周末来访
            ISNULL(l.lf, 0) - ISNULL(ls.lfsz_weekend, 0) 差异上周,
            CONVERT(VARCHAR(10), CAST(CAST(
                CASE
                    WHEN ISNULL(ls.lfsz_weekend, 0) > 0 THEN (ISNULL(l.lf, 0) - ISNULL(ls.lfsz_weekend, 0)) * 1.00 / ISNULL(ls.lfsz_weekend, 0)
                    ELSE 0
                END AS DECIMAL(18, 2)) * 100 AS INT)) 对比上周,
            ISNULL(lss.lfssz_weekend, 0) 上上周来访,
            ISNULL(l.lf, 0) - ISNULL(lss.lfssz_weekend, 0) 差异上上周,
            CONVERT(VARCHAR(10), CAST(CAST(
                CASE
                    WHEN ISNULL(lss.lfssz_weekend, 0) > 0 THEN (ISNULL(l.lf, 0) - ISNULL(lss.lfssz_weekend, 0)) * 1.00 / ISNULL(lss.lfssz_weekend, 0)
                    ELSE 0
                END AS DECIMAL(18, 2)) * 100 AS INT)) 对比上上周,
            CAST(y.本日认购金额 AS DECIMAL(18, 2)) 本日认购金额,
            CAST(y.合作业绩 AS DECIMAL(18, 2)) 合作业绩,
            CAST(y.续销业绩 AS DECIMAL(18, 2)) 续销业绩,
            CAST(sz.本周金额 AS DECIMAL(18, 2)) 上周金额,
            CONVERT(VARCHAR(10), CAST(CAST(
                CASE
                    WHEN ISNULL(sz.本周金额, 0) > 0 THEN (ISNULL(y.本日认购金额, 0) - ISNULL(sz.本周金额, 0)) * 1.00 / ISNULL(sz.本周金额, 0)
                    ELSE 0
                END AS DECIMAL(18, 2)) * 100 AS INT)) 对比上周业绩,
            sk.jkr 首开项目
        INTO #result_weekend
        FROM mybusinessunit bu
            LEFT JOIN #lf l ON bu.buguid = l.buguid
            LEFT JOIN #lfsz ls ON bu.buguid = ls.buguid
            LEFT JOIN #lfssz lss ON bu.buguid = lss.buguid
            LEFT JOIN #yjresult y ON bu.buguid = y.buguid
            LEFT JOIN #szyj sz ON bu.buguid = sz.buguid
            LEFT JOIN #skxm sk ON bu.buguid = sk.buguid
        WHERE bu.buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23'

        -- 输出最终结果
        SELECT buguid,
            '周末' as DayType,
            续销来访,
            CASE
                WHEN 对比上周 >= 0 THEN '提升' + 对比上周 + '%'
                ELSE '下降' + CONVERT(VARCHAR(10), ABS(对比上周)) + '%'
            END 对比上周来访,
            CASE
                WHEN 对比上上周 >= 0 THEN '提升' + 对比上上周 + '%'
                ELSE '下降' + CONVERT(VARCHAR(10), ABS(对比上上周)) + '%'
            END 对比上上周来访,
            本日认购金额,
            合作业绩,
            续销业绩,
            CASE
                WHEN 对比上周业绩 >= 0 THEN '提升' + 对比上周业绩 + '%'
                ELSE '下降' + CONVERT(VARCHAR(10), ABS(对比上周业绩)) + '%'
            END 对比上周业绩,
            首开项目
        FROM #result_weekend;
END


-- 清理临时表
DROP TABLE #re1,
           #sk,
           #lf,
           #lfsz,
           #lfssz,
           #szyj,
           #yj,
           #yjresult,
     --      #result,
		   --#result_weekend,
           #skxx,
		   #Q3lfs,
           #skxm;
