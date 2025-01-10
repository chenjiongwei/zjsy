-- 06逾期待回款账龄分析
-- 2025-01-08 调整收款日期的取数口径

-- 按项目分析逾期待回款账龄情况
SELECT 
    fq.buguid,
    fq.p_projectid,
    pro.projname AS 项目名称,
    pro.SpreadName AS 推广项目名称, 
    fq.projshortname AS 分期名称,
    
    -- 网签逾期待回款金额分析
    SUM(CASE WHEN st.ContractType='网签' THEN sf.rmbye ELSE 0 END) AS 网签逾期待回款,
    -- 网签逾期7天内
    SUM(CASE WHEN st.ContractType='网签' AND DATEDIFF(dd,sf.lastdate,GETDATE())<=7 THEN sf.rmbye ELSE 0 END) AS 网签逾期7天内,
    -- 网签逾期7至30天
    SUM(CASE WHEN st.ContractType='网签' AND DATEDIFF(dd,sf.lastdate,GETDATE()) BETWEEN 8 AND 30 THEN sf.rmbye ELSE 0 END) AS 网签逾期7至30天,
    -- 网签逾期30至90天  
    SUM(CASE WHEN st.ContractType='网签' AND DATEDIFF(dd,sf.lastdate,GETDATE()) BETWEEN 31 AND 90 THEN sf.rmbye ELSE 0 END) AS 网签逾期30至90天,
    -- 网签逾期90至180天
    SUM(CASE WHEN st.ContractType='网签' AND DATEDIFF(dd,sf.lastdate,GETDATE()) BETWEEN 91 AND 180 THEN sf.rmbye ELSE 0 END) AS 网签逾期90至180天,
    -- 网签逾期180天以上
    SUM(CASE WHEN st.ContractType='网签' AND DATEDIFF(dd,sf.lastdate,GETDATE())>180 THEN sf.rmbye ELSE 0 END) AS 网签逾期180天以上,
    
    -- 草签逾期待回款金额分析
    SUM(CASE WHEN st.ContractType='草签' THEN sf.rmbye ELSE 0 END) AS 草签逾期待回款,
    -- 草签逾期7天内
    SUM(CASE WHEN st.ContractType='草签' AND DATEDIFF(dd,sf.lastdate,GETDATE())<=7 THEN sf.rmbye ELSE 0 END) AS 草签逾期7天内,
    -- 草签逾期7至30天
    SUM(CASE WHEN st.ContractType='草签' AND DATEDIFF(dd,sf.lastdate,GETDATE()) BETWEEN 8 AND 30 THEN sf.rmbye ELSE 0 END) AS 草签逾期7至30天,
    -- 草签逾期30至90天
    SUM(CASE WHEN st.ContractType='草签' AND DATEDIFF(dd,sf.lastdate,GETDATE()) BETWEEN 31 AND 90 THEN sf.rmbye ELSE 0 END) AS 草签逾期30至90天,
    -- 草签逾期90至180天
    SUM(CASE WHEN st.ContractType='草签' AND DATEDIFF(dd,sf.lastdate,GETDATE()) BETWEEN 91 AND 180 THEN sf.rmbye ELSE 0 END) AS 草签逾期90至180天,
    -- 草签逾期180天以上
    SUM(CASE WHEN st.ContractType='草签' AND DATEDIFF(dd,sf.lastdate,GETDATE())>180 THEN sf.rmbye ELSE 0 END) AS 草签逾期180天以上
FROM data_wide_s_fee sf 
-- 关联激活状态的交易信息
INNER JOIN data_wide_s_trade st 
    ON sf.tradeguid = st.tradeguid 
    AND st.cstatus = '激活'
-- 关联项目分期信息    
INNER JOIN data_wide_mdm_project fq 
    ON st.projguid = fq.p_projectid
-- 关联项目主体信息
INNER JOIN data_wide_mdm_project pro 
    ON fq.parentguid = pro.p_projectid
WHERE sf.lastdate < GETDATE() 
    AND sf.ItemType IN ('非贷款类房款','贷款类房款','补充协议款')
    AND fq.p_projectid IN (@projguid)
GROUP BY 
    fq.buguid,
    fq.p_projectid,
    pro.projname,
    pro.SpreadName,
    fq.projshortname
ORDER BY 
    pro.projname,
    pro.SpreadName,
    fq.projshortname