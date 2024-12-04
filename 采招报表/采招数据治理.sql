/*
服务公司  集团总部的，但是是项目自行入库的，用途可能是合同登记的，需要剔除在城实公司，不要放在集团总部，多数是营销类的
查找合格供应商中服务公司包含“集团”和”城实公司“，且供应商为直接入库（供应商调整记录的”调整来源”为直接入库）
*/
--- 查询供应商考察合格记录
DECLARE	  @BUGUID VARCHAR(50) = '2d08d5ea-6ff0-e311-9029-40f2e92b3fdd'
DECLARE  @PageStart INT  =  1
DECLARE  @PageEnd INT  = 20

SELECT
  [ProviderRecord].[ProviderRecordGUID],
  [provider].[ProviderGUID],
  [ProviderRecord].[BUGUID],
  [ProviderType].[Name],
  [ProviderRecord].[KcGrade],
  [ProviderRecord].[ProviderState],
  [ProviderGrade].[GradeName],
  [ProviderRecord].[PgGrade],
  [Provider2Unit].HzStatus
INTO
  #CTE
FROM
  [dbo].[p_ProviderRecord] ProviderRecord WITH ( NOLOCK )
  INNER JOIN [dbo].[p_Provider] provider WITH ( NOLOCK ) ON [provider].[ProviderGUID] = [ProviderRecord].[ProviderGUID] AND [provider].[IsBlackList] = 0
  INNER JOIN [dbo].[p_Provider2Unit] Provider2Unit ON Provider2Unit.ProviderGUID = provider.ProviderGUID AND Provider2Unit.BUGUID = @BUGUID
  INNER JOIN [dbo].[p_ProviderInvestigateGrade] ProviderInvestigateGrade WITH ( NOLOCK ) ON [ProviderInvestigateGrade].[InvestigateGradeGUID] = [ProviderRecord].[KcGUID] AND [ProviderInvestigateGrade].[IsCanHZ] = 1
  INNER JOIN p_ProviderType ProviderType WITH ( NOLOCK ) ON [ProviderType].[ProviderTypeGUID] = [ProviderRecord].[ProviderTypeGUID]
  LEFT JOIN [dbo].[p_ProviderGrade] ProviderGrade WITH ( NOLOCK ) ON [ProviderGrade].[ProviderGradeGUID] = [ProviderRecord].[PgGUID]
WHERE
   (1=1) 
  AND ( [ProviderRecord].[PgGUID] IS NULL OR [ProviderGrade].[IsCanHZ] = 1 )
  AND [provider].[Status] = 2
  AND [ProviderRecord].[BUGUID] = @BUGUID;


--查找合格供应商中服务公司包含“集团”和”城实公司“，且供应商为直接入库（供应商调整记录的”调整来源”为直接入库）
SELECT p_Provider.ProviderGUID,
       p_Provider.ProviderName,
       ProviderRecord.AdjustSource,
       ProviderRecord.AdjustDate,
       P2U.BUName,
       (SELECT STUFF(
               (SELECT ',' + CONVERT(VARCHAR(200), b.BUName)
                FROM p_Provider2Unit a
                LEFT JOIN myBusinessUnit b 
                    ON a.buguid = b.buguid
                WHERE b.IsCompany = 1
                    AND a.ProviderGUID = p_Provider.ProviderGUID
                FOR XML PATH('')),
               1,
               1,
               '')) AS BUNameList
into #ZjrkProvider
FROM p_Provider p_Provider
OUTER APPLY (
    -- 集团总部或城实公司发起的直接入库
    SELECT TOP 1 
        ProviderRecord.ProviderGUID,
        ProviderRecord.AdjustSource,
        ProviderRecord.AdjustSourceType,
        ProviderRecord.AdjustDate,
        pr.BUGUID,
        bu.BUName
    FROM p_ProviderRecordAdjust ProviderRecord
    inner join p_ProviderRecord pr on ProviderRecord.ProviderRecordGUID = pr.ProviderRecordGUID
    inner join myBusinessUnit bu on pr.BUGUID = bu.BUGUID
    WHERE ProviderRecord.ProviderGUID = p_Provider.ProviderGUID 
        AND AdjustSource = '直接入库' and  bu.BUName in ('城实公司','集团总部')
    ORDER BY ProviderRecord.AdjustDate DESC
) ProviderRecord
inner JOIN (
    SELECT Provider2Unit.ProviderGUID,
           bu.BUName,
           Provider2Unit.BUGUID
    FROM p_Provider2Unit Provider2Unit
    INNER JOIN myBusinessUnit bu 
        ON Provider2Unit.BUGUID = bu.BUGUID
    WHERE bu.IsCompany = 1 
        AND bu.BUName = '城实公司'
) P2U ON p_Provider.ProviderGUID = P2U.ProviderGUID
WHERE AdjustSource = '直接入库';

