SELECT  a.AlterToContractGUID AS AlterGUID ,
        a.AlterGUID AS DesignAlterGUID,
        1 AS AlterClassEnum ,
        '设计变更' AS AlterClass ,
        b.ApproveDate,
        b.AlterCode ,
        b.AlterName ,
        b.AlterTypeGuid ,
        b.AlterType ,
        b.AlterReasonGuid ,
        b.AlterReason ,
        b.InvolveMajorGUIDs AS InvolveMajorsGUID ,
        b.InvolveMajors ,
        b.Remarks ,
        b.ReportDate ,
        b.ApproveStateEnum,
        b.ApproveState,
        d.ApproveStateEnum AS ZjspApproveStateEnum,
        d.ApproveState AS ZjspApproveState,
        a.ContractGUID ,
        b.ProjGUID ,
        b.BUGUID ,
        a.ApplyAmount ,
        a.ApplyAmountNonTax ,
        a.ApproveAmount AS AuditAmount ,
        a.ApproveAmountNonTax AS AuditAmountNonTax ,
        t.ProjectCostOwnerGUIDs ,
        t1.ProjectCostOwnerGUIDs AS ZjspProjectCostOwnerGUIDs ,
        ISNULL(e.AmountBw,0) AS ApplyInvalidCostAmount ,
        ISNULL(f.AmountBw,0) AS ZjspInvalidCostAmount,
        b.JbrName as AlterJbrName,
        b.CreatedTime
