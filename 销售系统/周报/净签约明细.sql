USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_项目净签约明细]    Script Date: 2025/1/16 11:59:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
功能: 根据项目和日期查询净签约明细数据
参数: 
    @var_proj - 项目GUID,多个项目用逗号分隔
    @var_enddate - 截止日期
    @var_cycle - 统计周期,可选值:本周新增/本月/本年/全盘(默认)
返回:
    - 一级项目名称
    - 分期名称 
    - 房间信息
    - 业绩认定日期
    - 业态
    - 周期
    - 净签约套数
    - 净签约面积
    - 净签约金额
    - 延期付款净签约套数
*/
--[usp_s_项目净签约明细] 'F695E9DE-89E9-E411-B4AE-40F2E92B3FDD','2024-12-31'
ALTER  PROCEDURE [dbo].[usp_s_项目净签约明细]
(
    @var_proj VARCHAR(MAX), -- 分期GUID
    @var_enddate DATETIME ,
    @var_cycle VARCHAR(10)='全盘' --周期
)
AS
BEGIN

    -- DECLARE  @var_cycle VARCHAR(10)='全盘' 
    IF @var_cycle NOT IN ('本周新增','本月','本年','全盘')
        SET @var_cycle = '全盘'

    IF @var_cycle = '本周新增'
    BEGIN
        -- 本周新增签约数据
        SELECT 
            sc.parentprojguid,
            sc.projguid,
            sc.parentprojname as 一级项目名称,
            sc.projname as 分期名称,
            sr.roomguid,
            sr.roominfo as 房间信息,
            sr.x_YeJiTime as 业绩认定日期,
            sc.TopProductTypeName AS 业态,
            '本周新增' AS 周期,
            1 AS 净签约套数,	
            -- 使用房间实际面积替代合同面积
            isnull(sr.bldarea,0) AS 净签约面积,
            isnull(sc.ccjtotal,0) AS 净签约金额,
            -- 统计延期付款签约套数
            CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END AS 延期付款净签约套数
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
        WHERE sc.cstatus = '激活'   AND DATEDIFF(ww,sr.x_YeJiTime-1,@var_enddate-1) = 0
            AND sc.parentprojguid IN (SELECT AllItem FROM fn_split_new(@var_proj,','))
    END

    ELSE IF @var_cycle = '本月'
    BEGIN
        -- 本月签约数据
        SELECT 
            sc.parentprojguid,
            sc.projguid,
            sc.parentprojname as 一级项目名称,
            sc.projname as 分期名称,
            sr.roomguid,
            sr.roominfo as 房间信息,
            sr.x_YeJiTime as 业绩认定日期,
            sc.TopProductTypeName AS 业态,
            '本月' AS 周期,
            1 AS 净签约套数,	
            -- 使用房间实际面积替代合同面积
            isnull(sr.bldarea,0) AS 净签约面积,
            isnull(sc.ccjtotal,0) AS 净签约金额,
            -- 统计延期付款签约套数
            CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END AS 延期付款净签约套数
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
        WHERE sc.cstatus = '激活' 
            AND DATEDIFF(mm,sr.x_YeJiTime,@var_enddate) = 0
            AND sc.parentprojguid IN (SELECT AllItem FROM fn_split_new(@var_proj,','))
    END

    ELSE IF @var_cycle = '本年'
    BEGIN
        -- 本年签约数据
        SELECT 
            sc.parentprojguid,
            sc.projguid,
            sc.parentprojname as 一级项目名称,
            sc.projname as 分期名称,
            sr.roomguid,
            sr.roominfo as 房间信息,
            sr.x_YeJiTime as 业绩认定日期,
            sc.TopProductTypeName AS 业态,
            '本年' AS 周期,
            1 AS 净签约套数,	
            -- 使用房间实际面积替代合同面积
            isnull(sr.bldarea,0) AS 净签约面积,
            isnull(sc.ccjtotal,0) AS 净签约金额,
            -- 统计延期付款签约套数
            CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END AS 延期付款净签约套数
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
        WHERE sc.cstatus = '激活' 
            AND DATEDIFF(yy,sr.x_YeJiTime,@var_enddate) = 0
            AND sc.parentprojguid IN (SELECT AllItem FROM fn_split_new(@var_proj,','))
    END

    ELSE -- @var_cycle = '全盘' 或其他值
    BEGIN
        -- 全盘签约数据
        SELECT 
            sc.parentprojguid,
            sc.projguid,
            sc.parentprojname as 一级项目名称,
            sc.projname as 分期名称,
            sr.roomguid,
            sr.roominfo as 房间信息,
            sr.x_YeJiTime as 业绩认定日期,
            sc.TopProductTypeName AS 业态,
            '全盘' AS 周期,
            1 AS 净签约套数,	
            -- 使用房间实际面积替代合同面积
            isnull(sr.bldarea,0) AS 净签约面积,
            isnull(sc.ccjtotal,0) AS 净签约金额,
            -- 统计延期付款签约套数
            CASE WHEN yq.tradeguid IS NOT NULL THEN 1 ELSE 0 END AS 延期付款净签约套数
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
        WHERE sc.cstatus = '激活' 
            AND sr.x_YeJiTime IS NOT NULL
            AND sc.parentprojguid IN (SELECT AllItem FROM fn_split_new(@var_proj,','))
    END

END