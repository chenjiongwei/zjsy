USE [dotnet_erp60_MDC]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_项目销售周报_回溯]    Script Date: 2025/1/16 15:55:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--[usp_s_项目销售周报_回溯] 'F695E9DE-89E9-E411-B4AE-40F2E92B3FDD','2025-1-16'

ALTER PROC [dbo].[usp_s_项目销售周报_回溯]
(
	@var_proj VARCHAR(MAX),
	@var_enddate DATETIME
)
AS 	
BEGIN 
	IF DATEDIFF(dd,@var_enddate,getdate())=0
		BEGIN 
		  CREATE TABLE #销售周报
			(
				[Projguid] [uniqueidentifier] NULL,
				[业态] [nvarchar](128) NULL,
				[排序] [int] NULL,
				[周期] [nvarchar](128) NULL,
				[来访统计] [int] NULL,
				[来电统计] [int] NULL,
				[认购套数] [int] NULL,
				[认购面积] [decimal](18, 4) NULL,
				[认购金额] [decimal](18, 4) NULL,
				[预选套数] [int] NULL,
				[预选面积] [decimal](18, 4) NULL,
				[预选金额] [decimal](18, 4) NULL,
				[认购退房套数] [int] NULL,
				[认购退房面积] [decimal](18, 4) NULL,
				[认购退房金额] [decimal](18, 4) NULL,
				[净签约套数] [int] NULL,
				[净签约面积] [decimal](18, 4) NULL,
				[净签约金额] [decimal](18, 4) NULL,
				[延期付款净签约套数] [int] NULL,
				[签约重售套数] [int] NULL,
				[签约重售面积] [decimal](18, 4) NULL,
				[签约重售金额] [decimal](18, 4) NULL,
				[本年签约回款] [decimal](18, 4) NULL,
				[往年签约回款] [decimal](18, 4) NULL,
				[认购未签约回款] [decimal](18, 4) NULL
			)
			INSERT INTO #销售周报 EXEC usp_s_项目销售周报 @var_proj,@var_enddate
			SELECT 
                 pro.p_projectid as 项目GUID,
			     pro.SpreadName as 推广项目名称,
				 pro.projname as 项目名称,
				 排序,
				 a.周期,
				 isnull(op.来访统计,0) as 来访统计,
				 isnull(op.来电统计,0) as 来电统计,
 				 业态,
				 isnull(sum(认购套数),0) as 认购套数,	
				 isnull(sum(认购面积),0) as 认购面积,
				 isnull(sum(认购金额),0)*0.0001 as 认购金额,
				 isnull(sum(预选套数),0) as 预选套数,	
				 isnull(sum(预选面积),0) as 预选面积,
				 isnull(sum(预选金额),0)*0.0001 as 预选金额,
				 isnull(sum(认购退房套数),0) as 认购退房套数,	
				 isnull(sum(认购退房面积),0) as 认购退房面积,
				 isnull(sum(认购退房金额),0)*0.0001 as 认购退房金额,
 				 isnull(sum(净签约套数),0)+isnull(sum(签约重售套数),0) as 实际签约套数,	
				 isnull(sum(净签约面积),0)+isnull(sum(签约重售面积),0) as 实际签约面积,
				 (isnull(sum(净签约金额),0)+isnull(sum(签约重售金额),0))*0.0001 as 实际签约金额,
				 isnull(sum(签约重售套数),0) as 签约重售套数,	
				 isnull(sum(签约重售面积),0) as 签约重售面积,
				 isnull(sum(签约重售金额),0)*0.0001 as 签约重售金额,
 				 isnull(sum(净签约套数),0) as 净签约套数,	
				 isnull(sum(净签约面积),0) as 净签约面积,
				 isnull(sum(净签约金额),0)*0.0001 as 净签约金额,
				 isnull(sum(本年签约回款),0)*0.0001 as 本年签约回款,
				 isnull(sum(往年签约回款),0)*0.0001 as 往年签约回款,
				 (isnull(sum(本年签约回款),0)+isnull(sum(往年签约回款),0))*0.0001 as 签约回款,
				 isnull(sum(认购未签约回款),0)*0.0001 as 认购未签约回款,
				 (isnull(sum(本年签约回款),0)+isnull(sum(往年签约回款),0)+isnull(sum(认购未签约回款),0))*0.0001 as 回款合计,
 				 isnull(sum(延期付款净签约套数),0) as 延期付款净签约套数,
				 isnull(sum(净签约套数),0) as 当年合约销售总套数
			FROM #销售周报 a
			inner join data_wide_mdm_project fq on a.projguid=fq.p_projectid
			inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
			left join 
			(
			select parentguid,周期,sum(来访统计) as 来访统计,sum(来电统计) as 来电统计
			from 
			(select distinct parentguid,projguid,周期,来访统计,来电统计 FROM #销售周报 a
			inner join data_wide_mdm_project pro on a.projguid=pro.p_projectid) tt group by parentguid,周期) op on pro.p_projectid=op.parentguid and a.周期=op.周期
			GROUP BY  pro.p_projectid,
			     pro.SpreadName,
				 pro.projname,
				 a.业态,
				 排序,
				 a.周期,
				 op.来电统计,
				 op.来访统计
			drop table #销售周报;	 
		END;
	ELSE 
		BEGIN 
			SELECT
                 pro.p_projectId as 项目GUID,
			     pro.SpreadName as 推广项目名称,
				 pro.projname as 项目名称,
				 排序,
				 a.周期,
				 op.来访统计,
				 op.来电统计,
 				 业态,
				 isnull(sum(认购套数),0) as 认购套数,	
				 isnull(sum(认购面积),0) as 认购面积,
				 isnull(sum(认购金额),0)*0.0001 as 认购金额,
				 isnull(sum(预选套数),0) as 预选套数,	
				 isnull(sum(预选面积),0) as 预选面积,
				 isnull(sum(预选金额),0)*0.0001 as 预选金额,
				 isnull(sum(认购退房套数),0) as 认购退房套数,	
				 isnull(sum(认购退房面积),0) as 认购退房面积,
				 isnull(sum(认购退房金额),0)*0.0001 as 认购退房金额,
 				 isnull(sum(净签约套数),0)+isnull(sum(签约重售套数),0) as 实际签约套数,	
				 isnull(sum(净签约面积),0)+isnull(sum(签约重售面积),0) as 实际签约面积,
				 (isnull(sum(净签约金额),0)+isnull(sum(签约重售金额),0))*0.0001 as 实际签约金额,
				 isnull(sum(签约重售套数),0) as 签约重售套数,	
				 isnull(sum(签约重售面积),0) as 签约重售面积,
				 isnull(sum(签约重售金额),0)*0.0001 as 签约重售金额,
 				 isnull(sum(净签约套数),0) as 净签约套数,	
				 isnull(sum(净签约面积),0) as 净签约面积,
				 isnull(sum(净签约金额),0)*0.0001 as 净签约金额,
				 isnull(sum(本年签约回款),0)*0.0001 as 本年签约回款,
				 isnull(sum(往年签约回款),0)*0.0001 as 往年签约回款,
				 (isnull(sum(本年签约回款),0)+isnull(sum(往年签约回款),0))*0.0001 as 签约回款,
				 isnull(sum(认购未签约回款),0)*0.0001 as 认购未签约回款,
				 (isnull(sum(本年签约回款),0)+isnull(sum(往年签约回款),0)+isnull(sum(认购未签约回款),0))*0.0001 as 回款合计,
 				 isnull(sum(延期付款净签约套数),0) as 延期付款净签约套数,
				 isnull(sum(净签约套数),0) as 当年合约销售总套数
			FROM s_Weeklyreport_sapshot a 
			inner join data_wide_mdm_project fq on a.projguid=fq.p_projectid
			inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
			left join 
			(
			select parentguid,周期,sum(来访统计) as 来访统计,sum(来电统计) as 来电统计
			from 
			(select distinct parentguid,projguid,周期,来访统计,来电统计 FROM s_Weeklyreport_sapshot a
			inner join data_wide_mdm_project pro on a.projguid=pro.p_projectid
			WHERE DATEDIFF(dd,拍照时间,@var_enddate)=0
			AND a.Projguid IN (SELECT AllItem FROM fn_split_new(@var_proj,',')) ) tt group by parentguid,周期) op on pro.p_projectid=op.parentguid and a.周期=op.周期
			WHERE DATEDIFF(dd,拍照时间,@var_enddate)=0
			AND a.Projguid IN (SELECT AllItem FROM fn_split_new(@var_proj,',')) 
			GROUP BY 
               pro.p_projectId,
			   pro.SpreadName,
				 pro.projname,
				 业态,
				 排序,
				 a.周期,
				 op.来电统计,
				 op.来访统计
		END;
END;