WITH MainCTE AS (
SELECT
  [#CTE].[BUGUID],
  [#CTE].[HzStatus],
  [provider].[ProviderGUID],
  [provider].[ProviderName],
  [provider].[ProviderCode],
  [provider].[ProviderShortName],
  [provider].[VersionNumber],
  [provider].[Source],
  [provider].[Status],
  [provider].[ApproveStatus],
  [provider].[ApproveModel],
  [provider].[IsBlackList],
  [provider].[LogoFile],
  [provider].Top100,
  [provider].ListSuccessful,
  [provider].IndustryTop,
  [provider].BusinessRisk,
  [provider].IsUpdate,
  [provider].[ClaimStatus],
  [provider].[ClaimStatusName],
  [provider].[TagNameList],
  [provider].[TagGUIDList],
  [provider].x_AgentFactory,
  [provider].x_DailyStrategic,
  MIN(FirstKc.BeginDate) AS FirstKcDate
FROM
  [dbo].[p_Provider] provider
  INNER JOIN [#CTE]
    ON [#CTE].[ProviderGUID] = [provider].[ProviderGUID]
  LEFT JOIN (
   SELECT p_ProviderRecord.ProviderGUID,cg_ProviderInvestigate.BeginDate 
	 FROM [dbo].cg_ProviderInvestigate cg_ProviderInvestigate WITH ( NOLOCK ) 
	 INNER JOIN dbo.p_ProviderRecord p_ProviderRecord WITH ( NOLOCK ) ON cg_ProviderInvestigate.ProviderRecordGUID = p_ProviderRecord.ProviderRecordGUID
	 INNER JOIN dbo.p_ProviderType ProviderType WITH ( NOLOCK )  ON p_ProviderRecord.[ProviderTypeGUID] = ProviderType.[ProviderTypeGUID]
   INNER JOIN dbo.cg_ProviderInvestigatePlan cg_ProviderInvestigatePlan  WITH ( NOLOCK )  ON cg_ProviderInvestigate.ProviderInvestigatePlanGUID = cg_ProviderInvestigatePlan.ProviderInvestigatePlanGUID
	 WHERE  (1=1)  AND cg_ProviderInvestigatePlan.InvestigatePlanStatus = 4 AND cg_ProviderInvestigate.InvestigateGrade = '考察合格' AND p_ProviderRecord.BUGUID = @BUGUID
  ) FirstKc ON [provider].[ProviderGUID] = FirstKc.ProviderGUID
GROUP BY
  [provider].[ProviderGUID],
  [provider].[ProviderName],
  [provider].[ProviderCode],
  [provider].[ProviderShortName],
  [#CTE].[BUGUID],
  [#CTE].[HzStatus],
  [provider].[Source],
  [provider].[Status],
  [provider].[ApproveStatus],
  [provider].[ApproveModel],
  [provider].[IsBlackList],
  [provider].[LogoFile],
  [provider].[VersionNumber],
  [provider].Top100,
  [provider].ListSuccessful,
  [provider].IndustryTop,
  [provider].BusinessRisk,
  [provider].IsUpdate,
  [provider].[ClaimStatus],
  [provider].[ClaimStatusName],
  [provider].TagNameList,
  [provider].TagGUIDList,
  [provider].x_AgentFactory,
  [provider].x_DailyStrategic
)

-- 查询结果
  SELECT
    ROW_NUMBER() OVER ( ORDER BY  [MainCTE].[ProviderName] ASC  ) AS num,
    [MainCTE].[BUGUID],
    [MainCTE].[ProviderGUID],
    [MainCTE].[ProviderName],
    [MainCTE].[ProviderCode],
    [MainCTE].[ProviderShortName],
    [MainCTE].[Source],
    [MainCTE].[Status],
    [MainCTE].[ApproveStatus],
    [MainCTE].[ApproveModel],
    [MainCTE].[IsBlackList],
    [MainCTE].[LogoFile] ,
    [MainCTE].[VersionNumber],
    [MainCTE].[HzStatus],
    [MainCTE].ListSuccessful,
    [MainCTE].IndustryTop ,
    [MainCTE].BusinessRisk,
    [MainCTE].IsUpdate,
    [MainCTE].[ClaimStatus],
    [MainCTE].[ClaimStatusName],
    [MainCTE].TagNameList,
    [MainCTE].TagGUIDList,
    [MainCTE].x_AgentFactory,
    [MainCTE].x_DailyStrategic,
    case when  ZjrkProvider.ProviderGUID is not null then '是' else '否' end as 是否需要迁移,
    ZjrkProvider.BUNameList as 服务公司,
    ZjrkProvider.AdjustSource as 调整来源
  FROM
    [MainCTE]
OUTER APPLY  ( 
   select  top  1 ZjrkProvider.BUNameList,ZjrkProvider.AdjustSource,ZjrkProvider.ProviderGUID,ZjrkProvider.AdjustDate 
   from  #ZjrkProvider ZjrkProvider where   [MainCTE].ProviderGUID = ZjrkProvider.ProviderGUID
   order by ZjrkProvider.AdjustDate desc   
) ZjrkProvider  
-- where  ZjrkProvider.ProviderGUID is not null



DROP TABLE #CTE;
DROP TABLE #ZjrkProvider;

-------------------------------------------------------------------------

-- 修复语句

select p_Provider2Unit.ProviderGUID,p_Provider2Unit.BUGUID 
from p_Provider2Unit 
inner join p_Provider p on p.ProviderGUID = p_Provider2Unit.ProviderGUID
inner join myBusinessUnit bu on bu.BUGUID = p_Provider2Unit.BUGUID
where p.ProviderName = '东莞市交通规划勘察设计院有限公司' and  bu.BUName = '城实公司'
