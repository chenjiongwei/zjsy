select  distinct --解决跨项目过程重复
        DENSE_RANK() OVER(ORDER BY ISNULL(A.BUName,''),ISNULL(A.ProjectNameList,''),
        CASE WHEN a.x_IsHistory<>'1' THEN CONVERT(char(10),d.ApproveTime,120)
		WHEN a.x_IsHistory IS NULL THEN CONVERT(char(10),d.ApproveTime,120)
		WHEN a.x_IsHistory='1' THEN CONVERT(char(10),dd.AuditDate,120) END DESC,
		A.CgSolutionGUID,VZ.CgSolutionSectionGUID
		) AS '序号',
		A.CgSolutionGUID AS '采购过程GUID',
		ISNULL(A.ProjectNameList,'') as '项目名称',
		ISNULL(A.x_CgSolutionCode,'') as '采购编号',
		ISNULL(A.SolutionName,0) as '采购过程名称',
		ISNULL(A.BUName,'') as '公司名称',
		ISNULL(A.BUName,'') AS '合同甲方',
		CASE WHEN A.CgTypeGUID='939BDC22-5049-E911-A1DD-463500000031' THEN '营销类' ELSE '工建类' END AS '类别',
		ty.[NAME] AS '采购类别',
		--A.ProviderTypeNameList AS '采购细项',
		CASE WHEN A.ProviderTypeNameList IS NULL THEN vz.ProviderTypeName ELSE A.ProviderTypeNameList END AS '采购细项',
		A.CgFormName AS '采购方式',
		CASE WHEN ISNULL(A.IsOnline,0)=1 THEN '是' ELSE '否' END AS '是否线上招标',
		ISNULL(A.AssessBidMethod,'') AS '评标方法',
		CASE WHEN ISNULL(A.TechGoalRate,0) = 0 THEN 0 ELSE ISNULL(A.TechGoalRate,0)/100 END AS '技术标评分比例',
		CASE WHEN ISNULL(A.BusinessGoalRate,0) = 0 THEN 0 ELSE ISNULL(A.BusinessGoalRate,0)/100 END AS '商务标评分比例',
		--CONVERT(char(10),b.OpenBidTime,120) AS '开标时间',
		CASE WHEN CONVERT(char(10),b.OpenBidTime,120) IS NULL THEN CONVERT(char(10),hxcg.SJWCOpenBidDate,120) ELSE CONVERT(char(10),b.OpenBidTime,120) END AS '开标时间',
		--STUFF(( SELECT DISTINCT ','+ [UserName] FROM cg_CgProcAssessBidExpert c WHERE --c.BidType=0 and 
		--c.CgSolutionGUID = a.CgSolutionGUID  FOR XML PATH('')),1 ,1, '') AS '评标专家',
		ISNULL(STUFF(( SELECT DISTINCT ','+ [UserName] FROM cg_CgProcAssessBidExpert c WHERE --c.BidType=0 and 
		c.CgSolutionGUID = a.CgSolutionGUID  FOR XML PATH('')),1 ,1, ''),
		STUFF(( SELECT DISTINCT ','+ Zrr FROM [172.16.22.29].[dotnet_erp352sp3].[dbo].cg_CgProcAssessBidZrr hxpb WHERE a.CgSolutionGUID = hxpb.CgSolutionGUID  FOR XML PATH('')),1 ,1, '')) AS '评标专家',
		ISNULL(ISNULL(b.x_LimitedPrice,hxxj.CgLimitedMoney),0) AS '限价',
        case when row_number() over(partition by A.x_CgSolutionCode order by A.x_CgSolutionCode)=1 then ISNULL(ISNULL(b.x_LimitedPrice,hxxj.CgLimitedMoney),0) else 0 end AS '限价合计',
		CASE WHEN a.x_IsHistory<>'1' THEN CONVERT(char(10),d.ApproveTime,120)
		WHEN a.x_IsHistory IS NULL THEN CONVERT(char(10),d.ApproveTime,120)
		WHEN a.x_IsHistory='1' THEN CONVERT(char(10),dd.AuditDate,120) END AS '定标时间',
		--CONVERT(char(10),e.modifiedTime,120) as '中标通知时间',
		null as '中标通知时间',
		null as '合同签订时间',
		ISNULL(WinPrice,0) AS '合同金额',
		vb.[Name] as '标段',
		vz.[Name] as '竞投单位',
		--ISNULL(b2.ReturnBidIP,'') as '回标IP',
		CASE WHEN b2.ReturnBidIP IS NULL THEN hxhb.ProviderReturnBidIP ELSE b2.ReturnBidIP END as '回标IP',
		ISNULL(ISNULL(b2.ProviderPrice,hxhb.ProviderPrice),0) as '回标报价',
		CASE WHEN ISNULL(ISNULL(b2.ProviderTaxRate,hxhb.ProviderTaxRate),0) = 0 THEN 0 ELSE ISNULL(ISNULL(b2.ProviderTaxRate,hxhb.ProviderTaxRate*100),0)/100 END as '税率',
		CASE WHEN ISNULL(ISNULL(b2.ProviderTaxRate,hxhb.ProviderTaxRate),0) = 0 THEN 0 ELSE ISNULL(ISNULL(b2.ProviderTaxRate,hxhb.ProviderTaxRate*100),0)/100 END as '税率',
		CASE WHEN a.x_IsHistory<>'1' THEN ISNULL(vp.ComprehensiveScore,0)
		WHEN a.x_IsHistory IS NULL THEN ISNULL(vp.ComprehensiveScore,0)
		WHEN a.x_IsHistory='1' THEN hxvp.ComprehensiveScore END  --核心定标得分
		 as '评审分数',
		CASE WHEN e.iswinbid=1 THEN '是' else '否' end as '是否中标',
		ISNULL(e.WinBidNoTaxPrice,0) as '拟中标不含税金额',
		ISNULL(e.WinBidPrice,0) as '拟中标含税金额',
		--case when ISNULL(b.x_LimitedPrice,0)=0 or ISNULL(e.WinBidPrice,0)=0 then NULL else (ISNULL(b.x_LimitedPrice,0)-ISNULL(e.WinBidPrice,0))/ISNULL(b.x_LimitedPrice,0) end as '采购节约率',
	    CASE WHEN a.x_IsHistory<>'1' THEN 
                (case when ISNULL(b.x_LimitedPrice,0)=0 or ISNULL(e.WinBidPrice,0)=0 then NULL else (ISNULL(e.WinBidPrice,0) - ISNULL(b.x_LimitedPrice,0))/ISNULL(b.x_LimitedPrice,0) end)
             WHEN a.x_IsHistory IS NULL THEN 
                (case when ISNULL(b.x_LimitedPrice,0)=0 or ISNULL(e.WinBidPrice,0)=0 then NULL else (ISNULL(e.WinBidPrice,0) - ISNULL(b.x_LimitedPrice,0))/ISNULL(b.x_LimitedPrice,0) end)    --如果不是历史数据，有可能为空，就无法算到节约率了
		     WHEN a.x_IsHistory='1' THEN 
                (case when ISNULL(hxxj.CgLimitedMoney,0)=0 or ISNULL(hxhb.WinBidPrice,0)=0 then NULL else (ISNULL(hxhb.WinBidPrice,0) - ISNULL(hxxj.CgLimitedMoney,0))/ISNULL(hxxj.CgLimitedMoney,0) end) 
             end as '采购节约率',	--改为不含税的节约率
		isnull(case when isnull(a.x_IsHistory,0)<>'1' then ISNULL(e.WinBidPrice,0) - ISNULL(b.x_LimitedPrice,0) else ISNULL(hxhb.WinBidPrice,0) - ISNULL(hxxj.CgLimitedMoney,0) end,0) as 采购节约率分子,
		isnull(case when isnull(a.x_IsHistory,0)<>'1' then b.x_LimitedPrice else hxxj.CgLimitedMoney end,0) as 采购节约率分母,
		vz.Employee as '联系人',
		vz.Phone as '联系电话',
		ISNULL(x_OpenBidLocation,'') AS '开标地点',
		a.Manager as '采购负责人',
		VZ.CgSolutionSectionGUID,VZ.isend,
		case when a.x_IsEntrustBid=1 then '是' ELSE '否' end as '是否委托股份招标'
