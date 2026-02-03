USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_rptzjlkb_CashFlowInfoProj]    Script Date: 2026/1/14 18:05:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_s_rptzjlkb_CashFlowInfoProj]
AS
    /*
功能：总经理看板PC报表,获取010303项目经营指标现金流
创建人：chenjw
创建时间：20200813
--------------------------------------------------------------
修改内容：添加融资本月任务，本月实际金额，本月完成率
修改时间：20210719
修改内容: 添加除地价外直投累计任务值,年度任务值,月度任务值,
          营销费用累计任务值,年度任务值;管理费用累计任务值,年度任务值
修改人：yudd
修改时间：20210831
[usp_s_rptzjlkb_CashFlowInfoProj]
*/
    BEGIN
        --获取项目的值
        SELECT  b.ProjGUID AS OrgGUID ,
                b.SpreadName AS OrganizationName ,
                SUM(CASE WHEN sbv.BudgetDimension = '年度' AND sbv.BudgetDimensionValue = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN ISNULL(sbv.ZtPlanTotal, 0)END) / 100000000.00 AS 本年直投任务 ,
                SUM(CASE WHEN sbv.BudgetDimension = '月度' AND sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.ZtPlanTotal, 0)END) / 100000000.00 AS 本月直投任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.RzPlanTotal, 0)
                END) / 100000000.00 AS 本年融资任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.RzRealTotal, 0)
                END) / 100000000.00 AS 本年实际融资 ,
                SUM(CASE WHEN sbv.BudgetDimension = '月度' AND sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.RzPlanTotal, 0)END) / 100000000.00 AS 本月融资任务 ,
                SUM(CASE WHEN sbv.BudgetDimension = '月度' AND sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.RzRealTotal, 0)END) / 100000000.00 AS 本月实际融资 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.PlanInvestmentAmount, 0)
                END) / 100000000.00 AS 本年投资拓展任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.RealInvestmentAmount, 0)
                END) / 100000000.00 AS 本年实际投资拓展 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.PlanCashFlowAmount, 0)
                END) / 100000000.00 AS 本年经营性现金流目标 ,
                -- 除地价外直投\营销费用\管理费用累计任务值   
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) <= CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ZtPlanTotal, 0)
                END) / 100000000.00 AS 累计除地价外直投任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) <= CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.SaleExpensesAmunt, 0)
                END) / 100000000.00 AS 累计营销费用任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) <= CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ManageExpensesAmunt, 0)
                END) / 100000000.00 AS 累计管理费用任务 ,
                --除地价外直投\营销费用\管理费用本年任务值
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ZtPlanTotal, 0)
                END) / 100000000.00 AS 本年除地价外直投任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.SaleExpensesAmunt, 0)
                END) / 100000000.00 AS 本年营销费用任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ManageExpensesAmunt, 0)
                END) / 100000000.00 AS 本年管理费用任务 ,
                --除地价外直投本月任务值
                SUM(CASE WHEN sbv.BudgetDimension = '月度' AND sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.ZtPlanTotal, 0)END) / 100000000.00 AS 本月除地价外直投任务
        INTO    #t_task
        FROM    data_wide_dws_s_SalesBudgetVerride sbv WITH (NOLOCK)
                INNER JOIN dbo.data_wide_dws_mdm_Project b WITH (NOLOCK) ON sbv.OrganizationGUID = b.ProjGUID
        WHERE   b.buguid NOT IN ('4EB64056-C30D-486A-BF5B-FC3BE0A52939') -- AND b.projguid NOT IN ('A1BB9940-2840-E711-80BA-E61F13C57837')
        GROUP BY b.ProjGUID ,
                 b.SpreadName;

        --成都公司取并表口径的融资(2022-12-30取消)
        INSERT INTO #t_task
        SELECT  b.ProjGUID AS OrgGUID ,
                b.SpreadName AS OrganizationName ,
                SUM(CASE WHEN sbv.BudgetDimension = '年度' AND sbv.BudgetDimensionValue = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN ISNULL(sbv.ZtPlanTotal, 0)END) / 100000000.00 AS 本年直投任务 ,
                SUM(CASE WHEN sbv.BudgetDimension = '月度' AND sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.ZtPlanTotal, 0)END) / 100000000.00 AS 本月直投任务 ,
                SUM(CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' --AND GenreTableType = '我司并表'
                              AND   ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN ISNULL(sbv.RzPlanTotal, 0)
                    END) / 100000000.00 AS 本年融资任务 ,
                SUM(CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' --AND GenreTableType = '我司并表'
                              AND   ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN ISNULL(sbv.RzRealTotal, 0)
                    END) / 100000000.00 AS 本年实际融资 ,
                SUM(CASE WHEN sbv.BudgetDimension = '月度' --AND  GenreTableType = '我司并表'
                              AND   sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.RzPlanTotal, 0)
                    END) / 100000000.00 AS 本月融资任务 ,
                SUM(CASE WHEN sbv.BudgetDimension = '月度' --AND GenreTableType = '我司并表'
                              AND   sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.RzRealTotal, 0)
                    END) / 100000000.00 AS 本月实际融资 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.PlanInvestmentAmount, 0)
                END) / 100000000.00 AS 本年投资拓展任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.RealInvestmentAmount, 0)
                END) / 100000000.00 AS 本年实际投资拓展 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.PlanCashFlowAmount, 0)
                END) / 100000000.00 AS 本年经营性现金流目标 ,
                -- 除地价外直投\营销费用\管理费用累计任务值   
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) <= CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ZtPlanTotal, 0)
                END) / 100000000.00 AS 累计除地价外直投任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) <= CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.SaleExpensesAmunt, 0)
                END) / 100000000.00 AS 累计营销费用任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) <= CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ManageExpensesAmunt, 0)
                END) / 100000000.00 AS 累计管理费用任务 ,
                --除地价外直投\营销费用\管理费用本年任务值
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ZtPlanTotal, 0)
                END) / 100000000.00 AS 本年除地价外直投任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.SaleExpensesAmunt, 0)
                END) / 100000000.00 AS 本年营销费用任务 ,
                SUM(
                CASE WHEN ISNULL(sbv.BudgetDimension, '年度') = '年度' AND  ISNULL(sbv.BudgetDimensionValue, CONVERT(VARCHAR(4), YEAR(GETDATE()))) = CONVERT(VARCHAR(4), YEAR(GETDATE())) THEN
                         ISNULL(sbv.ManageExpensesAmunt, 0)
                END) / 100000000.00 AS 本年管理费用任务 ,
                --除地价外直投本月任务值
                SUM(CASE WHEN sbv.BudgetDimension = '月度' AND sbv.BudgetDimensionValue = SUBSTRING(CONVERT(VARCHAR(10), GETDATE(), 23), 1, 7) THEN ISNULL(sbv.ZtPlanTotal, 0)END) / 100000000.00 AS 本月除地价外直投任务
        FROM    data_wide_dws_s_SalesBudgetVerride sbv WITH (NOLOCK)
                INNER JOIN dbo.data_wide_dws_mdm_Project b WITH (NOLOCK) ON sbv.OrganizationGUID = b.ProjGUID
        WHERE   b.buguid IN ('4EB64056-C30D-486A-BF5B-FC3BE0A52939')
        GROUP BY b.ProjGUID ,
                 b.SpreadName;

        --华南取平台公司填报版本
        SELECT  a.[ProjGUID] ,
                a.[ProjName] ,
                a.[Year] ,
                [Month] ,
                YearJaInvestmentAmount ,
                [InvestmentAmountTotal] ,
                [LoanBalanceTotal] ,
                [CollectionAmountTotal] ,
                [DirectInvestmentTotal] ,
                [LandCostTotal] ,
                [TaxTotal] ,
                [ExpenseTotal] ,    -- 累计三费
                [YearInvestmentAmount] ,
                [YearLoanBalance] ,
                [YearCollectionAmount] ,
                [YearDirectInvestment] ,
                [YearLandCost] ,
                [YearTax] ,
                [YearExpense] ,     -- 本年三费
                [MonthInvestmentAmount] ,
                [MonthLoanBalance] ,
                [MonthCollectionAmount] ,
                [MonthDirectInvestment] ,
                [MonthLandCost] ,
                [MonthTax] ,
                [MonthExpense] ,    --本月三费
                [YearNetIncreaseLoan] ,
                [MonthNetIncreaseLoan]
        INTO    #data_wide_dws_ys_ys_DssCashFlowData
        FROM    data_wide_dws_ys_ys_DssCashFlowData a WITH (NOLOCK)
                INNER JOIN data_wide_dws_mdm_Project mp WITH (NOLOCK) ON mp.ProjGUID = a.ProjGUID
        WHERE   -- mp.buguid  NOT IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', 'B2770421-F2D0-421C-B210-E6C7EF71B270')
		         mp.buguid  NOT IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' , 'B2770421-F2D0-421C-B210-E6C7EF71B270' )
                AND a.VersionGUID = (SELECT TOP 1   VersionGUID
                                     FROM   dbo.data_wide_dws_ys_ys_DssCashFlowData cf WITH (NOLOCK)
                                            INNER JOIN data_wide_dws_mdm_Project p WITH (NOLOCK) ON p.ProjGUID = cf.ProjGUID
                                     WHERE  p.BUGUID NOT IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', 'B2770421-F2D0-421C-B210-E6C7EF71B270' )
                                     GROUP BY VersionGUID ,
                                              Year ,
                                              CONVERT(INT, Month)
                                     HAVING SUM(DirectInvestmentTotal) > 0
                                     ORDER BY Year DESC ,
                                              CONVERT(INT, Month) DESC);

        --平台公司填报版本
        --获取平台公司填报版现金流的最新填报年月
        SELECT  t.BUGUID ,
                Year ,
                t.Month
        INTO    #company_confi
        FROM(SELECT ROW_NUMBER() OVER (PARTITION BY t.BUGUID ORDER BY t.Year DESC, CONVERT(INT, t.Month) DESC) AS num ,
                    t.BUGUID ,
                    t.Year ,
                    t.Month
             FROM   (SELECT pj.BUGUID ,
                            sc.Year ,
                            sc.Month
                     FROM   data_wide_dws_ys_DssCashFlowDataCompany sc WITH (NOLOCK)
                            INNER JOIN dbo.data_wide_dws_mdm_Project pj WITH (NOLOCK) ON pj.ProjGUID = sc.ProjGUID
                     GROUP BY pj.BUGUID ,
                              sc.Year ,
                              sc.Month
                     HAVING SUM(sc.InvestmentAmountTotal) > 0) t ) t
        WHERE   num = 1;

        SELECT  dc.*
        INTO    #data_wide_dws_ys_DssCashFlowDataCompany
        FROM    dbo.data_wide_dws_ys_DssCashFlowDataCompany dc WITH (NOLOCK)
                INNER JOIN dbo.data_wide_dws_mdm_Project pj WITH (NOLOCK) ON pj.ProjGUID = dc.ProjGUID
                INNER JOIN #company_confi con ON con.BUGUID = pj.buguid AND dc.Year = con.Year AND dc.Month = con.Month
        WHERE   --pj.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF', 'B2770421-F2D0-421C-B210-E6C7EF71B270');
		pj.BUGUID IN ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' , 'B2770421-F2D0-421C-B210-E6C7EF71B270' );

        /*--更新华南公司的贷款数据
        UPDATE  zb
        SET zb.LoanBalanceTotal = pt.LoanBalanceTotal ,
            zb.YearLoanBalance = pt.YearLoanBalance ,
            zb.MonthLoanBalance = pt.MonthLoanBalance ,
            zb.YearNetIncreaseLoan = pt.YearNetIncreaseLoan ,
            zb.MonthNetIncreaseLoan = pt.MonthNetIncreaseLoan
        FROM    #data_wide_dws_ys_ys_DssCashFlowData zb
                INNER JOIN #data_wide_dws_ys_DssCashFlowDataCompany pt ON zb.ProjGUID = pt.ProjGUID AND zb.Year = pt.year AND  zb.Month = pt.Month;*/

        -- 将华南公司和山西的现金流数据插入临时表
        INSERT INTO #data_wide_dws_ys_ys_DssCashFlowData([ProjGUID], [ProjName], [Year], [Month], YearJaInvestmentAmount, [InvestmentAmountTotal], [LoanBalanceTotal], [CollectionAmountTotal] ,
                                                         [DirectInvestmentTotal] , [LandCostTotal], [TaxTotal], [ExpenseTotal], [YearInvestmentAmount], [YearLoanBalance], [YearCollectionAmount] ,
                                                         [YearDirectInvestment] , [YearLandCost], [YearTax], [YearExpense], [MonthInvestmentAmount], [MonthLoanBalance], [MonthCollectionAmount] ,
                                                         [MonthDirectInvestment] , [MonthLandCost], [MonthTax], [MonthExpense], [YearNetIncreaseLoan], [MonthNetIncreaseLoan])
        SELECT  [ProjGUID] ,
                [ProjName] ,
                [Year] ,
                [Month] ,
                YearJaInvestment ,
                [InvestmentAmountTotal] ,
                [LoanBalanceTotal] ,
                [CollectionAmountTotal] ,
                [DirectInvestmentTotal] ,
                [LandCostTotal] ,
                [TaxTotal] ,
                [ExpenseTotal] ,    -- 累计三费
                [YearInvestmentAmount] ,
                [YearLoanBalance] ,
                [YearCollectionAmount] ,
                [YearDirectInvestment] ,
                [YearLandCost] ,
                [YearTax] ,
                [YearExpense] ,     -- 本年三费
                [MonthInvestmentAmount] ,
                [MonthLoanBalance] ,
                [MonthCollectionAmount] ,
                [MonthDirectInvestment] ,
                [MonthLandCost] ,
                [MonthTax] ,
                [MonthExpense] ,    --本月三费
                [YearNetIncreaseLoan] ,
                [MonthNetIncreaseLoan]
        FROM    #data_wide_dws_ys_DssCashFlowDataCompany;

        --直投情况
        SELECT  pj.ProjGUID AS orgguid ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearDirectInvestment, 0) - ISNULL(dd.YearLandCost, 0)ELSE 0 END) / 10000 AS 本年实际直接投资 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearJaInvestmentAmount, 0)ELSE 0 END) / 10000 AS 本年除地价外直投 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthDirectInvestment, 0) - ISNULL(dd.MonthLandCost, 0)ELSE 0 END) / 10000 AS 本月实际直接投资 ,
                SUM(ISNULL(CollectionAmountTotal, 0) + ISNULL(LoanBalanceTotal, 0) - ISNULL(DirectInvestmentTotal, 0) - ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) / 10000.00 AS 累计股东投资回收金额 ,
                SUM(ISNULL(CollectionAmountTotal, 0) - ISNULL(DirectInvestmentTotal, 0) - ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) / 10000.00 AS 累计实际经营性现金流 ,
                SUM(ISNULL(InvestmentAmountTotal, 0)) / 10000.00 AS 累计总投资金额 ,
                SUM(ISNULL(LoanBalanceTotal, 0)) / 10000.00 AS 累计贷款余额 ,
                SUM(ISNULL(CollectionAmountTotal, 0)) / 10000.00 AS 累计回笼金额 ,
                SUM(ISNULL(DirectInvestmentTotal, 0)) / 10000.00 AS 累计直接投资 ,
                SUM(ISNULL(LandCostTotal, 0)) / 10000.00 AS 累计直接投资土地费用 ,
                SUM(ISNULL(TaxTotal, 0)) / 10000.00 AS 累计税金 ,
                SUM(ISNULL(ExpenseTotal, 0)) / 10000.00 AS 累计三费 ,
                SUM(ISNULL(CollectionAmountTotal, 0) - ISNULL(DirectInvestmentTotal, 0) - ISNULL(ExpenseTotal, 0) - ISNULL(TaxTotal, 0)) / 10000.00 AS 累计占用集团资金 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearCollectionAmount, 0) - ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0) - ISNULL(YearExpense, 0)ELSE 0 END) / 10000.00 本年经营性现金流 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearCollectionAmount, 0)ELSE 0 END) / 10000.00 本年回笼 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearInvestmentAmount, 0)ELSE 0 END) / 10000.00 本年总投 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearLandCost, 0)ELSE 0 END) / 10000.00 本年地价 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearDirectInvestment, 0)ELSE 0 END) / 10000.00 AS 本年累计直接投资 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearTax, 0)ELSE 0 END) / 10000.00 AS 本年税金 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearExpense, 0)ELSE 0 END) / 10000.00 AS 本年三费 ,
                SUM(
                CASE WHEN Year = YEAR(GETDATE()) THEN
                         ISNULL(YearCollectionAmount, 0) + ISNULL(dd.YearNetIncreaseLoan, 0) - ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0) - ISNULL(YearExpense, 0)
                     ELSE 0
                END) / 10000.00 AS 本年股东投资回收金额 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearNetIncreaseLoan, 0)ELSE 0 END) / 10000.00 AS 本年贷款金额 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(YearCollectionAmount, 0) - ISNULL(YearDirectInvestment, 0) - ISNULL(YearTax, 0) - ISNULL(YearExpense, 0)ELSE 0 END) / 10000.00 AS 本年占用集团资金 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthCollectionAmount, 0) - ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0) - ISNULL(MonthExpense, 0)ELSE 0 END) / 10000.00 本月经营性现金流 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthCollectionAmount, 0)ELSE 0 END) / 10000.00 本月回笼 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthInvestmentAmount, 0)ELSE 0 END) / 10000.00 本月总投 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthLandCost, 0)ELSE 0 END) / 10000.00 本月地价 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthDirectInvestment, 0)ELSE 0 END) / 10000.00 AS 本月累计直接投资 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthTax, 0)ELSE 0 END) / 10000.00 AS 本月税金 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthExpense, 0)ELSE 0 END) / 10000.00 AS 本月三费 ,
                SUM(
                CASE WHEN Year = YEAR(GETDATE()) THEN
                         ISNULL(MonthCollectionAmount, 0) + ISNULL(dd.MonthNetIncreaseLoan, 0) - ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0) - ISNULL(MonthExpense, 0)
                     ELSE 0
                END) / 10000.00 AS 本月股东投资回收金额 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthNetIncreaseLoan, 0)ELSE 0 END) / 10000.00 AS 本月贷款金额 ,
                SUM(CASE WHEN Year = YEAR(GETDATE()) THEN ISNULL(MonthCollectionAmount, 0) - ISNULL(MonthDirectInvestment, 0) - ISNULL(MonthTax, 0) - ISNULL(MonthExpense, 0)ELSE 0 END) / 10000.00 AS 本月占用集团资金
        INTO    #t1
        FROM    dbo.data_wide_dws_mdm_Project pj WITH (NOLOCK)
                LEFT JOIN #data_wide_dws_ys_ys_DssCashFlowData dd ON dd.ProjGUID = pj.ProjGUID
        GROUP BY pj.ProjGUID;

        --获取结果集
        SELECT  ISNULL(ch.afterGuid, do.BUGUID) AS 公司Guid ,
                do1.ParentOrganizationGUID AS parentBuguid ,
                CASE WHEN do.XMSSCSGSGUID IS NULL THEN do.buguid ELSE do.XMSSCSGSGUID END AS buguid ,   --上级可能是项目部/区域公司/平台公司
                do.ProjGUID ,
                do.SpreadName AS 项目名称 ,
                ISNULL(tt.本年直投任务, 0) AS 本年直投任务 ,
                CASE WHEN do.buguid IN ('9AA7F9BA-4A45-496F-9C5A-5AFF26F561D8', 'A7AA464A-9D27-4319-9C74-53EBACDF9F11', '4EB64056-C30D-486A-BF5B-FC3BE0A52939') THEN ISNULL(t1.本年实际直接投资, 0)
                     ELSE ISNULL(t1.本年实际直接投资, 0) + ISNULL(zt.本月实际直接投资, 0)
                END AS 本年实际直接投资 ,
                CASE WHEN ISNULL(tt.本年直投任务, 0) = 0 THEN 0
                     ELSE CASE WHEN do.buguid IN ('9AA7F9BA-4A45-496F-9C5A-5AFF26F561D8', 'A7AA464A-9D27-4319-9C74-53EBACDF9F11', '4EB64056-C30D-486A-BF5B-FC3BE0A52939') THEN ISNULL(t1.本年实际直接投资, 0)
                               ELSE ISNULL(t1.本年实际直接投资, 0) + ISNULL(zt.本月实际直接投资, 0)
                          END * 1.00 / ISNULL(tt.本年直投任务, 0)
                END AS 本年直投达成率 ,
                ISNULL(tt.本月直投任务, 0) AS 本月直投任务 ,
                CASE WHEN do.buguid IN ('9AA7F9BA-4A45-496F-9C5A-5AFF26F561D8', 'A7AA464A-9D27-4319-9C74-53EBACDF9F11', '4EB64056-C30D-486A-BF5B-FC3BE0A52939') THEN ISNULL(t1.本月实际直接投资, 0)
                     ELSE ISNULL(zt.本月实际直接投资, 0)
                END AS 本月实际直接投资 ,
                CASE WHEN ISNULL(tt.本月直投任务, 0) = 0 THEN 0
                     ELSE CASE WHEN do.buguid IN ('9AA7F9BA-4A45-496F-9C5A-5AFF26F561D8', 'A7AA464A-9D27-4319-9C74-53EBACDF9F11', '4EB64056-C30D-486A-BF5B-FC3BE0A52939') THEN ISNULL(t1.本月实际直接投资, 0)
                               ELSE ISNULL(zt.本月实际直接投资, 0)
                          END * 1.00 / ISNULL(tt.本月直投任务, 0)
                END AS 本月直投达成率 ,
                ISNULL(tt.本年融资任务, 0) AS 本年融资任务 ,
                ISNULL(tt.本年实际融资, 0) AS 本年实际融资 ,
                CASE WHEN ISNULL(tt.本年融资任务, 0) = 0 THEN 0 ELSE ISNULL(tt.本年实际融资, 0) * 1.0 / ISNULL(tt.本年融资任务, 0)END 本年融资达成率 ,
                ISNULL(tt.本月融资任务, 0) AS 本月融资任务 ,
                ISNULL(tt.本月实际融资, 0) AS 本月实际融资 ,
                CASE WHEN ISNULL(tt.本月融资任务, 0) = 0 THEN 0 ELSE ISNULL(tt.本月实际融资, 0) * 1.0 / ISNULL(tt.本月融资任务, 0)END 本月融资达成率 ,
                ISNULL(tt.本年投资拓展任务, 0) AS 本年拓展任务 ,
                ISNULL(tt.本年实际投资拓展, 0) AS 本年实际拓展 ,
                CASE WHEN ISNULL(tt.本年投资拓展任务, 0) = 0 THEN 0 ELSE ISNULL(tt.本年实际投资拓展, 0) * 1.0 / ISNULL(tt.本年投资拓展任务, 0)END 本年拓展达成率 ,
                ISNULL(t1.累计股东投资回收金额, 0) AS 累计股东投资回收金额 ,
                ISNULL(t1.累计实际经营性现金流, 0) AS 累计实际经营性现金流 ,
                ISNULL(t1.累计总投资金额, 0) AS 累计总投资金额 ,
                ISNULL(t1.累计贷款余额, 0) AS 累计贷款余额 ,
                ISNULL(t1.累计回笼金额, 0) AS 累计回笼金额 ,
                ISNULL(t1.累计直接投资, 0) AS 累计直接投资 ,
                ISNULL(t1.累计直接投资土地费用, 0) AS 累计直接投资土地费用 ,
                ISNULL(t1.累计税金, 0) AS 累计税金 ,
                ISNULL(t1.累计三费, 0) AS 累计三费 ,
                ISNULL(t1.累计占用集团资金, 0) AS 累计占用集团资金 ,
                ISNULL(t1.本年经营性现金流, 0) AS 本年经营性现金流 ,
                ISNULL(t1.本年回笼, 0) AS 本年回笼 ,
                ISNULL(t1.本年总投, 0) AS 本年总投 ,
                ISNULL(t1.本年地价, 0) AS 本年地价 ,
                ISNULL(t1.本年累计直接投资, 0) AS 本年累计直接投资 ,
                ISNULL(t1.本年税金, 0) AS 本年税金 ,
                ISNULL(t1.本年三费, 0) AS 本年三费 ,
                ISNULL(t1.本年股东投资回收金额, 0) AS 本年股东投资回收金额 ,
                ISNULL(t1.本年贷款金额, 0) AS 本年贷款金额 ,
                ISNULL(t1.本年占用集团资金, 0) AS 本年占用集团资金 ,
                ISNULL(t1.本月经营性现金流, 0) AS 本月经营性现金流 ,
                ISNULL(t1.本月回笼, 0) AS 本月回笼 ,
                ISNULL(t1.本月总投, 0) AS 本月总投 ,
                ISNULL(t1.本月地价, 0) AS 本月地价 ,
                ISNULL(t1.本月累计直接投资, 0) AS 本月累计直接投资 ,
                ISNULL(t1.本月税金, 0) AS 本月税金 ,
                ISNULL(t1.本月三费, 0) AS 本月三费 ,
                ISNULL(t1.本月股东投资回收金额, 0) AS 本月股东投资回收金额 ,
                ISNULL(t1.本月贷款金额, 0) AS 本月贷款金额 ,
                ISNULL(t1.本月占用集团资金, 0) AS 本月占用集团资金 ,
                ISNULL(t1.本年实际直接投资, 0) AS 本年实际除地价外直投 ,                                                  --除地价外直投
                ISNULL(t1.累计直接投资, 0) - ISNULL(t1.累计直接投资土地费用, 0) AS 累计实际除地价外直投 ,
                ISNULL(tt.本年经营性现金流目标, 0) AS 本年经营性现金流目标 ,
                                                                                                        --添加
                ISNULL(t1.本月实际直接投资, 0) AS 本月实际除地价外直投 ,                                                  --除地价外直投
                ISNULL(tt.累计除地价外直投任务, 0) AS 累计除地价外直投任务 ,
                ISNULL(tt.本年除地价外直投任务, 0) AS 本年除地价外直投任务 ,
                ISNULL(tt.本月除地价外直投任务, 0) AS 本月除地价外直投任务 ,
                ISNULL(tt.累计营销费用任务, 0) AS 累计营销费用任务 ,
                ISNULL(tt.本年营销费用任务, 0) AS 本年营销费用任务 ,
                ISNULL(tt.累计管理费用任务, 0) AS 累计管理费用任务 ,
                ISNULL(tt.本年管理费用任务, 0) AS 本年管理费用任务 ,
                CASE WHEN ISNULL(tt.累计除地价外直投任务, 0) = 0 THEN 0 ELSE (ISNULL(t1.累计直接投资, 0) - ISNULL(t1.累计直接投资土地费用, 0)) * 1.0 / ISNULL(tt.累计除地价外直投任务, 0)END 累计除地价外直投达成率 ,
                CASE WHEN ISNULL(tt.本年除地价外直投任务, 0) = 0 THEN 0 ELSE ISNULL(t1.本年实际直接投资, 0) * 1.0 / ISNULL(tt.本年除地价外直投任务, 0)END 本年除地价外直投达成率 ,
                CASE WHEN ISNULL(tt.本月除地价外直投任务, 0) = 0 THEN 0 ELSE ISNULL(t1.本月实际直接投资, 0) * 1.0 / ISNULL(tt.本月除地价外直投任务, 0)END 本月除地价外直投达成率 ,
                ISNULL(t1.本年除地价外直投, 0) AS 本年除地价外直投_建安
        INTO    #res
        FROM    dbo.data_wide_dws_mdm_Project do WITH (NOLOCK)
                LEFT JOIN #t_task tt ON tt.OrgGUID = do.projguid
                LEFT JOIN #t1 t1 ON t1.orgguid = do.projguid
                LEFT JOIN(
                          SELECT    pj.ParentGUID AS buguid ,
                                    SUM(CFAmont) * 1.0 / 100000000.00 AS 本月实际直接投资
                          FROM  data_wide_cb_bizbill cb WITH (NOLOCK)
                                INNER JOIN dbo.data_wide_dws_mdm_Project pj WITH (NOLOCK) ON cb.ProjGUID = pj.ProjGUID
                                LEFT JOIN dbo.data_wide_dws_s_Dimension_Organization do WITH (NOLOCK) ON do.OrgGUID = pj.XMSSCSGSGUID
                          WHERE BillType = '付款登记' AND  DATEDIFF(mm, BillDate, GETDATE()) = 0
                                AND   (CostCode NOT LIKE '5001.01%' AND   CostCode NOT LIKE '5001.09%' AND CostCode NOT LIKE '5001.10%' AND   CostCode NOT LIKE '5001.11%')
                          GROUP BY pj.ParentGUID
                         ) zt ON zt.buguid = do.projguid
                LEFT JOIN dbo.data_wide_dws_s_Dimension_Organization do1 WITH (NOLOCK) ON do1.OrgGUID = do.XMSSCSGSGUID AND  t1.orgguid = do1.orgguid --20210927加上do1与#t1表做关联，不然数据重复
                LEFT JOIN s_rptzjlkb_OrgInfo_chg ch WITH (NOLOCK) ON ch.beforeGuid = do.BUGUID    --公司合并
        WHERE   do.Level = 2;

        DELETE  FROM s_rptzjlkb_CashFlowInfoProj;

        INSERT INTO s_rptzjlkb_CashFlowInfoProj
        SELECT  t.* ,
                sc.累计经营性现金流_四川 ,
                sc.累计股东回收金额_四川 ,
                sc.累计权益经营性现金流_四川 ,
                sc.本年经营性现金流_四川 ,
                sc.本年股东回收金额_四川 ,
                sc.本年权益经营性现金流_四川
        FROM    #res t
                LEFT JOIN(
                           SELECT    项目guid ,
                                    SUM(ISNULL(累计经营性现金流, 0)) / 10000.0 AS 累计经营性现金流_四川 ,
                                    SUM(ISNULL(累计股东回收金额, 0)) / 10000.0 AS 累计股东回收金额_四川 ,
                                    SUM(ISNULL(累计权益经营性现金流, 0)) / 10000.0 AS 累计权益经营性现金流_四川 ,
                                    SUM(ISNULL(本年经营性现金流, 0)) / 10000.0 AS 本年经营性现金流_四川 ,
                                    SUM(ISNULL(本年股东回收金额, 0)) / 10000.0 AS 本年股东回收金额_四川 ,
                                    SUM(ISNULL(本年权益经营性现金流, 0)) / 10000.0 AS 本年权益经营性现金流_四川
                           FROM  data_tb_projxjl_sichuan WITH (NOLOCK)
                           GROUP BY 项目guid
                         ) sc ON t.ProjGUID = sc.项目guid;

        SELECT  * FROM  s_rptzjlkb_CashFlowInfoProj WITH (NOLOCK);

        --删掉临时表
        DROP TABLE #t1;
        DROP TABLE #t_task ,
                   #res ,
                   #company_confi ,
                   #data_wide_dws_ys_DssCashFlowDataCompany ,
                   #data_wide_dws_ys_ys_DssCashFlowData;
    END;
