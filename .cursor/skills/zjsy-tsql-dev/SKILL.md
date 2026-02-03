---
name: zjsy-tsql-dev
description: Develop and review SQL Server (T-SQL) database scripts for 珠江实业客户, following repo conventions (GO, TRY...CATCH/THROW, temp tables, WITH(NOLOCK), data_wide_* wide tables, snapshot jobs/logging). Use when writing or refactoring .sql scripts for reports/queries, stored procedures/jobs (snapshot & execution logs), or data governance/fix scripts (backup + rollback + impact checks).
---

# 珠江实业 T-SQL 脚本开发

## 快速开始

当你需要为“珠江实业客户”编写/改造 SQL Server (T‑SQL) 脚本时：

- 先按“决策树”确定脚本类型
- 从 `references/templates.md` 复制对应模板并替换占位符
- 交付/上线前用 `references/checklists.md` 自检

## 工作流决策树（先分型再写）

- **报表/查询脚本**：以 `SELECT` 为主，允许临时表 `#` 拆解，常见“实时/快照版本号”双口径
- **存储过程/作业脚本**：`CREATE/ALTER PROCEDURE`，分段 `TRY...CATCH`，写执行日志表，失败 `THROW`
- **数据治理/修复脚本**：先备份/对账，再修复；强调可回滚、影响行数可解释、避免长事务阻塞

## 通用约定（所有类型都遵守）

- **脚本头部注释（必须）**：目的、影响对象（库/表/存储过程）、执行环境、是否可重复执行、回滚方案
- **参数化优先**：`@BUGUID / @ProjGUID / @版本号 / @StartDate/@EndDate` 等作为输入，避免硬编码
- **口径与单位明确**：金额是否 `/10000.0`、日期口径（`SkDate` vs `CWSkDate`）、关键业务字段取值逻辑要写明
- **可验证**：关键更新/插入后输出或记录 `@@ROWCOUNT`；治理脚本必须提供 before/after 对账
- **一致的 T‑SQL 风格**：
  - 存储过程：`SET NOCOUNT ON;`
  - 临时表：创建前先 drop，结束后清理
  - `WITH(NOLOCK)` 仅在容忍不一致的报表场景使用，并在注释说明风险
- **先查表结构再写 SQL（推荐）**：当涉及“表结构/字段含义/字段口径/主键/关联关系/枚举值”等问题时，优先读取对应系统的数据字典设计文档，再落到脚本实现，避免凭经验猜字段。

仓库内代表脚本可用于对照风格：

- `销售系统/报表拍照存储过程SP_SnapshotReport.sql`
- `销售系统/01考核汇总表.sql`
- `计划系统/修改计划节点信息.sql`

## 报表/查询脚本开发指南

- **推荐形态**：确有需要时做“实时/快照版本号”双口径：实时从 `data_wide_*` 宽表计算，快照从 `Result_*`/`*_snapshot` 表读取
- **性能**：
  - 过滤条件尽量落在可索引字段上（日期、GUID、状态），避免在列上套函数
  - 复杂口径用 `#临时表` 分段汇总，避免超长单条 SQL 难维护
- **一致性**：字段顺序、中文别名与下游报表保持一致

## 存储过程/作业（快照类）开发指南

- **骨架**：`USE ...; GO` + `ANSI_NULLS/QUOTED_IDENTIFIER` + `ALTER PROCEDURE` + `SET NOCOUNT ON;`
- **日志与分段**：每个子任务独立 `TRY...CATCH`，Started/Completed/Failed 都要写；失败记录 `ERROR_MESSAGE()` 并 `THROW`
- **临时表**：创建前 drop；结束后清理

## 数据治理/修复脚本开发指南

- **执行策略（强制）**：备份 → 修复前对账 → 修复 → 修复后对账 → 回滚方案
- **事务策略**：小范围可单事务；大范围优先分批（batch）降低锁表与阻塞风险
- **交付物**：同一份 `.sql` 内包含变更说明、对账查询、修复语句、回滚语句/指引

## 示例触发语句（用于自测）

- 报表：`写一个报表 SQL，支持 @版本号=实时/快照，按项目过滤且输出字段口径一致。`
- 快照作业：`把 XX 报表做成快照存储过程：分段 TRY...CATCH，写 SnapshotExecutionLog，失败 THROW。`
- 修复治理：`写一个数据治理修复脚本：先备份表，再修复字段值，给出 before/after 对账与回滚。`

## 本 Skill 的参考文件

- `references/templates.md`：三类脚本可复制模板
- `references/checklists.md`：交付/上线前检查清单
- `references/采招系统-数据字典文档_设计文档.md`：采招系统表结构与字段口径
- `references/成本系统-数据字典文档_设计文档.md`：成本系统表结构与字段口径
- `references/销售系统-数据字典文档_设计文档.md`：销售系统表结构与字段口径

## 数据字典触发场景（遇到这些就先读字典）

- “某张表有哪些字段/字段含义是什么/字段是否可空/默认值/枚举值”
- “主键是什么/与哪张表关联/如何 join 才不重复”
- “某指标口径字段来自哪里/宽表 data_wide_* 对应明细表是什么”
