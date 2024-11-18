
          WITH StageAccount AS (
					SELECT bb.ProjGUID,aa.StageAccountGUID AS CostGUID 
					FROM dbo.cb_StageAccount aa  WITH (NOLOCK)
					INNER JOIN (
						SELECT ProjGUID,AccountCode FROM dbo.cb_StageAccount WITH (NOLOCK) WHERE AccountShortName IN ('室外工程费','建筑安装工程费','公共配套设施费','销售设施建造费') AND ProjGUID=@ProjGUID
					) bb ON aa.AccountCode LIKE ''+ bb.AccountCode +'%' AND aa.ProjGUID = bb.ProjGUID
				),
				DesignAlterApply AS (
					SELECT c.ProjGUID,a.AlterGUID,a.ContractGUID,a.ApplyAmount_Bz,a.ApproveAmount_Bz,b.x_ConfirmMonitorLightsStateEnum,b.CreatedTime,b.ReportDate
					FROM dbo.cb_DesignAlterApplyToContract a WITH (NOLOCK)
					INNER JOIN dbo.cb_DesignAlterApply b WITH (NOLOCK) ON a.AlterGUID = b.AlterGUID
					INNER JOIN dbo.cb_DesignAlterApplyProj c WITH (NOLOCK) ON b.AlterGUID = c.ApplyGUID
					WHERE b.ApproveStateEnum = 3
				), 
				DesignAlterCostConfirm AS (
					SELECT b.ProjGUID,a.AlterGUID,a.ContractGUID,a.Amount_Bz,a.ValidationAmount_Bz,b.CreatedTime,a.SignDate
					FROM dbo.cb_DesignAlterCostConfirm a WITH (NOLOCK)
					INNER JOIN dbo.cb_DesignAlterApplyProj b WITH (NOLOCK) ON a.AlterGUID = b.ApplyGUID
					WHERE a.ApproveStateEnum = 3
				),
				LocaleAlterApply AS (
					SELECT c.ProjGUID,a.AlterGUID,a.ContractGUID,a.ApplyAmount_Bz,a.ApproveAmount_Bz,b.x_ConfirmMonitorLightsStateEnum,b.CreatedTime,b.ReportDate 
					FROM dbo.cb_LocaleAlterApplyToContract a WITH (NOLOCK)
					INNER JOIN dbo.cb_LocaleAlterApply b WITH (NOLOCK) ON a.AlterGUID = b.AlterGUID
					INNER JOIN dbo.cb_LocaleAlterApplyProj c WITH (NOLOCK) ON b.AlterGUID = c.ApplyGUID
					WHERE b.ApproveStateEnum = 3
				),
				LocaleAlterCostConfirm AS (
					SELECT b.ProjGUID,a.AlterGUID,a.ContractGUID,a.Amount_Bz,a.ValidationAmount_Bz,b.CreatedTime,a.SignDate 
					FROM dbo.cb_LocaleAlterCostConfirm a WITH (NOLOCK) 
					INNER JOIN dbo.cb_LocaleAlterApplyProj b WITH (NOLOCK) ON a.AlterGUID = b.ApplyGUID
					WHERE a.ApproveStateEnum = 3
				) ,
				CbContract AS (
					SELECT a.ProjGUID,b.ContractGUID,b.TotalAmount,b.SignDate 
					FROM dbo.cb_ContractProj a WITH (NOLOCK)
					INNER JOIN dbo.cb_Contract b WITH (NOLOCK) ON a.ContractGUID = b.ContractGUID
					WHERE b.ApproveStateEnum = 3
				),
				--设计变更合同
				DesignAlterContract AS (
					SELECT aa.ContractGUID 
					FROM dbo.cb_DesignAlterApplyToContract aa
					INNER JOIN (
						SELECT c.AlterGUID 
						FROM dbo.cb_DesignAlterApplyBudgetUse a WITH (NOLOCK)
						INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
						INNER JOIN dbo.cb_DesignAlterApply c WITH (NOLOCK) ON a.AlterGUID = c.AlterGUID
						INNER JOIN dbo.cb_DesignAlterApplyProj d WITH (NOLOCK) ON c.AlterGUID = d.ApplyGUID
						WHERE c.ApproveStateEnum = 3 AND d.ProjGUID=@ProjGUID
						GROUP BY c.AlterGUID
					) bb ON aa.AlterGUID = bb.AlterGUID
					GROUP BY aa.ContractGUID
				),
				--现场签证合同
				LocaleAlterContract AS (
					SELECT aa.ContractGUID 
					FROM dbo.cb_LocaleAlterApplyToContract aa
					INNER JOIN (
						SELECT c.AlterGUID 
						FROM dbo.cb_LocaleAlterApplyBudgetUse a WITH (NOLOCK)
						INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
						INNER JOIN dbo.cb_LocaleAlterApply c WITH (NOLOCK) ON a.AlterGUID = c.AlterGUID
						INNER JOIN dbo.cb_LocaleAlterApplyProj d WITH (NOLOCK) ON c.AlterGUID = d.ApplyGUID
						WHERE c.ApproveStateEnum = 3 AND d.ProjGUID=@ProjGUID
						GROUP BY c.AlterGUID
					) bb ON aa.AlterGUID = bb.AlterGUID
					GROUP BY aa.ContractGUID
				),
				ContractAllAlter AS (
					SELECT @ProjGUID AS ProjGUID,(
						--如果【存在已审核的完工确认】则取【完工确认归集对应科目 归集金额】 否则取【归集对应科目 归集金额】
						SELECT ISNULL(SUM(CASE WHEN bbb.AlterGUID IS NOT NULL THEN bbb.CfAmount ELSE aaa.CfAmount END),0)
						FROM (
							--设计变更
							SELECT e.ContractGUID,c.AlterGUID,c.AlterItemConfirmState,SUM(a.CfAmount) CfAmount 
							FROM dbo.cb_DesignAlterApplyBudgetUse a WITH (NOLOCK)
							INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
							INNER JOIN dbo.cb_DesignAlterApply c WITH (NOLOCK) ON a.AlterGUID = c.AlterGUID
							INNER JOIN dbo.cb_DesignAlterApplyProj d WITH (NOLOCK) ON c.AlterGUID = d.ApplyGUID
									LEFT JOIN dbo.cb_DesignAlterApplyToContract e  WITH(NOLOCK) ON a.AlterGUID = e.AlterGuid
                                                    AND a.ContractGUID = e.ContractGUID
							WHERE c.ApproveStateEnum = 3 AND d.ProjGUID=@ProjGUID
							GROUP BY c.AlterGUID,c.AlterItemConfirmState,e.ContractGUID
						) aaa 
						LEFT JOIN (
							--设计变更完工确认
							SELECT e.ContractGUID,c.AlterGUID,SUM(a.CfAmount) CfAmount
							FROM dbo.cb_DesignAlterCostConfirmBudgetUse a WITH (NOLOCK)
							INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
							INNER JOIN dbo.cb_DesignAlterCostConfirm c WITH (NOLOCK) ON a.AlterGUID = c.AlterZjspGUID
									LEFT JOIN dbo.cb_DesignAlterApplyToContract e  WITH(NOLOCK) ON c.AlterGUID = e.AlterGuid
                                                    AND c.ContractGUID = e.ContractGUID
							WHERE c.ApproveStateEnum  = 3
							GROUP BY c.AlterGUID,e.ContractGUID
						) bbb ON aaa.AlterGUID = bbb.AlterGUID AND bbb.ContractGUID = aaa.ContractGUID
					) AS DesignAlterAmount,
					(
						SELECT ISNULL(SUM(u.CfAmount),0) FROM DesignAlterContract a INNER JOIN dbo.cb_Contract b WITH(NOLOCK) ON a.ContractGUID = b.ContractGUID
						INNER JOIN ( SELECT us.CfAmount,us.ContractGUID FROM  dbo.cb_BudgetUseContract us WITH(NOLOCK) INNER JOIN StageAccount s ON s.CostGUID=us.CostGUID ) u ON u.ContractGUID=a.ContractGUID AND u.ContractGUID=b.ContractGUID
					)
					+
					(
						SELECT ISNULL(SUM(u.CfAmount),0) FROM DesignAlterContract a INNER JOIN dbo.cb_BcContract b WITH(NOLOCK) ON a.ContractGUID = b.MasterContractGUID and  b.SupTypeEnum <> 2 AND b.ApproveStateEnum = 3 
						INNER JOIN ( SELECT us.CfAmount,us.ContractGUID,us.BcContractGUID FROM  dbo.cb_BudgetUseBcContract us WITH(NOLOCK) INNER JOIN StageAccount s ON s.CostGUID=us.CostGUID ) u ON u.ContractGUID=a.ContractGUID   AND u.BcContractGUID=b.BcContractGUID
					) AS DesignAlterContractAmount,
					(
						--补协（不含变更转补协）
						SELECT ISNULL(SUM(a.CfAmount),0) FROM dbo.cb_BudgetUseBcContract a WITH (NOLOCK)
						INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
						INNER JOIN dbo.cb_BcContract c WITH (NOLOCK) ON a.BcContractGUID = c.BcContractGUID
						INNER JOIN dbo.cb_BcContractProj d WITH (NOLOCK) ON c.BcContractGUID = d.BcContractGUID
						WHERE c.SupTypeEnum <> 2 AND c.ApproveStateEnum = 3 AND d.ProjGUID=@ProjGUID
					) AS Alter2BcContractAmount,
					(
						--如果【存在已审核的完工确认】则取【完工确认归集对应科目 归集金额】 否则取【归集对应科目 归集金额】
						SELECT ISNULL(SUM(CASE WHEN bbb.AlterGUID IS NOT NULL THEN bbb.CfAmount ELSE aaa.CfAmount END),0)
						FROM (
							--现场签证
							SELECT c.AlterGUID,c.AlterItemConfirmState,SUM(a.CfAmount) CfAmount 
							FROM dbo.cb_LocaleAlterApplyBudgetUse a WITH (NOLOCK)
							INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
							INNER JOIN dbo.cb_LocaleAlterApply c WITH (NOLOCK) ON a.AlterGUID = c.AlterGUID
							INNER JOIN dbo.cb_LocaleAlterApplyProj d WITH (NOLOCK) ON c.AlterGUID = d.ApplyGUID
							WHERE c.ApproveStateEnum = 3 AND d.ProjGUID=@ProjGUID
							GROUP BY c.AlterGUID,c.AlterItemConfirmState
						) aaa 
						LEFT JOIN (
							--现场签证完工确认
							SELECT c.AlterGUID,SUM(a.CfAmount) CfAmount
							FROM dbo.cb_LocaleAlterCostConfirmBudgetUse a WITH (NOLOCK)
							INNER JOIN StageAccount b WITH (NOLOCK) ON a.CostGUID = b.CostGUID
							INNER JOIN dbo.cb_LocaleAlterCostConfirm c WITH (NOLOCK) ON a.AlterGUID = c.AlterZjspGUID
							WHERE c.ApproveStateEnum  = 3
							GROUP BY c.AlterGUID
						) bbb ON aaa.AlterGUID = bbb.AlterGUID
					) AS LocaleAlterAmount,
					(
						SELECT ISNULL(SUM(u.CfAmount),0) FROM LocaleAlterContract a INNER JOIN dbo.cb_Contract b WITH(NOLOCK) ON a.ContractGUID = b.ContractGUID
						INNER JOIN ( SELECT us.CfAmount,us.ContractGUID FROM  dbo.cb_BudgetUseContract us WITH(NOLOCK) INNER JOIN StageAccount s ON s.CostGUID=us.CostGUID ) u ON u.ContractGUID=a.ContractGUID  AND u.ContractGUID=b.ContractGUID
					)
					+
					(
						SELECT ISNULL(SUM(u.CfAmount),0) FROM LocaleAlterContract a WITH (NOLOCK) INNER JOIN dbo.cb_BcContract b WITH (NOLOCK) ON a.ContractGUID = b.MasterContractGUID and  b.SupTypeEnum <> 2 AND b.ApproveStateEnum = 3 
						INNER JOIN ( SELECT us.CfAmount,us.ContractGUID,us.BcContractGUID FROM  dbo.cb_BudgetUseBcContract us WITH (NOLOCK) INNER JOIN StageAccount s ON s.CostGUID=us.CostGUID ) u ON u.ContractGUID=a.ContractGUID   AND u.BcContractGUID=b.BcContractGUID
					) AS LocaleAlterContractAmount,
					(
						SELECT ISNULL(SUM(b.HtAmount_Bz),0) FROM dbo.cb_ContractProj a WITH (NOLOCK) 
						INNER JOIN dbo.cb_Contract b WITH (NOLOCK) ON a.ContractGUID = b.ContractGUID
						WHERE b.ApproveStateEnum = 3 AND a.ProjGUID=@ProjGUID
					) 
					+
					(
						SELECT ISNULL(SUM(b.HtAmount_Bz),0) FROM dbo.cb_BcContractProj a WITH (NOLOCK)
						INNER JOIN dbo.cb_BcContract b WITH (NOLOCK) ON a.BcContractGUID = b.BcContractGUID
						WHERE b.SupTypeEnum <> 2 AND b.ApproveStateEnum = 3 AND a.ProjGUID=@ProjGUID
					)
					AS ContractAmount,
					(
						SELECT ISNULL(SUM(u.CfAmount),0) FROM cb_Contract a WITH (NOLOCK)
						INNER JOIN dbo.cb_BudgetUseContract u WITH (NOLOCK) ON a.ContractGUID=u.ContractGUID AND u.ProjectGUID=@ProjGUID
						INNER JOIN StageAccount s ON s.CostGUID=u.CostGUID
						INNER JOIN (
							SELECT aa.ContractGUID FROM (
								SELECT a.ContractGUID FROM LocaleAlterContract a
								UNION ALL 
								SELECT a.ContractGUID FROM DesignAlterContract a
							) aa GROUP BY ContractGUID
						) b ON a.ContractGUID = b.ContractGUID
					)
					+
					(
						SELECT ISNULL(SUM(u.CfAmount),0) FROM cb_BcContract  a WITH (NOLOCK)
						INNER JOIN dbo.cb_BudgetUseBcContract u WITH (NOLOCK) ON a.BcContractGUID=u.BcContractGUID AND u.ProjectGUID=@ProjGUID
						INNER JOIN StageAccount s ON s.CostGUID=u.CostGUID
						INNER JOIN (
							SELECT aa.ContractGUID FROM (
								SELECT a.ContractGUID FROM LocaleAlterContract a
								UNION ALL 
								SELECT a.ContractGUID FROM DesignAlterContract a
							) aa GROUP BY ContractGUID
						) b ON a.MasterContractGUID = b.ContractGUID AND a.ApproveStateEnum=3
						WHERE a.SupTypeEnum <> 2 AND a.ApproveStateEnum = 3
					)
					AS AlterContractAmount 
				)

            ---查询结果    
				SELECT 
				ContractAlter.ContractCostChangeRate,
				ContractAlter.DesignAlterRate,
				ContractAlter.LocaleAlterRate,
				--本月新增设计变更申报数量
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate GROUP BY aa.AlterGUID) g)
				ELSE
					(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.CreatedTime >= lastReview.ReviewDate GROUP BY aa.AlterGUID) g)
				END AS MonthAddDesignAlterCount,
				--本月度新增设计变更申报金额
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT SUM(aa.ApproveAmount_Bz) FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate)
				ELSE
					(SELECT SUM(aa.ApproveAmount_Bz) FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.CreatedTime >= lastReview.ReviewDate)
				END AS MonthAddDesignAlterAmount,
				--本月度新增现场签证申报数量
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate GROUP BY aa.AlterGUID) g)
				ELSE
					(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.CreatedTime >= lastReview.ReviewDate GROUP BY aa.AlterGUID) g)
				END AS MonthAddLocaleAlterCount,
				--本月度新增现场签证申报金额
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT SUM(aa.ApproveAmount_Bz) FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate)
				ELSE
					(SELECT SUM(aa.ApproveAmount_Bz) FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.CreatedTime >= lastReview.ReviewDate)
				END AS MonthAddLocalAlterAmount,
				--本月度新增完工确认
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT COUNT(0) FROM DesignAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate)
					+
					(SELECT COUNT(0) FROM LocaleAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate)
				ELSE
					(SELECT COUNT(0) FROM DesignAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate AND aa.SignDate >= lastReview.ReviewDate)
					+
					(SELECT COUNT(0) FROM LocaleAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate AND aa.SignDate >= lastReview.ReviewDate)
				END AS MonthAddCostConfirmCount,
				--本月度新增设计变更完工确认
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT COUNT(0) FROM DesignAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate)
				ELSE
					(SELECT COUNT(0) FROM DesignAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate AND aa.SignDate >= lastReview.ReviewDate)
				END AS MonthAddDesignAlterConfirmCount,
				--本月度新增现场签证完工确认
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(SELECT COUNT(0) FROM LocaleAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate)
				ELSE
					(SELECT COUNT(0) FROM LocaleAlterCostConfirm aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.SignDate <= currentReview.ReviewDate AND aa.SignDate >= lastReview.ReviewDate)
				END AS MonthAddLocalAlterConfirmCount,
				--截止本月度超期未做完工确认的合同变更
				((SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.x_ConfirmMonitorLightsStateEnum = 2 GROUP BY aa.AlterGUID) g)
				+
				(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.x_ConfirmMonitorLightsStateEnum = 2 GROUP BY aa.AlterGUID) g))
				AS OverdueNotDoneCostConfirm,
				--截止本月度超期未做完工确认的设计变更
				(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.x_ConfirmMonitorLightsStateEnum = 2 GROUP BY aa.AlterGUID) g)
				AS OverdueNotDoneDesignAlterConfirm,
				--截止本月度超期未做完工确认的现场签证
				(SELECT COUNT(0) FROM (SELECT aa.AlterGUID FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate AND aa.x_ConfirmMonitorLightsStateEnum = 2 GROUP BY aa.AlterGUID) g)
				AS OverdueNotDoneLocalAlterConfirm,
				--本月度设计变更金额超指标的合同数
					(
						SELECT COUNT(aa.ContractGUID) FROM (
							SELECT CASE WHEN (b.ApproveAmount_Bz / a.TotalAmount * 100.00) > ISNULL(dataSet.x_DesignAlterRate,3) THEN a.ContractGUID ELSE NULL END AS ContractGUID
							FROM CbContract a 
							INNER JOIN (
								SELECT aa.ContractGUID,SUM(aa.ApproveAmount_Bz) AS ApproveAmount_Bz FROM DesignAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate
								GROUP BY aa.ContractGUID
							) b ON a.ContractGUID = b.ContractGUID
              WHERE a.TotalAmount <> 0 AND a.SignDate <= currentReview.ReviewDate
						) aa WHERE aa.ContractGUID IS NOT NULL
					) AS MonthDesignAlterAmountOverdue,
				--本月度现场签证金额超指标的合同数 
					(
						SELECT COUNT(aa.ContractGUID) FROM (
							SELECT CASE WHEN (b.ApproveAmount_Bz / a.TotalAmount * 100.00) > ISNULL(dataSet.x_LocaleAlterRate,1) THEN a.ContractGUID ELSE NULL END AS ContractGUID
							FROM CbContract a 
							INNER JOIN (
								SELECT aa.ContractGUID,SUM(aa.ApproveAmount_Bz) AS ApproveAmount_Bz FROM LocaleAlterApply aa WHERE aa.ProjGUID = currentReview.ProjGUID AND aa.CreatedTime <= currentReview.ReviewDate
								GROUP BY aa.ContractGUID
							) b ON a.ContractGUID = b.ContractGUID
              WHERE a.TotalAmount <> 0 AND a.SignDate <= currentReview.ReviewDate
						) aa WHERE aa.ContractGUID IS NOT NULL
					) AS MonthLocaleAlterAmountOverdue,
				--本月签证变更超期上线数量
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(
						SELECT COUNT(0) FROM (
							SELECT a.AlterGUID FROM LocaleAlterApply a WHERE a.ProjGUID = currentReview.ProjGUID AND a.CreatedTime <= currentReview.ReviewDate AND DATEDIFF(DAY,a.ReportDate,a.CreatedTime) >  ISNULL(dataSet.x_LocaleAlterOverdueDays,30)
							GROUP BY a.AlterGUID
						) aa
					)
				ELSE 
					(
						SELECT COUNT(0) FROM (
							SELECT a.AlterGUID FROM LocaleAlterApply a WHERE a.ProjGUID = currentReview.ProjGUID AND a.CreatedTime <= currentReview.ReviewDate AND a.CreatedTime >= lastReview.ReviewDate AND DATEDIFF(DAY,a.ReportDate,a.CreatedTime) >  ISNULL(dataSet.x_LocaleAlterOverdueDays,30)
							GROUP BY a.AlterGUID
						) aa
					)
				END AS MonthLocaleAlterOverdueCount,
				--本月设计变更超期上线数量
				CASE WHEN lastReview.MonthlyReviewGUID IS NULL 
				THEN 
					(
						SELECT COUNT(0) FROM (
							SELECT a.AlterGUID FROM DesignAlterApply a WHERE a.ProjGUID = currentReview.ProjGUID AND a.CreatedTime <= currentReview.ReviewDate AND DATEDIFF(DAY,a.ReportDate,a.CreatedTime) >  ISNULL(dataSet.x_DesignAlterOverdueDays,15)
							GROUP BY a.AlterGUID
						) aa
					)
				ELSE 
					(
						SELECT COUNT(0) FROM (
							SELECT a.AlterGUID FROM DesignAlterApply a WHERE a.ProjGUID = currentReview.ProjGUID AND a.CreatedTime <= currentReview.ReviewDate AND a.CreatedTime >= lastReview.ReviewDate AND DATEDIFF(DAY,a.ReportDate,a.CreatedTime) >  ISNULL(dataSet.x_DesignAlterOverdueDays,15)
							GROUP BY a.AlterGUID
						) aa
					)
				END AS MonthDesignAlterOverdueCount
				FROM dbo.cb_MonthlyReview currentReview WITH (NOLOCK)
				LEFT JOIN dbo.cb_MonthlyReview lastReview WITH (NOLOCK) ON currentReview.LastVersionGUID = lastReview.MonthlyReviewGUID
				LEFT JOIN dbo.x_cb_DateControlSet dataSet WITH (NOLOCK) ON currentReview.BuGUID = dataSet.x_BUGUID
				LEFT JOIN (
					SELECT ContractAllAlter.ProjGUID,
					CASE WHEN AlterContractAmount = 0 THEN 0 ELSE ROUND((DesignAlterAmount +  LocaleAlterAmount) / AlterContractAmount * 100,2) END AS ContractCostChangeRate,
					CASE WHEN DesignAlterContractAmount = 0 THEN 0 ELSE ROUND(DesignAlterAmount / DesignAlterContractAmount * 100,2) END AS DesignAlterRate,
					CASE WHEN LocaleAlterContractAmount = 0 THEN 0 ELSE ROUND(LocaleAlterAmount / LocaleAlterContractAmount * 100,2) END AS LocaleAlterRate
					FROM ContractAllAlter
				) ContractAlter ON currentReview.ProjGUID = ContractAlter.ProjGUID
				WHERE currentReview.MonthlyReviewGUID=@MonthlyReviewGUID