from cg_cgsolution a
LEFT JOIN cg_CgSolutionProject P ON a.CgSolutionGUID=P.SolutionGUID
LEFT JOIN cg_CgType ty ON ty.CgTypeGUID=A.CgTypeGUID
left join vcg_CgSolutionProvider vb on vb.CgSolutionGUID=a.CgSolutionGUID AND vb.Isend = 0 --入围标段
left join vcg_CgSolutionProvider vz on vz.CgSolutionGUID=a.CgSolutionGUID AND VZ.CgSolutionSectionGUID = VB.CgSolutionSectionGUID AND VZ.Isend = 1 --入围供应商
left join cg_CgProcReturnBidMain b on a.CgSolutionGUID = b.CgSolutionGUID --回标
left join (select a.CgSolutionGUID,b.CgLimitedMoney from [172.16.22.29].[dotnet_erp352sp3].[dbo].Cg_CgSolution a
left join [172.16.22.29].[dotnet_erp352sp3].[dbo].cg_CgPlanFileRegistration b on a.CgPlanAdjustGUID = b.CgPlanAdjustGUID and b.CgType='2'
) hxxj on hxxj.CgSolutionGUID = a.CgSolutionGUID --核心限价
left join vcg_CgProcReturnBidMain b2 on a.CgSolutionGUID = b2.CgSolutionGUID AND VZ.ProviderGUID = b2.ProviderGUID and b2.SectionGUID = vb.BusinessGUID and b2.Isend=1 --回标供应商
left join vcg_CgProcAssessBidProvider vp on a.CgSolutionGUID = vp.CgSolutionGUID and VZ.ProviderGUID = vp.ProviderGUID and vp.SectionGUID = vb.BusinessGUID --评标供应商
left join [172.16.22.29].[dotnet_erp352sp3].[dbo].Cg_CgProcReturnBid hxvp on a.CgSolutionGUID = hxvp.CgSolutionGUID and VZ.ProviderGUID = hxvp.ProviderGUID and hxvp.CgSolutionSectionGUID = vb.BusinessGUID    --核心评标得分
inner join cg_CgProcWinBid d on a.CgSolutionGUID = d.CgSolutionGUID --定标
left join [172.16.22.29].[dotnet_erp352sp3].[dbo].cg_CgProcWinBid dd on a.CgSolutionGUID = dd.CgSolutionGUID --核心定标
inner join vcg_CgProcWinBid e on a.CgSolutionGUID = e.CgSolutionGUID and VZ.ProviderGUID = e.ProviderGUID and e.SectionGUID = vb.BusinessGUID --定标供应商
left join cg_CgProcProviderSign f on a.CgSolutionGUID = f.CgSolutionGUID and VZ.ProviderGUID =f.ReturnBidProviderGUID and f.SectionProjectGUID = vb.BusinessGUID --签约供应商
left join [172.16.22.29].[dotnet_erp352sp3].[dbo].cg_CgSolution hxcg on a.CgSolutionGUID = hxcg.CgSolutionGUID  --核心采购
left join [172.16.22.29].[dotnet_erp352sp3].[dbo].Cg_CgProcReturnBid hxhb on a.CgSolutionGUID = hxhb.CgSolutionGUID and vz.ProviderGUID = hxhb.ProviderGUID and hxhb.CgSolutionSectionGUID=vz.CgSolutionSectionGUID --核心回标
WHERE 	a.Status=2 
		and a.IsTacticCg=0 
		--and isnull(a.x_Ishistory,0)=0 
		--AND A.BUGUID IN (@var_BuGUIDs)
		AND a.ManagerGUID IN (@var_Manager) 
		AND P.ProjGUID IN (@var_ProjGUIDs)
		AND a.x_IsEntrustBid IN (@var_x_IsEntrustBid)
		AND a.x_IsJcPlatform IN (@var_x_IsJcPlatform)
		--AND DATEDIFF(DAY, @var_StartDate, a.[SendCgDate]) >= 0 PYW 与大屏采集平台-采购金额时间保持一致
		--AND DATEDIFF(DAY, a.[SendCgDate], @var_EndDate) >= 0	PYW 与大屏采集平台-采购金额时间保持一致
		--AND DATEDIFF(DAY, @var_StartDate, convert(date,(CASE WHEN D.ApproveTime is not null then D.ApproveTime when A.realEndTime is not null then A.realEndTime  else A.PlanEndTime end),23)) >= 0
		--AND DATEDIFF(DAY, convert(date,(CASE WHEN D.ApproveTime is not null then D.ApproveTime when A.realEndTime is not null then A.realEndTime  else A.PlanEndTime end),23), @var_EndDate) >= 0
		AND convert(date,(CASE WHEN D.ApproveTime is not null then D.ApproveTime when A.realEndTime is not null then A.realEndTime  else A.PlanEndTime end),23) between @var_StartDate and @var_EndDate
		--AND a.x_IsEntrustBid=1 --PYW 与大屏采集平台-采购金额时间保持一致
        --AND a.cgsolutionstate = '2'   --只显示完成定标的采购过程
		AND d.STATUS = 2
        AND a.CgSolutionState <> - 1
ORDER BY ISNULL(A.BUName,'')--,VZ.CgSolutionSectionGUID,VZ.isend