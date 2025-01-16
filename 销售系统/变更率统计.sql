-- 创建临时表存储项目信息
SELECT SpreadName,
       ProjName,
       p_projectId
INTO #proj
FROM dbo.data_wide_mdm_Project
WHERE SpreadName IN ('东方明珠', '广梅珠江花城', '广州珠江花城', '海珠里', 
                    '花城云著', '嘉悦湾', '时光荟', '天河壹品', '天悦海湾', 
                    '御东雅苑', '云湖花城', '云悦花语', '长沙好世界', 
                    '长沙珠江花城', '中侨中心', '珠江·花屿花城', '珠江广钢花城', 
                    '珠江嘉园', '珠江郦城', '珠江四方印', '珠江颐德公馆', 
                    '珠实·西关都荟')
      AND Level = 2
UNION
SELECT SpreadName,
       ProjName,
       p_projectId
FROM dbo.data_wide_mdm_Project
WHERE ProjName IN ('御东雅苑', '中侨中心', '珠江嘉园') 
      AND Level = 2

-- 设置截止日期参数
DECLARE @qxDate DATETIME = '2024-12-31'

-- 统计汇总查询：按项目统计销售合同总套数和延期付款变更次数
SELECT r.BUName, 
       r.ParentProjName,
       p.SpreadName, 
       r.ParentProjGUID AS ProjGUID,
       -- 当年销售合同总套数
       SUM(CASE WHEN DATEDIFF(YEAR, r.x_YeJiTime, @qxDate) = 0 THEN 1 ELSE 0 END) AS 当年销售合同总套数,
       -- 当年签约延期付款变更次数
       SUM(CASE WHEN DATEDIFF(YEAR, r.x_YeJiTime, @qxDate) = 0 
                AND sma.ApplyGUID IS NOT NULL THEN 1 ELSE 0 END) AS 当年签约延期付款变更次数
FROM data_wide_s_Room r WITH(NOLOCK)
    INNER JOIN data_wide_s_Trade tr WITH(NOLOCK) 
        ON tr.RoomGUID = r.RoomGUID 
        AND tr.TradeStatus = '激活' 
        AND tr.IsLast = 1 
    INNER JOIN #proj p 
        ON p.p_projectId = r.ParentProjGUID
    OUTER APPLY (
        -- 获取最新的延期付款申请记录
        SELECT TOP 1 sm.ApplyGUID 
        FROM data_wide_s_SaleModiApply sm WITH(NOLOCK) 
        WHERE sm.ApplyStatus = '已执行' 
          AND sm.ApplyType IN ('延期付款', '延期付款(签约)')
          AND sm.RoomGUID = r.RoomGUID
          AND sm.TradeGUID = tr.TradeGUID
        ORDER BY sm.ApplyDate DESC
    ) sma
WHERE r.Status IN ('签约')
GROUP BY r.BUName, r.ParentProjName, p.SpreadName, r.ParentProjGUID

-- 查询明细：获取具体房间的延期付款变更记录
SELECT r.BUName, 
       r.ParentProjName,
       r.RoomGUID,
       r.roominfo,
       r.x_YeJiTime,
       sma.ApplyGUID,
       sma.ApplyDate,
       sma.ApplyType,
       sma.ApplyStatus
FROM data_wide_s_Room r WITH(NOLOCK)
    INNER JOIN data_wide_s_Trade tr WITH(NOLOCK) 
        ON tr.RoomGUID = r.RoomGUID 
        AND tr.TradeStatus = '激活' 
        AND tr.IsLast = 1 
    --INNER JOIN #proj p  ON p.p_projectId = r.ParentProjGUID
    OUTER APPLY (
        -- 获取最新的延期付款申请详细信息
        SELECT TOP 1 sm.ApplyGUID,
                    sm.ApplyDate,
                    sm.ApplyType,
                    sm.ApplyStatus
        FROM data_wide_s_SaleModiApply sm WITH(NOLOCK) 
        WHERE sm.ApplyStatus = '已执行' 
          AND sm.ApplyType IN ('延期付款', '延期付款(签约)')
          AND sm.RoomGUID = r.RoomGUID
          AND sm.TradeGUID = tr.TradeGUID
        ORDER BY sm.ApplyDate DESC
    ) sma
