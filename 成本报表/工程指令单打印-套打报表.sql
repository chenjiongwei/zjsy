-- 修改工程指令单打印-套打报表 将"工程指令单打印"这个审批步骤剔除
SELECT
    A.AlterGUID,
    '设计变更' AS 变更类型,
    A.AlterName AS '变更名称',
    B.ContractName AS '合同编号',
    B.ContractName AS '合同名称',
    A.AlterCode AS '变更单号',
    O.CommandCode AS '指令单编号',
    O.JbDeptName AS '费用责任单位',
    (
        SELECT TOP 1 x_AlterReason 
        FROM x_cb_DesignAlter2AlterReason 
        WHERE x_AlterGUID = O.AlterGUID
    ) AS '变更原因',
    B.ZSProviderName AS '乙方单位',
    O.CommandContext AS '变更说明',
    A.ApplyAmount AS '变更申报金额',
    (
        SELECT TOP 1 AuditorName 
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity 
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE (BusinessGUID = a.AlterGUID)
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime DESC
    ) AS '流程审批中的最后一个人',
    (
        SELECT TOP 1 HandleDatetime 
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity 
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE (BusinessGUID = a.AlterGUID)
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime DESC
    ) AS '最后一个人审批完成时间',
    (
        SELECT TOP 1 AuditorName 
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity 
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE (BusinessGUID = a.AlterGUID)
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime DESC
    ) AS '审批过程中的人',
    STUFF((
        SELECT 
            CAST(',' AS VARCHAR(MAX)) + CAST(AuditorName AS VARCHAR(MAX))
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity 
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid 
                            AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE (BusinessGUID = a.AlterGUID) 
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime
        FOR XML PATH('')
    ), 1, 1, '') AS '抄送人'
FROM cb_DesignAlterEngineeringOrder O
LEFT JOIN cb_DesignAlterApply A ON O.AlterGUID = A.AlterGUID
LEFT JOIN cb_Contract B ON O.ContractGUID = B.ContractGUID
WHERE (1=1) 
    AND O.AlterProjectCommandGUID = @oid

UNION ALL 

SELECT
    A.AlterGUID,
    '现场签证' AS 变更类型,
    A.AlterName AS '变更名称',
    B.ContractName AS '合同编号',
    B.ContractName AS '合同名称',
    A.AlterCode AS '变更单号',
    O.CommandCode AS '指令单编号',
    O.JbDeptName AS '费用责任单位',
    A.AlterReason AS '变更原因',
    B.ZSProviderName AS '乙方单位',
    O.CommandContext AS '变更说明',
    A.ApplyAmount AS '变更申报金额',
    (
        SELECT TOP 1 AuditorName
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid 
                            AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE BusinessGUID = A.AlterGUID
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime DESC
    ) AS '流程审批中的最后一个人',
    (
        SELECT TOP 1 HandleDatetime
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid 
                            AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE BusinessGUID = A.AlterGUID
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime DESC
    ) AS '最后一个人审批完成时间',
    (
        SELECT TOP 1 AuditorName
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid 
                            AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE BusinessGUID = A.AlterGUID
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime DESC
    ) AS '审批过程中的人',
    STUFF((
        SELECT 
            ',' + CAST(AuditorName AS VARCHAR(MAX))
        FROM dbo.myWorkflowNodeEntity
        LEFT JOIN dbo.myWorkflowProcessEntity
            ON dbo.myWorkflowNodeEntity.ProcessGUID = dbo.myWorkflowProcessEntity.ProcessGUID
        left join dbo.myworkflowsteppathentity on  myworkflowsteppathentity.steppathguid = myWorkflowNodeEntity.steppathguid 
                            AND myWorkflowNodeEntity.ProcessGUID = myworkflowsteppathentity.ProcessGUID
        WHERE BusinessGUID = A.AlterGUID
            AND stepname <> '工程指令单打印'
            AND HandlerName <> '工作流引擎'
        ORDER BY HandleDatetime
        FOR XML PATH('')
    ), 1, 1, '') AS '抄送人'
FROM cb_LocaleAlterEngineeringOrder O
LEFT JOIN cb_LocaleAlterApply A ON O.AlterGUID = A.AlterGUID
LEFT JOIN cb_Contract B ON O.ContractGUID = B.ContractGUID
WHERE O.AlterProjectCommandGUID = @oid




