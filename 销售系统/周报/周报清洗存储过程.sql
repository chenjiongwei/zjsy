USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_项目销售周报]    Script Date: 2025/1/16 9:42:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- usp_s_项目销售周报 



ALTER PROC [dbo].[usp_s_项目销售周报]      
 (      
 @var_proj VARCHAR(MAX),              
 @var_enddate DATETIME      
 )                  
AS                  
BEGIN  

set  @var_enddate=convert(varchar(10),@var_enddate,120)+' 23:59:59' 

    -- 来电来访
    select tt.* into  #来访来电 from 
    (
    select 
    op.projguid,
    '本周新增' as 周期,
    sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
    sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
    from data_wide_s_Opportunity op
    where op.status<>'丢失'
    and datediff(ww,op.FirstGjDate-1,@var_enddate-1)=0
    group by 
    op.projguid
    union all
    select 
    op.projguid,
    '本月' as 周期,
    sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
    sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
    from data_wide_s_Opportunity op
    where op.status<>'丢失'
    and datediff(mm,op.FirstGjDate,@var_enddate)=0
    group by 
    op.projguid
    union all
    select 
    op.projguid,
    '本年' as 周期,
    sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
    sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
    from data_wide_s_Opportunity op
    where op.status<>'丢失'
    and datediff(yy,op.FirstGjDate,@var_enddate)=0
    group by 
    op.projguid
    union all
    select 
    op.projguid,
    '全盘' as 周期,
    sum(case when op.ZcStatus='看房' then 1 else 0 end) as 来访统计,
    sum(case when op.ZcStatus='问询' then 1 else 0 end) as 来电统计
    from data_wide_s_Opportunity op
    where op.status<>'丢失'
    group by 
    op.projguid
    ) tt

    -- 认购情况
    select tt.* into  #认购情况 from  
    (
    select 
    so.projguid,
    so.TopProductTypeName as 业态,
    '本周新增' as 周期,
    sum(1) as 认购套数,	
    -- sum(isnull(so.ocjbldarea,so.ccjbldarea)) as 认购面积,
    sum(isnull(sr.bldarea,0)) as 认购面积,
    sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
    sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
    -- sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(sr.bldarea,0) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
    from data_wide_s_trade so 
    left join data_wide_s_room sr on so.roomguid=sr.roomguid
    where (so.ostatus='激活' or so.cstatus='激活')
    and datediff(ww,so.ZcOrderDate-1,@var_enddate-1)=0
    group by 
    so.projguid,
    so.TopProductTypeName
    UNION ALL 
    select 
    so.projguid,
    so.TopProductTypeName as 业态,
    '本月' as 周期,
    sum(1) as 认购套数,	
    -- sum(isnull(so.ocjbldarea,so.ccjbldarea)) as 认购面积,
    sum(isnull(sr.bldarea,0)) as 认购面积,
    sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
    sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
    -- sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(sr.bldarea,0) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
    from data_wide_s_trade so 
    left join data_wide_s_room sr on so.roomguid=sr.roomguid
    where (so.ostatus='激活' or so.cstatus='激活')
    and datediff(mm,so.ZcOrderDate,@var_enddate)=0
    group by 
    so.projguid,
    so.TopProductTypeName
    UNION ALL 
    select 
    so.projguid,
    so.TopProductTypeName as 业态,
    '本年' as 周期,
    sum(1) as 认购套数,	
    -- sum(isnull(so.ocjbldarea,so.ccjbldarea)) as 认购面积,
    sum(isnull(sr.bldarea,0)) as 认购面积,
    sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
    sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
    -- sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(sr.bldarea,0) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
    from data_wide_s_trade so 
    left join data_wide_s_room sr on so.roomguid=sr.roomguid
    where (so.ostatus='激活' or so.cstatus='激活')
    and datediff(yy,so.ZcOrderDate,@var_enddate)=0
    group by 
    so.projguid,
    so.TopProductTypeName
    UNION ALL 
    select 
    so.projguid,
    so.TopProductTypeName as 业态,
    '全盘' as 周期,
    sum(1) as 认购套数,	
    -- sum(isnull(so.ccjbldarea,so.ocjbldarea)) as 认购面积,
    sum(isnull(sr.bldarea,0)) as 认购面积,
    sum(isnull(so.ccjtotal,so.ocjtotal)) as 认购金额,
    sum(case when so.ordertype='预选' then 1 else 0 end) as 预选套数,	
    -- sum(case when so.ordertype='预选' then isnull(so.ocjbldarea,so.ccjbldarea) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(sr.bldarea,0) else 0 end) as 预选面积,
    sum(case when so.ordertype='预选' then isnull(so.ocjtotal,so.ccjtotal) else 0 end) as 预选金额
    from data_wide_s_trade so 
    left join data_wide_s_room sr on so.roomguid=sr.roomguid
    where (so.ostatus='激活' or so.cstatus='激活')
    group by 
    so.projguid,
    so.TopProductTypeName
    ) tt

    select tt.* into  #认购退房情况 from 
    (
    select 
    tf.projguid,
    tf.TopProductTypeName as 业态,
    '本周新增' as 周期,
    sum(1) as 认购退房套数,	
    -- sum(tf.ocjbldarea) as 认购退房面积,
    sum(isnull(sr.bldarea,0)) as 认购退房面积,
    sum(tf.ocjtotal) as 认购退房金额
    from data_wide_s_trade tf 
    left join data_wide_s_room sr on tf.roomguid=sr.roomguid
    where year(tf.ZcOrderDate)=year(@var_enddate)
    and datediff(ww,tf.ocloseDate-1,@var_enddate-1)=0
    and tf.oclosereason='退房'
    group by 
    tf.projguid,
    tf.TopProductTypeName
    UNION ALL 
    select 
    tf.projguid,
    tf.TopProductTypeName as 业态,
    '本月' as 周期,
    sum(1) as 认购退房套数,	
    -- sum(tf.ocjbldarea) as 认购退房面积,
    sum(isnull(sr.bldarea,0)) as 认购退房面积,
    sum(tf.ocjtotal) as 认购退房金额
    from data_wide_s_trade tf 
    left join data_wide_s_room sr on tf.roomguid=sr.roomguid
    where year(tf.ZcOrderDate)=year(@var_enddate)
    and datediff(mm,tf.ocloseDate,@var_enddate)=0
    and tf.oclosereason='退房'
    group by 
    tf.projguid,
    tf.TopProductTypeName
    UNION ALL 
    select 
    tf.projguid,
    tf.TopProductTypeName as 业态,
    '本年' as 周期,
    sum(1) as 认购退房套数,	
    -- sum(tf.ocjbldarea) as 认购退房面积,
    sum(isnull(sr.bldarea,0)) as 认购退房面积,
    sum(tf.ocjtotal) as 认购退房金额
    from data_wide_s_trade tf 
    left join data_wide_s_room sr on tf.roomguid=sr.roomguid
    where year(tf.ZcOrderDate)=year(@var_enddate)
    and datediff(yy,tf.ocloseDate,@var_enddate)=0
    and tf.oclosereason='退房'
    group by 
    tf.projguid,
    tf.TopProductTypeName
    UNION ALL 
    select 
    tf.projguid,
    tf.TopProductTypeName as 业态,
    '全盘' as 周期,
    sum(1) as 认购退房套数,	
    --sum(tf.ocjbldarea) as 认购退房面积,
    sum(isnull(sr.bldarea,0)) as 认购退房面积,
    sum(tf.ocjtotal) as 认购退房金额
    from data_wide_s_trade tf 
    left join data_wide_s_room sr on tf.roomguid=sr.roomguid
    where year(tf.ZcOrderDate)=year(@var_enddate)
    and tf.oclosereason='退房'
    group by 
    tf.projguid,
    tf.TopProductTypeName
    ) tt
    
    -- 插入净签约情况
    SELECT tt.* INTO #签约情况 FROM 
    (
        -- 本周新增签约数据
        SELECT 
            sc.projguid,
            sc.TopProductTypeName AS 业态,
            '本周新增' AS 周期,
            SUM(1) AS 净签约套数,	
            -- 使用房间实际面积替代合同面积
            SUM(ISNULL(sr.bldarea,0)) AS 净签约面积,
            SUM(sc.ccjtotal) AS 净签约金额,
            -- 统计延期付款签约套数
            SUM(CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END) AS 延期付款净签约套数
        FROM data_wide_s_trade sc
        LEFT JOIN data_wide_s_room sr ON sc.roomguid = sr.roomguid 
        -- 关联延期付款申请表
        LEFT JOIN 
        (
            SELECT 
                yq.tradeguid
            FROM data_wide_s_SaleModiApply yq
            WHERE yq.applytype IN ('延期付款','延期付款(签约)')
                AND yq.ApplyStatus = '已执行' 
            GROUP BY 
                yq.tradeguid
        ) yq ON sc.tradeguid = yq.tradeguid
        WHERE sc.cstatus = '激活'  AND DATEDIFF(ww,sr.x_YeJiTime-1,@var_enddate-1) = 0
        GROUP BY 
            sc.projguid,
            sc.TopProductTypeName

        UNION ALL 

        -- 本月签约数据
        SELECT 
            sc.projguid,
            sc.TopProductTypeName AS 业态,
            '本月' AS 周期,
            SUM(1) AS 净签约套数,	
            SUM(ISNULL(sr.bldarea,0)) AS 净签约面积,
            SUM(sc.ccjtotal) AS 净签约金额,
            SUM(CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END) AS 延期付款净签约套数
        FROM data_wide_s_trade sc
        LEFT JOIN data_wide_s_room sr ON sc.roomguid = sr.roomguid 
        LEFT JOIN 
        (
            SELECT 
                yq.tradeguid
            FROM data_wide_s_SaleModiApply yq
            WHERE yq.applytype IN ('延期付款','延期付款(签约)')
                AND yq.ApplyStatus = '已执行'
            GROUP BY 
                yq.tradeguid
        ) yq ON sc.tradeguid = yq.tradeguid
        WHERE sc.cstatus = '激活' AND DATEDIFF(mm,sr.x_YeJiTime,@var_enddate) = 0
        GROUP BY 
            sc.projguid,
            sc.TopProductTypeName

        UNION ALL 

        -- 本年签约数据
        SELECT 
            sc.projguid,
            sc.TopProductTypeName AS 业态,
            '本年' AS 周期,
            SUM(1) AS 净签约套数,	
            SUM(ISNULL(sr.bldarea,0)) AS 净签约面积,
            SUM(sc.ccjtotal) AS 净签约金额,
            SUM(CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END) AS 延期付款净签约套数
        FROM data_wide_s_trade sc
        LEFT JOIN data_wide_s_room sr ON sc.roomguid = sr.roomguid 
        LEFT JOIN 
        (
            SELECT 
                yq.tradeguid
            FROM data_wide_s_SaleModiApply yq
            WHERE yq.applytype IN ('延期付款','延期付款(签约)')
                AND yq.ApplyStatus = '已执行'
            GROUP BY 
                yq.tradeguid
        ) yq ON sc.tradeguid = yq.tradeguid
        WHERE sc.cstatus = '激活' AND DATEDIFF(yy,sr.x_YeJiTime,@var_enddate) = 0
        GROUP BY 
            sc.projguid,
            sc.TopProductTypeName

        UNION ALL 

        -- 全盘签约数据
        SELECT 
            sc.projguid,
            sc.TopProductTypeName AS 业态,
            '全盘' AS 周期,
            SUM(1) AS 净签约套数,	
            SUM(ISNULL(sr.bldarea,0)) AS 净签约面积,
            SUM(sc.ccjtotal) AS 净签约金额,
            SUM(CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END) AS 延期付款净签约套数
        FROM data_wide_s_trade sc
        LEFT JOIN data_wide_s_room sr ON sc.roomguid = sr.roomguid 
        LEFT JOIN 
        (
            SELECT 
                yq.tradeguid
            FROM data_wide_s_SaleModiApply yq
            WHERE yq.applytype IN ('延期付款','延期付款(签约)')
                AND yq.ApplyStatus = '已执行'
            GROUP BY 
                yq.tradeguid
        ) yq ON sc.tradeguid = yq.tradeguid
        WHERE sc.cstatus = '激活' AND sr.x_YeJiTime IS NOT NULL
        GROUP BY 
            sc.projguid,
            sc.TopProductTypeName
    ) tt

    select tt.* into  #签约重售情况 from 
    (
    select 
    sc.projguid,
    sc.TopProductTypeName as 业态,
    '本周新增' as 周期,
    sum(1) as 签约重售套数,	
    -- sum(sc.ccjbldarea) as 签约重售面积,
    sum(isnull(sr.bldarea,0)) as 签约重售面积,
    sum(sc.ccjtotal) as 签约重售金额
    from data_wide_s_trade sc
    left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
    where sc.cstatus='激活'
    and year(sr.x_YeJiTime)<year(@var_enddate)
    and datediff(ww,isnull(sc.x_InitialledDate,sc.CNetQsDate)-1,@var_enddate-1)=0
    group by 
    sc.projguid,
    sc.TopProductTypeName
    UNION ALL 
    select 
    sc.projguid,
    sc.TopProductTypeName as 业态,
    '本月' as 周期,
    sum(1) as 签约重售套数,	
    -- sum(sc.ccjbldarea) as 签约重售面积,
    sum(isnull(sr.bldarea,0)) as 签约重售面积,
    sum(sc.ccjtotal) as 签约重售金额
    from data_wide_s_trade sc
    left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
    where sc.cstatus='激活'
    and year(sr.x_YeJiTime)<year(@var_enddate)
    and datediff(mm,isnull(sc.x_InitialledDate,sc.CNetQsDate),@var_enddate)=0
    group by 
    sc.projguid,
    sc.TopProductTypeName
    UNION ALL 
    select 
    sc.projguid,
    sc.TopProductTypeName as 业态,
    '本年' as 周期,
    sum(1) as 签约重售套数,	
    -- sum(sc.ccjbldarea) as 签约重售面积,
    sum(isnull(sr.bldarea,0)) as 签约重售面积,
    sum(sc.ccjtotal) as 签约重售金额
    from data_wide_s_trade sc
    left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
    where sc.cstatus='激活'
    and year(sr.x_YeJiTime)<year(@var_enddate)
    and datediff(yy,isnull(sc.x_InitialledDate,sc.CNetQsDate),@var_enddate)=0
    group by 
    sc.projguid,
    sc.TopProductTypeName
    UNION ALL 
    select 
    sc.projguid,
    sc.TopProductTypeName as 业态,
    '全盘' as 周期,
    sum(1) as 签约重售套数,	
    -- sum(sc.ccjbldarea) as 签约重售面积,
    sum(isnull(sr.bldarea,0)) as 签约重售面积,
    sum(sc.ccjtotal) as 签约重售金额
    from data_wide_s_trade sc
    left join data_wide_s_room sr on sc.roomguid=sr.roomguid 
    where sc.cstatus='激活'
    and year(sr.x_YeJiTime)<year(@var_enddate)
    and year(isnull(sc.x_InitialledDate,sc.CNetQsDate))>=year(@var_enddate)
    group by 
    sc.projguid,
    sc.TopProductTypeName
    ) tt

    -- 将实收情况数据存入临时表
    SELECT tt.* INTO #实收情况 FROM 
    (
        -- 本周新增实收情况
        SELECT 
            st.projguid,
            st.TopProductTypeName AS 业态,
            '本周新增' AS 周期,
            SUM(CASE WHEN  YEAR(isnull(st.CNetQsDate,st.cqsdate))=YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 本年签约回款,
            SUM(CASE WHEN  YEAR(isnull(st.CNetQsDate,st.cqsdate))<YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 往年签约回款,
            SUM(CASE WHEN  st.cqsdate IS NULL THEN sg.rmbamount ELSE 0 END) AS 认购未签约回款
        FROM data_wide_s_getin sg 
        LEFT JOIN data_wide_s_trade st ON sg.SaleGUID=st.tradeguid AND st.IsLast = 1
        WHERE ISNULL(sg.vouchstatus,'')<>'作废'
            AND sg.itemtype IN ('贷款类房款','非贷款类房款','补充协议款')
            AND sg.VouchType NOT IN ('POS机单','划拨单','放款单')
            AND DATEDIFF(ww,sg.cwskdate-1,@var_enddate-1)=0
        GROUP BY 
            st.projguid,
            st.TopProductTypeName

        UNION ALL 

        -- 本月实收情况
        SELECT 
            st.projguid,
            st.TopProductTypeName AS 业态,
            '本月' AS 周期,
            SUM(CASE WHEN  YEAR(isnull(st.CNetQsDate,st.cqsdate))=YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 本年签约回款,
            SUM(CASE WHEN  YEAR(isnull(st.CNetQsDate,st.cqsdate))<YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 往年签约回款,
            SUM(CASE WHEN  st.cqsdate IS NULL THEN sg.rmbamount ELSE 0 END) AS 认购未签约回款
        FROM data_wide_s_getin sg 
        LEFT JOIN data_wide_s_trade st ON sg.SaleGUID=st.tradeguid AND st.IsLast = 1
        WHERE ISNULL(sg.vouchstatus,'')<>'作废'
            AND sg.itemtype IN ('贷款类房款','非贷款类房款','补充协议款')
            AND sg.VouchType NOT IN ('POS机单','划拨单','放款单')
            AND DATEDIFF(mm,sg.cwskdate,@var_enddate)=0
        GROUP BY 
            st.projguid,
            st.TopProductTypeName

        UNION ALL 

        -- 本年实收情况
        SELECT 
            st.projguid,
            st.TopProductTypeName AS 业态,
            '本年' AS 周期,
            SUM(CASE WHEN  YEAR(isnull(st.CNetQsDate,st.cqsdate))=YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 本年签约回款,
            SUM(CASE WHEN  YEAR(isnull(st.CNetQsDate,st.cqsdate))<YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 往年签约回款,
            SUM(CASE WHEN  st.cqsdate IS NULL THEN sg.rmbamount ELSE 0 END) AS 认购未签约回款
        FROM data_wide_s_getin sg 
        INNER JOIN data_wide_s_trade st ON sg.SaleGUID=st.tradeguid AND st.IsLast = 1
        WHERE ISNULL(sg.vouchstatus,'')<>'作废'
            AND sg.itemtype IN ('贷款类房款','非贷款类房款','补充协议款')
            AND sg.VouchType NOT IN ('POS机单','划拨单','放款单')
            AND DATEDIFF(yy,sg.cwskdate,@var_enddate)=0
        GROUP BY 
            st.projguid,
            st.TopProductTypeName

        UNION ALL 

        -- 全盘实收情况
        SELECT 
            st.projguid,
            st.TopProductTypeName AS 业态,
            '全盘' AS 周期,
            SUM(CASE WHEN YEAR(isnull(st.CNetQsDate,st.cqsdate))=YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 本年签约回款,
            SUM(CASE WHEN YEAR(isnull(st.CNetQsDate,st.cqsdate))<YEAR(@var_enddate) THEN sg.rmbamount ELSE 0 END) AS 往年签约回款,
            SUM(CASE WHEN  st.cqsdate IS NULL THEN sg.rmbamount ELSE 0 END) AS 认购未签约回款
        FROM data_wide_s_getin sg 
        INNER JOIN data_wide_s_trade st ON sg.SaleGUID=st.tradeguid AND st.IsLast = 1
        WHERE ISNULL(sg.vouchstatus,'')<>'作废'
            AND sg.itemtype IN ('贷款类房款','非贷款类房款','补充协议款')
            AND sg.VouchType NOT IN ('POS机单','划拨单','放款单')
        GROUP BY 
            st.projguid,
            st.TopProductTypeName
    ) tt

    -- 查询最终结果
    SELECT
        zt.projguid,
        zt.业态,
        zq.排序,
        zq.周期,
        lf.来访统计,
        lf.来电统计,
        so.认购套数,	
        so.认购面积,
        so.认购金额,
        so.预选套数,	
        so.预选面积,
        so.预选金额,
        tf.认购退房套数,	
        tf.认购退房面积,
        tf.认购退房金额,
        sc.净签约套数,	
        sc.净签约面积,
        sc.净签约金额,
        sc.延期付款净签约套数,
        cs.签约重售套数,	
        cs.签约重售面积,
        cs.签约重售金额,
        sg.本年签约回款,
        sg.往年签约回款,
        sg.认购未签约回款
    FROM 
    (
        SELECT 
            fq.p_projectId AS ProjGUID,
            ISNULL(sr.TopProductTypeName,'住宅') AS 业态
        FROM data_wide_mdm_Project fq 
        LEFT JOIN data_wide_s_room sr ON fq.p_projectId = sr.ProjGUID
        WHERE (fq.p_projectId IN (SELECT AllItem FROM fn_split_new(@var_proj,',')) 
            OR @var_proj = '00000000-0000-0000-0000-000000000000')
        GROUP BY 
            fq.p_projectId,
            ISNULL(sr.TopProductTypeName,'住宅')
    ) zt
    LEFT JOIN (
        SELECT '1' AS 排序,'本周新增' AS 周期 
        UNION SELECT '2','本月' 
        UNION SELECT '3','本年' 
        UNION SELECT '4','全盘'
    ) zq ON 1=1
    LEFT JOIN #来访来电 lf ON zt.projguid = lf.projguid AND zq.周期 = lf.周期
    LEFT JOIN #认购情况 so ON zt.projguid = so.projguid AND zt.业态 = so.业态 AND zq.周期 = so.周期
    LEFT JOIN #认购退房情况 tf ON zt.projguid = tf.projguid AND zt.业态 = tf.业态 AND zq.周期 = tf.周期
    LEFT JOIN #签约情况 sc ON zt.projguid = sc.projguid AND zt.业态 = sc.业态 AND zq.周期 = sc.周期
    LEFT JOIN #签约重售情况 cs ON zt.projguid = cs.projguid AND zt.业态 = cs.业态 AND zq.周期 = cs.周期
    LEFT JOIN #实收情况 sg ON zt.projguid = sg.projguid AND zt.业态 = sg.业态 AND zq.周期 = sg.周期

    DROP TABLE #来访来电, #认购情况, #认购退房情况, #签约情况, #签约重售情况, #实收情况

END
