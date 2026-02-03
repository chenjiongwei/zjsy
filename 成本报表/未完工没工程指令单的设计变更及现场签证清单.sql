-- 得空帮忙拉一下珠实的清单，设计变更、现场签证，有申报，但是没完工，没工程指令单的数据，
-- 设计变更
SELECT DISTINCT
    bu.buname,
    a.ProjectCostOwnerNames,       -- 项目成本责任单位名称（多值场景下逗号分隔，业务实际多个主体时展开）
    a.ProjectCostOwnerGUIDs,       -- 项目成本责任单位GUID（同上，多值已通过CROSS APPLY拆分）
    a.ContractCodes,               -- 合同编号
    a.ContractNames,               -- 合同名称
    a.AlterGUID,                   -- 设计变更GUID主键
    a.AlterName,                   -- 设计变更名称
    a.AlterCode,                   -- 设计变更编号
    a.AlterReason,                 -- 变更原因
    a.AlterType,                   -- 变更类型
    a.ApplyAmount,                 -- 申报金额
    a.ApproveDate,                 -- 审批日期
    a.ApproveState                -- 审批状态
FROM (
    -- 子查询：针对ProjectCostOwnerGUIDs字段进行拆分（多个责任主体用逗号分隔，需逐一查询其“项目GUID”）
    SELECT 
        value AS ProjGUID,         -- 数据值（逐个ProjectCostOwnerGUID），将用于外部查询的联接
        a.ProjectCostOwnerGUIDs,
        a.ProjectCostOwnerNames,
        ContractCodes,
        ContractNames,
        AlterGUID,
        AlterName,
        AlterCode,
        AlterReason,
        AlterType,
        ApplyAmount,
        ApproveDate,
        ApproveState
    FROM cb_DesignAlterApply AS a
    CROSS APPLY dbo.fn_Split1(a.ProjectCostOwnerGUIDs, ',') --按照逗号分隔责任主体GUID，并一行转多行
    WHERE ISNULL(a.ProjectCostOwnerGUIDs, '') <> '' -- 过滤掉责任主体字段为空的数据
) AS a
INNER JOIN p_Project AS p ON p.p_projectId = a.ProjGUID            -- 关联在拆分后明细的每个项目ID
inner join myBusinessUnit bu on bu.buguid =p.buguid
LEFT JOIN cb_DesignAlterEngineeringOrder AS b
    ON a.AlterGUID = b.AlterGUID             -- 尝试联接工程指令单，实际WHERE过滤未用此表
WHERE NOT EXISTS (
    -- 排除已通过“成本变更确认”审批的变更
    SELECT 1
    FROM cb_DesignAlterCostConfirm AS cfm
    WHERE cfm.AlterGUID = a.AlterGUID
      AND cfm.ApproveState = '已审核'
)
-- 可选：限制项目范围，去除注释即可启用
-- AND p.p_projectId IN (
--     'E5F9A169-B2C3-477E-DB5E-08DD01CAD6A4',
--     'E0732CAA-BD8C-4D22-C3BF-08DD25F05778'
-- )

-- 现场签证
SELECT distinct
    bu.BUName,
    a.ProjectCostOwnerNames,
    a.ProjGUID,
    a.ContractCodes,
    a.ContractNames,
    a.AlterGUID,
    a.AlterName,
    a.AlterCode,
    a.AlterReason,
    a.AlterType,
    a.ApplyAmount,
    a.ApproveDate,
    a.ApproveState
FROM 
(
        SELECT 
        value AS ProjGUID,         -- 数据值（逐个ProjectCostOwnerGUID），将用于外部查询的联接
        a.ProjectCostOwnerGUIDs,
        a.ProjectCostOwnerNames,
        ContractCodes,
        ContractNames,
        AlterGUID,
        AlterName,
        AlterCode,
        AlterReason,
        AlterType,
        ApplyAmount,
        ApproveDate,
        ApproveState
    FROM cb_LocaleAlterApply AS a
    CROSS APPLY dbo.fn_Split1(a.ProjectCostOwnerGUIDs, ',') --按照逗号分隔责任主体GUID，并一行转多行
    WHERE ISNULL(a.ProjectCostOwnerGUIDs, '') <> '' -- 过滤掉责任主体字段为空的数据
) a
INNER JOIN p_Project p   ON p.p_projectId = a.ProjGUID
inner join myBusinessUnit bu on bu.buguid =p.buguid
LEFT JOIN cb_LocaleAlterEngineeringOrder b 
    ON a.AlterGUID = b.AlterGUID

WHERE NOT EXISTS (
    SELECT 1 
    FROM cb_LocaleAlterCostConfirm cfm 
    WHERE cfm.AlterGUID = a.AlterGUID
      AND cfm.ApproveState = '已审核'
)
