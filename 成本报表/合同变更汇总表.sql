--处理变更对应多分期
SELECT  DISTINCT a.ContractGUID ,
                 b.ProjectCostOwnerGUIDs
INTO    #cb_alter
FROM(SELECT a.AlterGUID ,
            a.ContractGUID ,
            a.AlterType ,
            ProjectCostOwnerGUIDs = CAST('<v>' + REPLACE(ISNULL(a.ZjspProjectCostOwnerGUIDs, a.ProjectCostOwnerGUIDs), ',', '</v><v>') + '</v>' AS XML)
     FROM   data_wide_cb_alter a WITH(NOLOCK)) a
    OUTER APPLY(SELECT  ProjectCostOwnerGUIDs = t.c.value('.', 'varchar(max)')
                FROM    a.ProjectCostOwnerGUIDs.nodes('/v') AS t(c) ) b;

SELECT  P1.ProjName AS 项目名称 ,
        P.ProjName AS 分期名称 ,
        SUM(cb.TotalAmount) AS 合同金额 ,
        SUM(cb.BcContractAmount) AS 补充协议金额 ,
        SUM(bc.项目需求) AS 项目需求金额 ,
        SUM(bc.项目需求) / NULLIF(SUM(bc.变更原因分母用), 0) AS 项目需求比例 ,
        SUM(bc.设计需求) AS 设计需求金额 ,
        SUM(bc.设计需求) / NULLIF(SUM(bc.变更原因分母用), 0) AS 设计需求比例 ,
        SUM(bc.营销需求) AS 营销需求金额 ,
        SUM(bc.营销需求) / NULLIF(SUM(bc.变更原因分母用), 0) AS 营销需求比例 ,
        SUM(bc.设计变更) AS 设计变更金额 ,
        SUM(bc.设计变更) / NULLIF(SUM(bc.变更原因分母用), 0) AS 设计变更比例 ,
        SUM(bc.现场签证) AS 现场签证金额 ,
        SUM(bc.现场签证) / NULLIF(SUM(bc.变更原因分母用), 0) AS 现场签证比例 ,
        SUM(ISNULL(cb.HtAmount, 0) + ISNULL(cb.BcContractAmount, 0)) AS 合同净值加补协 ,
        -- SUM(LjAlter.Cfamount_Total) AS 合同累计变更金额 ,
        -- SUM(LjAlter.Cfamount_Total) / NULLIF(SUM(cb.TotalAmount), 0) AS 合同累计变更比例 ,
        -- SUM(LjAlter.Cfamount_Design) AS 累计设计变更金额 ,
        -- SUM(LjAlter.Cfamount_Design) / NULLIF(SUM(cb.TotalAmount), 0) AS 累计设计变更比例 ,
        -- SUM(LjAlter.Cfamount_Local) AS 累计现场签证金额 ,
        -- SUM(LjAlter.Cfamount_Local) / NULLIF(SUM(cb.TotalAmount), 0) AS 累计现场签证比例 ,
        -- SUM(LjAlter.Cfamount_Mate) AS 累计材料调差金额 ,
        -- SUM(LjAlter.Cfamount_Mate) / NULLIF(SUM(cb.TotalAmount), 0) AS 累计材料调差比例 ,

        SUM(bg.Cfamount_Total) AS 合同累计变更金额 ,
        SUM(bg.Cfamount_Total) / NULLIF(SUM(cb.TotalAmount), 0) AS 合同累计变更比例 ,
        SUM(bg.Cfamount_Design) AS 累计设计变更金额 ,
        SUM(bg.Cfamount_Design) / NULLIF(SUM(cb.TotalAmount), 0) AS 累计设计变更比例 ,
        SUM(bg.Cfamount_Local) AS 累计现场签证金额 ,
        SUM(bg.Cfamount_Local) / NULLIF(SUM(cb.TotalAmount), 0) AS 累计现场签证比例 ,
        SUM(LjAlter.Cfamount_Mate) AS 累计材料调差金额 ,
        SUM(LjAlter.Cfamount_Mate) / NULLIF(SUM(cb.TotalAmount), 0) AS 累计材料调差比例 ,

        SUM(bg.设计变更营销管理因素) AS 设计变更营销管理因素金额 ,
        SUM(bg.设计变更营销管理因素) / NULLIF(SUM(bg.设计变更分母用), 0) AS 设计变更营销管理因素比例 ,
        SUM(bg.设计变更设计管理因素) AS 设计变更设计管理因素金额 ,
        SUM(bg.设计变更设计管理因素) / NULLIF(SUM(bg.设计变更分母用), 0) AS 设计变更设计管理因素比例 ,
        SUM(bg.设计变更经营管理因素) AS 设计变更经营管理因素金额 ,
        SUM(bg.设计变更经营管理因素) / NULLIF(SUM(bg.设计变更分母用), 0) AS 设计变更经营管理因素比例 ,
        SUM(bg.设计变更政策环境因素) AS 设计变更政策环境因素金额 ,
        SUM(bg.设计变更政策环境因素) / NULLIF(SUM(bg.设计变更分母用), 0) AS 设计变更政策环境因素比例 ,
        SUM(bg.设计变更工程管理因素) AS 设计变更工程管理因素金额 ,
        SUM(bg.设计变更工程管理因素) / NULLIF(SUM(bg.设计变更分母用), 0) AS 设计变更工程管理因素比例 ,
        SUM(bg.设计变更进度管理因素) AS 设计变更进度管理因素金额 ,
        SUM(bg.设计变更进度管理因素) / NULLIF(SUM(bg.设计变更分母用), 0) AS 设计变更进度管理因素比例 ,
        SUM(bg.现场签证现场管理因素) AS 现场签证现场管理因素金额 ,
        SUM(bg.现场签证现场管理因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证现场管理因素比例 ,
        SUM(bg.现场签证工程签证因素) AS 现场签证工程签证因素金额 ,
        SUM(bg.现场签证工程签证因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证工程签证因素比例 ,
        SUM(bg.现场签证施工方案因素) AS 现场签证施工方案因素金额 ,
        SUM(bg.现场签证施工方案因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证施工方案因素比例 ,
        SUM(bg.现场签证进度管理因素) AS 现场签证进度管理因素金额 ,
        SUM(bg.现场签证进度管理因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证进度管理因素比例 ,
        SUM(bg.现场签证设计管理因素) AS 现场签证设计管理因素金额 ,
        SUM(bg.现场签证设计管理因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证设计管理因素比例 ,
        SUM(bg.现场签证索赔管理因素) AS 现场签证索赔管理因素金额 ,
        SUM(bg.现场签证索赔管理因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证索赔管理因素比例 ,
        SUM(bg.现场签证供应商因素) AS 现场签证供应商因素金额 ,
        SUM(bg.现场签证供应商因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证供应商因素比例 ,
        SUM(bg.现场签证营销因素) AS 现场签证营销因素金额 ,
        SUM(bg.现场签证营销因素) / NULLIF(SUM(bg.现场签证分母用), 0) AS 现场签证营销因素比例 ,
        SUM(lx.设计变更审核实施份数) AS 设计变更审核实施份数 ,
        SUM(lx.设计变更不实施份数) AS 设计变更不实施份数 ,
        SUM(bg.已审核设计变更预估份数) AS 已审核设计变更预估份数 ,
        SUM(bg.设计变更预估申报金额) AS 设计变更预估申报金额 ,
        SUM(bg.设计变更预估审核金额) AS 设计变更预估审核金额 ,
        SUM(bg.设计变更超期录入份数) AS 设计变更超期录入份数 ,
        SUM(bg.设计变更指令单份数) AS 设计变更指令单份数 ,
        SUM(bg.设计变更超期单价确认份数) AS 设计变更超期单价确认份数 ,
        SUM(bg.已审核设计变更完工确认份数) AS 已审核设计变更完工确认份数 ,
        SUM(bg.设计变更完工确认申报金额) AS 设计变更完工确认申报金额 ,
        SUM(bg.设计变更完工确认审核金额) AS 设计变更完工确认审核金额 ,
        SUM(lx.现场签证审核实施份数) AS 现场签证审核实施份数 ,
        SUM(lx.现场签证不实施份数) AS 现场签证不实施份数 ,
        SUM(bg.已审核现场签证预估份数) AS 已审核现场签证预估份数 ,
        SUM(bg.现场签证预估申报金额) AS 现场签证预估申报金额 ,
        SUM(bg.现场签证预估审核金额) AS 现场签证预估审核金额 ,
        SUM(bg.现场签证超期录入份数) AS 现场签证超期录入份数 ,
        SUM(bg.现场签证指令单份数) AS 现场签证指令单份数 ,
        SUM(bg.现场签证超期单价确认份数) AS 现场签证超期单价确认份数 ,
        SUM(bg.已审核现场签证完工确认份数) AS 已审核现场签证完工确认份数 ,
        SUM(bg.现场签证完工确认申报金额) AS 现场签证完工确认申报金额 ,
        SUM(bg.现场签证完工确认审核金额) AS 现场签证完工确认审核金额 ,
        --
        ISNULL(SUM(bgz.审核中设计变更预估份数), 0) AS 审核中设计变更预估份数 ,
        ISNULL(SUM(bgz.审核中现场签证预估份数), 0) AS 审核中现场签证预估份数 ,
        ISNULL(SUM(bgz.审核中设计变更完工确认份数), 0) AS 审核中设计变更完工确认份数 ,
        ISNULL(SUM(bgz.审核中现场签证完工确认份数), 0) AS 审核中现场签证完工确认份数 ,
        ISNULL(SUM(bgw.未审核设计变更预估份数), 0) AS 未审核设计变更预估份数 ,
        ISNULL(SUM(bgw.未审核现场签证预估份数), 0) AS 未审核现场签证预估份数 ,
        ISNULL(SUM(wsh1.未审核设计变更完工确认份数), 0) AS 未审核设计变更完工确认份数 ,
        ISNULL(SUM(wsh2.未审核现场签证完工确认份数), 0) AS 未审核现场签证完工确认份数 ,
        --,sum(bgq.设计变更预估份数) as 设计变更预估份数,sum(bgq.现场签证预估份数) as 现场签证预估份数,sum(bgq.设计变更完工确认份数) as 设计变更完工确认份数,sum(bgq.现场签证完工确认份数) as 现场签证完工确认份数
        ISNULL(SUM(bg.已审核设计变更预估份数), 0) + ISNULL(SUM(bgz.审核中设计变更预估份数), 0) + ISNULL(SUM(bgw.未审核设计变更预估份数), 0) AS 设计变更预估份数 ,
        ISNULL(SUM(bg.已审核现场签证预估份数), 0) + ISNULL(SUM(bgz.审核中现场签证预估份数), 0) + ISNULL(SUM(bgw.未审核现场签证预估份数), 0) AS 现场签证预估份数 ,
        ISNULL(SUM(bg.已审核设计变更完工确认份数), 0) + ISNULL(SUM(bgz.审核中设计变更完工确认份数), 0) + ISNULL(SUM(wsh1.未审核设计变更完工确认份数), 0) AS 设计变更完工确认份数 ,
        ISNULL(SUM(bg.已审核现场签证完工确认份数), 0) + ISNULL(SUM(bgz.审核中现场签证完工确认份数), 0) + ISNULL(SUM(wsh2.未审核现场签证完工确认份数), 0) AS 现场签证完工确认份数
--
FROM    data_wide_cb_contract cb
        INNER JOIN dbo.data_wide_cb_ContractProj CP ON cb.ContractGUID = CP.ContractGUID
        INNER JOIN(SELECT   ContractGUID, ProjectCostOwnerGUIDs FROM    #cb_alter) alt ON cb.ContractGUID = alt.ContractGUID AND   CP.ProjGUID = alt.ProjectCostOwnerGUIDs
        LEFT JOIN(SELECT    b.mastercontractguid ,
                            SUM(CASE WHEN a.x_ReasonType = '项目需求' THEN a.x_FtAmount ELSE 0 END) AS 项目需求 ,
                            SUM(CASE WHEN a.x_ReasonType = '设计需求' THEN a.x_FtAmount ELSE 0 END) AS 设计需求 ,
                            SUM(CASE WHEN a.x_ReasonType = '营销需求' THEN a.x_FtAmount ELSE 0 END) AS 营销需求 ,
                            SUM(CASE WHEN a.x_ReasonType = '设计变更' THEN a.x_FtAmount ELSE 0 END) AS 设计变更 ,
                            SUM(CASE WHEN a.x_ReasonType = '现场签证' THEN a.x_FtAmount ELSE 0 END) AS 现场签证 ,
                            SUM(a.x_FtAmount) AS 变更原因分母用
                  FROM  dotnet_erp60.dbo.x_cb_BcContractReasonType a
                        INNER JOIN data_wide_cb_SubAndBcContract b ON a.x_bccontractguid = b.subandbccontractguid
                  WHERE a.x_ReasonType IN ('项目需求', '设计需求', '营销需求', '设计变更', '现场签证')
                  GROUP BY b.mastercontractguid) bc ON cb.ContractGUID = bc.mastercontractguid
        --累计变更
        LEFT JOIN(SELECT    ContractGUID ,
                            SUM(CASE WHEN BillTypeEnum IN (6, 7, 8, 9, 20) THEN Cfamount ELSE 0 END) Cfamount_Total ,
                            SUM(CASE WHEN BillTypeEnum IN (6, 7) THEN Cfamount ELSE 0 END) Cfamount_Design ,
                            SUM(CASE WHEN BillTypeEnum IN (8, 9) THEN Cfamount ELSE 0 END) Cfamount_Local ,
                            SUM(CASE WHEN BillTypeEnum IN (20) THEN Cfamount ELSE 0 END) Cfamount_Mate
                  FROM  data_wide_cb_budgetuse b WITH(NOLOCK)
                  WHERE b.BillTypeEnum IN (6, 7, 8, 9, 20) AND ApproveStateEnum = 3
                  GROUP BY ContractGUID) LjAlter ON LjAlter.ContractGUID = cb.ContractGUID
        LEFT JOIN(SELECT    contractguid ,
                            sum(case when alterclass = '设计变更' then  applyamount else  0  end  ) as Cfamount_Design,
                            sum(case when alterclass = '现场签证' then  applyamount else  0  end  ) as Cfamount_Local,
                            sum(case when alterclass in ('现场签证','设计变更')  then applyamount else  0  end  ) as Cfamount_Total,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason = '营销管理因素' THEN applyamount ELSE 0 END) AS 设计变更营销管理因素 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason = '设计管理因素' THEN applyamount ELSE 0 END) AS 设计变更设计管理因素 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason = '经营管理因素' THEN applyamount ELSE 0 END) AS 设计变更经营管理因素 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason = '政策环境因素' THEN applyamount ELSE 0 END) AS 设计变更政策环境因素 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason = '工程管理因素' THEN applyamount ELSE 0 END) AS 设计变更工程管理因素 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason = '进度管理因素' THEN applyamount ELSE 0 END) AS 设计变更进度管理因素 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   alterreason IN ('营销管理因素', '设计管理因素', '经营管理因素', '政策环境因素', '工程管理因素', '进度管理因素') THEN applyamount ELSE 0 END) AS 设计变更分母用 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '现场管理因素' THEN applyamount ELSE 0 END) AS 现场签证现场管理因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '工程签证因素' THEN applyamount ELSE 0 END) AS 现场签证工程签证因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '施工方案因素' THEN applyamount ELSE 0 END) AS 现场签证施工方案因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '进度管理因素' THEN applyamount ELSE 0 END) AS 现场签证进度管理因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '设计管理因素' THEN applyamount ELSE 0 END) AS 现场签证设计管理因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '索赔管理因素' THEN applyamount ELSE 0 END) AS 现场签证索赔管理因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '供应商因素' THEN applyamount ELSE 0 END) AS 现场签证供应商因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason = '营销因素' THEN applyamount ELSE 0 END) AS 现场签证营销因素 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   alterreason IN ('现场管理因素', '工程签证因素', '施工方案因素', '进度管理因素', '设计管理因素', '索赔管理因素', '供应商因素', '营销因素') THEN applyamount ELSE 0 END) AS 现场签证分母用 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 设计变更审核实施份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   ISNULL(iszjsp, 0) <> 1 THEN 1 ELSE 0 END) AS 设计变更不实施份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' THEN 1 ELSE 0 END) AS 已审核设计变更预估份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' THEN applyamount ELSE 0 END) AS 设计变更预估申报金额 ,
                            SUM(CASE WHEN alterclass = '设计变更' THEN AuditAmount ELSE 0 END) AS 设计变更预估审核金额 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   DATEDIFF(dd, ReportDate, CreatedTime) > 7 THEN 1 ELSE 0 END) AS 设计变更超期录入份数 ,
                            COUNT(CASE WHEN alterclass = '设计变更' THEN ProjectCommandCode END) AS 设计变更指令单份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   DATEDIFF(dd, ReportDate, x_DjQrDate) > 45 THEN 1 ELSE 0 END) AS 设计变更超期单价确认份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 已审核设计变更完工确认份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   iszjsp = 1 THEN ZjspApplyAmount ELSE 0 END) AS 设计变更完工确认申报金额 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   iszjsp = 1 THEN ZjspAuditAmount ELSE 0 END) AS 设计变更完工确认审核金额 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 现场签证审核实施份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   ISNULL(iszjsp, 0) <> 1 THEN 1 ELSE 0 END) AS 现场签证不实施份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' THEN 1 ELSE 0 END) AS 已审核现场签证预估份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' THEN applyamount ELSE 0 END) AS 现场签证预估申报金额 ,
                            SUM(CASE WHEN alterclass = '现场签证' THEN AuditAmount ELSE 0 END) AS 现场签证预估审核金额 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   DATEDIFF(dd, ReportDate, CreatedTime) > 30 THEN 1 ELSE 0 END) AS 现场签证超期录入份数 ,
                            COUNT(CASE WHEN alterclass = '现场签证' THEN ProjectCommandCode END) AS 现场签证指令单份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   DATEDIFF(dd, ReportDate, x_DjQrDate) > 45 THEN 1 ELSE 0 END) AS 现场签证超期单价确认份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 已审核现场签证完工确认份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   iszjsp = 1 THEN ZjspApplyAmount ELSE 0 END) AS 现场签证完工确认申报金额 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   iszjsp = 1 THEN ZjspAuditAmount ELSE 0 END) AS 现场签证完工确认审核金额
                  FROM  data_wide_cb_alter
                  WHERE ApproveState = '已审核'   AND   CreatedTime >= @tjdate
                  GROUP BY contractguid) bg ON cb.contractguid = bg.contractguid
