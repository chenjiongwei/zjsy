# 珠江实业 T-SQL 脚本模板（可复制）

> 使用方式：根据任务类型复制对应模板，替换占位符（`TODO:`）。\n+> 注意：本文件是“模板库”，`SKILL.md` 保持精炼即可。

## 1) 报表/查询脚本模板（支持 实时/快照版本号）

```sql
/*
目的: TODO
报表名称/编号: TODO
口径说明:
- @版本号='实时': 从 data_wide_* 宽表实时计算
- @版本号<>'实时': 从快照/结果表读取（version= @版本号）
参数:
- @版本号: '实时' 或 'YYYY-MM-DD' 等（与结果表 version 字段保持一致）
- @ProjGUID: TODO（可选，多值时用拆分表/临时表）
回滚: N/A（纯查询）
*/

-- TODO: 声明参数（若在报表工具里由外部注入，则保留说明即可）
-- DECLARE @版本号 nvarchar(50) = N'实时';
-- DECLARE @ProjGUID uniqueidentifier = NULL;

IF (@版本号 = N'实时')
BEGIN
    -- 实时口径：宽表计算
    SELECT
        NULL AS snapshot_time,
        N'实时' AS version,
        -- TODO: 字段列表（保持与快照表一致）
        p.p_projectId,
        p.ProjName
    FROM data_wide_mdm_Project p
    WHERE p.Level = 2
      AND (@ProjGUID IS NULL OR p.p_projectId = @ProjGUID);
END
ELSE
BEGIN
    -- 快照口径：结果表读取
    SELECT
        snapshot_time,
        version,
        p_projectId,
        项目
        -- TODO: 其他字段
    FROM dbo.result_kh_zb_snapshot
    WHERE version = @版本号
      AND (@ProjGUID IS NULL OR p_projectId = @ProjGUID);
END
```

## 2) 存储过程/作业（快照）模板（含执行日志）

```sql
USE [TODO_DB_NAME];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
存储过程功能说明: TODO（例如：定时生成报表数据快照）
写入表: TODO（列出 Result_* / *_snapshot）
日志表: dbo.SnapshotExecutionLog（若不同请替换）
回滚: TODO（若需要，说明如何删除本次 snapshot_time/version 的数据）
*/

ALTER PROCEDURE [dbo].[TODO_ProcedureName]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMessage nvarchar(4000);
    DECLARE @SnapshotTime datetime = GETDATE();
    DECLARE @VersionNo varchar(50) = CONVERT(varchar(10), @SnapshotTime, 112);
    DECLARE @ExecuteMode varchar(50) = 'AUTO';

    -- 子任务 1：TODO_SnapshotName
    BEGIN TRY
        INSERT INTO dbo.SnapshotExecutionLog (SnapshotName, ExecuteMode, StartTime, VersionNo, Status)
        VALUES (N'TODO_SnapshotName', @ExecuteMode, @SnapshotTime, @VersionNo, 'Started');

        -- TODO: 业务插入（建议显式列名）
        INSERT INTO dbo.TODO_ResultTable (snapshot_time, version /*, ...*/)
        SELECT @SnapshotTime, CONVERT(varchar(10), @SnapshotTime, 23) /*, ...*/
        FROM TODO_Source;

        UPDATE dbo.SnapshotExecutionLog
        SET EndTime = GETDATE(),
            Status = 'Completed',
            AffectedRows = @@ROWCOUNT
        WHERE SnapshotName = N'TODO_SnapshotName'
          AND StartTime = @SnapshotTime;
    END TRY
    BEGIN CATCH
        SELECT @ErrorMessage = ERROR_MESSAGE();

        UPDATE dbo.SnapshotExecutionLog
        SET EndTime = GETDATE(),
            Status = 'Failed',
            ErrorMessage = @ErrorMessage
        WHERE SnapshotName = N'TODO_SnapshotName'
          AND StartTime = @SnapshotTime;

        THROW;
    END CATCH;

    -- TODO: 子任务 2/3... 按需复制分段
END;
GO
```

## 3) 数据治理/修复模板（备份 + 对账 + 可回滚）

```sql
/*
目的: TODO（问题描述 + 修复目标）
影响对象: TODO（库/表/字段）
执行窗口: TODO（建议低峰期）
风险: TODO（锁表/阻塞/长事务）

回滚方案:
1) 从备份表回写（推荐）
2) 或按本脚本内回滚 SQL 执行
*/

-- 0) 备份（推荐：将备份表名带日期）
-- TODO: 备份表名规范：<TableName>_bakYYYYMMDD
-- SELECT * INTO dbo.TODO_Table_bak20260203 FROM dbo.TODO_Table;

-- 1) 修复前对账（必须）
-- TODO: 统计受影响范围（行数、关键口径、抽样明细）
SELECT COUNT(1) AS before_cnt
FROM dbo.TODO_Table
WHERE TODO_condition;

-- 2) 修复（建议先小范围验证）
BEGIN TRY
    BEGIN TRAN;

    -- TODO: 修复语句（必要时分批）
    UPDATE t
    SET t.TODO_Col = TODO_Value
    FROM dbo.TODO_Table t
    WHERE TODO_condition;

    SELECT @@ROWCOUNT AS affected_rows;

    COMMIT TRAN;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN;
    THROW;
END CATCH;

-- 3) 修复后对账（必须）
SELECT COUNT(1) AS after_cnt
FROM dbo.TODO_Table
WHERE TODO_condition;

-- 4) 回滚（示例：从备份表回写）
-- UPDATE t
-- SET t.TODO_Col = b.TODO_Col
-- FROM dbo.TODO_Table t
-- INNER JOIN dbo.TODO_Table_bak20260203 b ON b.PK = t.PK
-- WHERE TODO_condition;
```