WHERE r.Status IN ('签约') 
     AND DATEDIFF(YEAR, r.x_YeJiTime, @qxDate) = 0
     AND  r.ParentProjGUID IN (@projguid)



--ZSDC-01-考核指标完成情况-延期付款变更率明细
IF @版本号 = '实时' 
BEGIN
    -- 查询明细：获取具体房间的延期付款变更记录
    SELECT r.BUName,
           r.BUGUID,
           r.ParentProjGUID,
           r.ParentProjName,
           r.RoomGUID,
           r.roominfo,
           r.x_YeJiTime,
           sma.ApplyGUID,
           sma.ApplyDate,
           sma.ApplyType,
           sma.ApplyStatus
    FROM data_wide_s_Room r WITH(NOLOCK)
        INNER JOIN data_wide_s_Trade tr WITH(NOLOCK) 
            ON tr.RoomGUID = r.RoomGUID 
            AND tr.TradeStatus = '激活' 
            AND tr.IsLast = 1 
        --INNER JOIN #proj p ON p.p_projectId = r.ParentProjGUID
        OUTER APPLY (
            -- 获取最新的延期付款申请详细信息
            SELECT TOP 1 sm.ApplyGUID,
                        sm.ApplyDate,
                        sm.ApplyType,
                        sm.ApplyStatus
            FROM data_wide_s_SaleModiApply sm WITH(NOLOCK) 
            WHERE sm.ApplyStatus = '已执行' 
                AND sm.ApplyType IN ('延期付款', '延期付款(签约)')
                AND sm.RoomGUID = r.RoomGUID
                AND sm.TradeGUID = tr.TradeGUID
            ORDER BY sm.ApplyDate DESC
        ) sma
    WHERE r.Status IN ('签约') 
        AND DATEDIFF(YEAR, r.x_YeJiTime, getdate()) = 0
        AND r.ParentProjGUID IN (@projguid)
        AND r.BUGUID IN (@buguid)
END 
ELSE
BEGIN
    SELECT snapshot_time,
           version,
           BUName,
           BUGUID,
           ParentProjGUID,
           ParentProjName,
           RoomGUID,
           roominfo,
           x_YeJiTime,
           ApplyGUID,
           ApplyDate,
           ApplyType,
           ApplyStatus
    FROM dbo.Result_YearYqfkSaleModiApply
    WHERE [version] = @版本号
        AND BUGUID IN (@buguid)
        AND ParentProjGUID IN (@Projguid)
END

    -- IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Result_YearYqfkSaleModiApply]') AND type in (N'U'))
    -- BEGIN
    --     CREATE TABLE [dbo].[Result_YearYqfkSaleModiApply](
    --         [snapshot_time] datetime NOT NULL,
    --         [version] nvarchar(50) NOT NULL,
    --         [BUName] nvarchar(100) NULL,
    --         [BUGUID] uniqueidentifier NULL,
    --         [ParentProjGUID] uniqueidentifier NULL,
    --         [ParentProjName] nvarchar(100) NULL, 
    --         [RoomGUID] uniqueidentifier NULL,
    --         [roominfo] nvarchar(100) NULL,
    --         [x_YeJiTime] datetime NULL,
    --         [ApplyGUID] uniqueidentifier NULL,
    --         [ApplyDate] datetime NULL,
    --         [ApplyType] nvarchar(50) NULL,
    --         [ApplyStatus] nvarchar(50) NULL,
    --         CONSTRAINT [PK_Result_YearYqfkSaleModiApply] PRIMARY KEY CLUSTERED 
    --         (
    --             [snapshot_time] ASC,
    --             [version] ASC
    --         )
    --     )
    -- END