/*
--审核中
left join 
(
select 
contractguid,
sum(case when alterclass='设计变更' then 1 else 0 end) as 审核中设计变更预估份数,
sum(case when alterclass='现场签证' then 1 else 0 end) as 审核中现场签证预估份数,
sum(case when alterclass='设计变更' and iszjsp=1 then 1 else 0 end) as 审核中设计变更完工确认份数,
sum(case when alterclass='现场签证' and iszjsp=1 then 1 else 0 end) as 审核中现场签证完工确认份数

from data_wide_cb_alter 
where ApproveState='审核中'
and CreatedTime>=@tjdate
group by 
contractguid
) bgz on cb.contractguid=bgz.contractguid
--
--未审核设计变更预估份数和未审核现场签证预估份数
left join 
(
select 
contractguid,
sum(case when alterclass='设计变更' then 1 else 0 end) as 未审核设计变更预估份数,
sum(case when alterclass='现场签证' then 1 else 0 end) as 未审核现场签证预估份数

from data_wide_cb_alter 
where ApproveState='未审核'
and CreatedTime>=@tjdate
group by 
contractguid
) bgw on cb.contractguid=bgw.contractguid
--


--未审核设计变更完工确认份数
left join
(
select b.contractguid,
count(1)  as 未审核设计变更完工确认份数
from  dotnet_erp60.dbo.cb_DesignAlterCostConfirm a
left join  dotnet_erp60.dbo.cb_contract b on a.contractguid = b.contractguid
left join dotnet_erp60.dbo.ep_Project c on  b.ProjectCostOwnerGUIDs like  '%'+cast(c.projguid as varchar(36))+'%'

where a.ApproveState = '未审核' and c.projguid in (@projguid)
group by  b.contractguid
)wsh1 
on  cb.contractguid = wsh1.contractguid 



--未审核现场签证完工确认份数
left join 
(
select b.contractguid,
count(1)  as 未审核现场签证完工确认份数
from  dotnet_erp60.dbo.cb_LocaleAlterCostConfirm a
left join  dotnet_erp60.dbo.cb_contract b on a.contractguid = b.contractguid
left join dotnet_erp60.dbo.ep_Project c on  b.ProjectCostOwnerGUIDs like  '%'+cast(c.projguid as varchar(36))+'%'
where a.ApproveState = '未审核' and c.projguid in  (@projguid)
group by b.contractguid
) wsh2 on  cb.contractguid = wsh2.contractguid 
*/
        --总份数
        LEFT JOIN(SELECT    contractguid ,
                            SUM(CASE WHEN alterclass = '设计变更' THEN 1 ELSE 0 END) AS 设计变更预估份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' THEN 1 ELSE 0 END) AS 现场签证预估份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 设计变更完工确认份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 现场签证完工确认份数
                  FROM  data_wide_cb_alter
                  WHERE 1=1 AND   CreatedTime >= @tjdate
                  GROUP BY contractguid) bgq ON cb.contractguid = bgq.contractguid

        --
        LEFT JOIN(SELECT    x_contractguid ,
                            SUM(CASE WHEN itemtype = '设计变更' AND x_IsExec = 1 THEN 1 ELSE 0 END) AS 设计变更审核实施份数 ,
                            SUM(CASE WHEN itemtype = '设计变更' AND ISNULL(x_IsExec, 0) <> 1 THEN 1 ELSE 0 END) AS 设计变更不实施份数 ,
                            SUM(CASE WHEN itemtype = '现场签证' AND x_IsExec = 1 THEN 1 ELSE 0 END) AS 现场签证审核实施份数 ,
                            SUM(CASE WHEN itemtype = '现场签证' AND ISNULL(x_IsExec, 0) <> 1 THEN 1 ELSE 0 END) AS 现场签证不实施份数
                  FROM  dotnet_erp60.dbo.cb_ContractItem
                  WHERE ApproveState = '已审核'   AND   CreatedTime >= @tjdate
                  GROUP BY x_contractguid) lx ON cb.contractguid = lx.x_contractguid
        INNER JOIN data_wide_mdm_Project P WITH(NOLOCK)ON P.p_projectId = CP.ProjGUID
        INNER JOIN data_wide_mdm_Project P1 WITH(NOLOCK)ON P.ParentGUID = P1.p_projectId
        --审核中
        LEFT JOIN(SELECT    contractguid ,
                            ProjGUID ,
                            SUM(CASE WHEN alterclass = '设计变更' THEN 1 ELSE 0 END) AS 审核中设计变更预估份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' THEN 1 ELSE 0 END) AS 审核中现场签证预估份数 ,
                            SUM(CASE WHEN alterclass = '设计变更' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 审核中设计变更完工确认份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' AND   iszjsp = 1 THEN 1 ELSE 0 END) AS 审核中现场签证完工确认份数
                  FROM  data_wide_cb_alter
                  WHERE ApproveState = '审核中'   AND   CreatedTime >= @tjdate
                  GROUP BY contractguid ,
                           ProjGUID) bgz ON cb.contractguid = bgz.contractguid AND bgz.ProjGUID LIKE '%' + CAST(P.p_projectId AS VARCHAR(36)) + '%'
        --
        --未审核设计变更预估份数和未审核现场签证预估份数
        LEFT JOIN(SELECT    contractguid ,
                            ProjGUID ,
                            SUM(CASE WHEN alterclass = '设计变更' THEN 1 ELSE 0 END) AS 未审核设计变更预估份数 ,
                            SUM(CASE WHEN alterclass = '现场签证' THEN 1 ELSE 0 END) AS 未审核现场签证预估份数
                  FROM  data_wide_cb_alter
                  WHERE ApproveState = '未审核'  AND   CreatedTime >= @tjdate
                  GROUP BY contractguid ,
                           ProjGUID) bgw ON cb.contractguid = bgw.contractguid AND bgw.ProjGUID LIKE '%' + CAST(P.p_projectId AS VARCHAR(36)) + '%'
        --
        --未审核设计变更完工确认份数
        LEFT JOIN(SELECT    b.contractguid ,
                            c.projguid ,
                            COUNT(1) AS 未审核设计变更完工确认份数
                  FROM  dotnet_erp60.dbo.cb_DesignAlterCostConfirm a
                        LEFT JOIN dotnet_erp60.dbo.cb_contract b ON a.contractguid = b.contractguid
                        LEFT JOIN dotnet_erp60.dbo.ep_Project c ON b.ProjectCostOwnerGUIDs LIKE '%' + CAST(c.projguid AS VARCHAR(36)) + '%'
                  --LEFT JOIN dotnet_erp60.dbo.cb_DesignAlterApply d ON a.AlterGUID = d.AlterGUID
                  WHERE a.ApproveState = '未审核' AND c.projguid IN (@projguid)
                  GROUP BY b.contractguid ,
                           c.projguid) wsh1 ON cb.contractguid = wsh1.contractguid AND wsh1.projguid LIKE '%' + CAST(P.p_projectId AS VARCHAR(36)) + '%'
        --未审核现场签证完工确认份数
        LEFT JOIN(SELECT    b.contractguid ,
                            c.projguid ,
                            COUNT(1) AS 未审核现场签证完工确认份数
                  FROM  dotnet_erp60.dbo.cb_LocaleAlterCostConfirm a
                        LEFT JOIN dotnet_erp60.dbo.cb_contract b ON a.contractguid = b.contractguid
                        LEFT JOIN dotnet_erp60.dbo.ep_Project c ON b.ProjectCostOwnerGUIDs LIKE '%' + CAST(c.projguid AS VARCHAR(36)) + '%'
                  --LEFT JOIN dotnet_erp60.dbo.cb_LocaleAlterApply d ON a.AlterGUID = d.AlterGUID
                  WHERE a.ApproveState = '未审核' AND c.projguid IN (@projguid)
                  GROUP BY b.contractguid ,
                           c.projguid) wsh2 ON cb.contractguid = wsh2.contractguid AND wsh2.projguid LIKE '%' + CAST(P.p_projectId AS VARCHAR(36)) + '%'
WHERE   P.p_projectId IN (@projguid) AND CONVERT(DATE, cb.CreatedTime, 112) BETWEEN @签约开始日期 AND @签约结束日期
GROUP BY P1.ProjName ,
         P.ProjName;

DROP TABLE #cb_alter;