FROM    dbo.cb_DesignAlterApplyToContract a
        LEFT JOIN dbo.cb_DesignAlterApply b ON a.AlterGUID = b.AlterGUID
        LEFT JOIN ( SELECT  AlterGuid ,
                            ContractGuid ,
                            SUM(ISNULL(InvalidCostAmount,0)) AS AmountBw
                    FROM    dbo.cb_DesignAlterApplyInvalidCost
                    GROUP BY AlterGuid ,
                            ContractGuid
                  ) e ON a.AlterGuid = e.AlterGuid
                         AND a.ContractGUID = e.ContractGuid
        LEFT JOIN dbo.cb_DesignAlterCostConfirm d ON a.AlterGuid = d.AlterGUID
                                              AND a.ContractGUID = d.ContractGUID
        LEFT JOIN ( SELECT  AlterGUID ,
                            SUM(ISNULL(InvalidCostAmount,0)) AS AmountBw
                    FROM    dbo.cb_DesignAlterCostConfirmInvalidCost
                    GROUP BY AlterGUID
                  ) f ON f.AlterGUID = d.AlterZJSPGUID
        OUTER APPLY ( SELECT    STUFF(( SELECT DISTINCT
                                                ','
                                                + CONVERT(VARCHAR(100), ProjectGUID)
                                        FROM    dbo.cb_DesignAlterApplyBudgetUse
                                        WHERE   AlterGUID = b.AlterGUID
                                                AND ContractGUID = a.ContractGUID
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS ProjectCostOwnerGUIDs
                    ) t
        OUTER APPLY ( SELECT    STUFF(( SELECT DISTINCT
                                                ','
                                                + CONVERT(VARCHAR(100), ProjectGUID)
                                        FROM    dbo.cb_DesignAlterCostConfirmBudgetUse
                                        WHERE   AlterGUID = d.AlterZjspGUID
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS ProjectCostOwnerGUIDs
                    ) t1
UNION ALL
SELECT  ISNULL(a.AlterGUID,toc.AlterGUID) AS AlterGUID ,
        a.AlterGUID AS DesignAlterGUID,
        2 AS AlterClassEnum ,
        '现场签证' AS AlterClass ,
        a.ApproveDate,
        a.AlterCode ,
        a.AlterName ,
        a.AlterTypeGUID ,
        a.AlterType ,
        a.AlterReasonGUID ,
        a.AlterReason ,
        a.InvolveMajorGUIDs AS InvolveMajorsGUID ,
        a.InvolveMajors ,
        a.Remarks ,
        a.ReportDate ,
        a.ApproveStateEnum ,
        a.ApproveState ,
        c.ApproveStateEnum AS ZjspApproveStateEnum,
        c.ApproveState AS ZjspApproveState,
        toc.ContractGUID,
        a.ProjGUID ,
        a.BUGUID ,
        a.ApplyAmount ,
        toc.ApplyAmountNonTax,
        a.AuditAmount ,
        a.AuditAmountNonTax,
        t.ProjectCostOwnerGUIDs ,
        t1.ProjectCostOwnerGUIDs AS ZjspProjectCostOwnerGUIDs ,
        ISNULL(a.InvalidCostAmount,0) ,
        ISNULL(c.InvalidCostAmount,0),
        a.JbrName as AlterJbrName,
        a.CreatedTime
FROM    dbo.cb_LocaleAlterApplyToContract toc
        LEFT JOIN dbo.cb_LocaleAlterApply a ON toc.AlterGUID = a.AlterGUID
        LEFT JOIN dbo.cb_Contract b ON toc.ContractGUID = b.ContractGUID
        LEFT JOIN dbo.cb_LocaleAlterCostConfirm c ON toc.AlterGUID = c.AlterGUID
        OUTER APPLY ( SELECT    STUFF(( SELECT DISTINCT
                                                ','
                                                + CONVERT(VARCHAR(100), ProjectGUID)
                                        FROM    dbo.cb_LocaleAlterApplyBudgetUse
                                        WHERE   AlterGUID = toc.AlterGUID
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS ProjectCostOwnerGUIDs
                    ) t
        OUTER APPLY ( SELECT    STUFF(( SELECT DISTINCT
                                                ','
                                                + CONVERT(VARCHAR(100), ProjectGUID)
                                        FROM    dbo.cb_LocaleAlterCostConfirmBudgetUse
                                        WHERE   AlterGUID = c.AlterZjspGUID
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS ProjectCostOwnerGUIDs
                    ) t1
UNION ALL
SELECT  a.AlterGUID AS AlterGUID ,
        a.AlterGUID AS DesignAlterGUID,
        3 AS AlterClassEnum ,
        '材料调差' AS AlterClass ,
        a.ApproveDate,
        a.AlterCode ,
        a.AlterName ,
        a.AlterTypeGUID ,
        a.AlterType ,
        a.AlterReasonGUID ,
        a.AlterReason ,
        a.InvolveMajorGUIDs AS InvolveMajorsGUID ,
        a.InvolveMajors ,
        a.Remarks ,
        a.ReportDate ,
        a.ApproveStateEnum ,
        a.ApproveState ,
        4 AS ZjspApproveStateEnum,
        '无需完工' AS ZjspApproveState,
        toc.ContractGUID,
        a.ProjGUID ,
        a.BUGUID ,
        a.ApplyAmount ,
        toc.ApplyAmountNonTax,
        a.AuditAmount ,
        a.AuditAmountNonTax,
        t.ProjectCostOwnerGUIDs ,
        null AS ZjspProjectCostOwnerGUIDs ,
        ISNULL(a.InvalidCostAmount,0) ,
        NULL,
        a.JbrName as AlterJbrName,
        a.CreatedTime
FROM    dbo.cb_MaterialDiffApplyToContract toc
        LEFT JOIN dbo.cb_MaterialDiffApply a ON toc.AlterGUID = a.AlterGUID
        LEFT JOIN dbo.cb_Contract b ON toc.ContractGUID = b.ContractGUID
        OUTER APPLY ( SELECT    STUFF(( SELECT DISTINCT
                                                ','
                                                + CONVERT(VARCHAR(100), ProjectGUID)
                                        FROM    dbo.cb_MaterialDiffApplyBudgetUse
                                        WHERE   AlterGUID = toc.AlterGUID
                                      FOR
                                        XML PATH('')
                                      ), 1, 1, '') AS ProjectCostOwnerGUIDs
                    ) t
