/*
服务公司  集团总部的，但是是项目自行入库的，用途可能是合同登记的，需要剔除在城实公司，不要放在集团总部，多数是营销类的
查找合格供应商中服务公司包含“集团”和”城实公司“，且供应商为直接入库（供应商调整记录的”调整来源”为直接入库）
*/
--- 查询供应商考察合格记录
DECLARE	  @BUGUID VARCHAR(50) = '2d08d5ea-6ff0-e311-9029-40f2e92b3fdd'

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
       ProviderRecord.AddBy,
       ProviderRecord.AddByGUID,
       ProviderRecord.Remark,
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
        bu.BUName,
        prs.AddBy,  -- 调整人
        prs.AddByGUID, -- 调整人GUID
        prs.Remark  -- 备注
    FROM p_ProviderRecordAdjust ProviderRecord
    inner join p_ProviderRecord pr on ProviderRecord.ProviderRecordGUID = pr.ProviderRecordGUID
    inner join p_ProviderRecordStorage prs on prs.ProviderRecordGUID = pr.ProviderRecordGUID
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
    ZjrkProvider.AdjustSource as 调整来源,
    ZjrkProvider.AddBy as 调整人,
    ZjrkProvider.AddByGUID as 调整人GUID,
    ZjrkProvider.Remark as 调整备注,
    ZjrkProvider.BUFullName as 调整人所属公司全称
  FROM
    [MainCTE]
OUTER APPLY  ( 
   select  top  1 ZjrkProvider.BUNameList,ZjrkProvider.AdjustSource,ZjrkProvider.ProviderGUID,ZjrkProvider.AdjustDate,AddBy,AddByGUID,Remark,bu.BUFullName
   from  #ZjrkProvider ZjrkProvider 
   inner join myuser mu on ZjrkProvider.AddByGUID = mu.UserGUID
   inner join myBusinessUnit bu on mu.BUGUID = bu.BUGUID
   where   [MainCTE].ProviderGUID = ZjrkProvider.ProviderGUID
   order by ZjrkProvider.AdjustDate desc   
) ZjrkProvider  
-- where  ZjrkProvider.ProviderGUID is not null



DROP TABLE #CTE;
DROP TABLE #ZjrkProvider;

--------------//////////////////修复SQL///////////////////////////--------------------------------------------
-- 备份数据表
select * into p_Provider2UnitAdjust_bak20241216 from p_Provider2UnitAdjust
select * into p_Provider2Unit_bak20241216 from p_Provider2Unit
select * into p_Provider2UnitHzDetail_bak20241216 from p_Provider2UnitHzDetail
select  * into p_ProviderRecord_bak20241216 from p_ProviderRecord


-- -- 修复语句 20241213 chenjw 优先处理14个需要迁移到珠江商管的供应商
SELECT 
    p_Provider2Unit.Provider2UnitGUID,
    p_Provider2Unit.ProviderGUID,
    p_Provider2Unit.BUGUID,
    bu.BUName,
    bu.BUFullName,
    bu.BUCode
    into #Provider2Unit
FROM p_Provider2Unit 
INNER JOIN p_Provider p  ON p.ProviderGUID = p_Provider2Unit.ProviderGUID
INNER JOIN myBusinessUnit bu   ON bu.BUGUID = p_Provider2Unit.BUGUID
WHERE bu.BUName = '集团总部'
and  p.providerguid in (
  -- 'D01E0F6E-6829-E711-B3D4-40F2E92B3FDD'
  '3A0FE0A6-FF7A-5433-E9D1-9D1AD5F6E237',
  '3A0F971D-0753-73BE-6AD9-E66FE9BA65E7',
  '3A0C7A30-02FF-6163-FE26-90F1D17F6B53',
  '3A0DB5C0-627C-B848-C58B-D6BBFA7AE057',
  '3A0CC21F-36FC-8579-DB89-51B0920D7139',
  '3A0DC8E0-98C8-7189-0FC3-5803B90D9ECD',
  '3A0DBFBD-BE33-BA8C-32C3-7A98B92D8B00',
  '3A0BCBEC-13FF-B971-0283-F7F8D3A35992',
  '3A0CC15C-5D97-E2BE-C42B-7BCBE3F2EBDB',
  '3A0EEE21-A2D2-F28E-ADF5-6944519B58D9',
  '3A0EC921-5C0C-010A-C1A7-34FCD27A52EC',
  '3A0C7A4D-975D-4BF9-E137-324498B5F499',
  '3A0CC7D4-DF94-C1D5-9E7B-5E1CAAF3D6C9',
  '3A0C7A44-45AE-2ABA-94F1-3D2CE1948160'
)


-- -- 删除服务公司调整记录 p_Provider2UnitAdjust
-- delete b
-- -- select a.*
-- from  #Provider2Unit a
-- inner join p_Provider2UnitAdjust b on a.Provider2UnitGUID = b.Provider2UnitGUID
-- where a.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部

-- 删除 供应商所属集团总部服务公司的记录 p_Provider2Unit
delete b
--SELECT DISTINCT  b.ProviderGUID
from  #Provider2Unit a
inner join p_Provider2Unit b on a.Provider2UnitGUID = b.Provider2UnitGUID
where b.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部


-- 将珠江商管插入服务公司
DECLARE @UserGUID uniqueidentifier
DECLARE @UserName nvarchar(50)
DECLARE @NewBUGUID uniqueidentifier -- 新公司GUID

select  @NewBUGUID=BUGUID from  myBusinessUnit  where  BUName ='珠江商管'
SELECT  @UserGUID = UserGUID ,@UserName = UserName FROM  dbo.myuser WHERE  UserCode ='admin'

INSERT  INTO dbo.p_Provider2Unit
(
    CreatedGUID,
    CreatedName,
    CreatedTime,
    ModifiedGUID,
    ModifiedName,
    ModifiedTime,
    Provider2UnitGUID,
    ProviderGUID,
    BUGUID,
    HzStatus
)
SELECT  
    @UserGUID AS  CreatedGUID,
    @UserName AS  CreatedName,
    GETDATE() AS  CreatedTime,
    @UserGUID AS  ModifiedGUID,
    @UserName AS  ModifiedName,
    GETDATE() AS  ModifiedTime,
    newid() AS  Provider2UnitGUID,
    a.ProviderGUID,
    @NewBUGUID as BUGUID,
    0 AS  HzStatus
FROM #Provider2Unit a
LEFT JOIN  (
   SELECT  ProviderGUID,COUNT(1) AS UnitNUm  
   FROM  p_Provider2Unit 
   WHERE BUGUID ='30e3b6af-6521-44c1-31d6-08da4991e890'  -- 珠江商管
   GROUP BY  ProviderGUID 
) b ON a.ProviderGUID =b.ProviderGUID
 WHERE  b.ProviderGUID IS NULL 



--修改p_ProviderRecord 表上的 BUGUID
UPDATE  a
SET  a.BUGUID ='30e3b6af-6521-44c1-31d6-08da4991e890'  -- 珠江商管
-- select  a.*
FROM  p_ProviderRecord a
inner join  #Provider2Unit b on a.ProviderGUID =b.ProviderGUID
WHERE  a.BUGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部



--修改p_Provider2UnitHzDetail
update b  
   set b.BUGUID ='30e3b6af-6521-44c1-31d6-08da4991e890',  -- 珠江商管
   b.HtBUGUID = '30e3b6af-6521-44c1-31d6-08da4991e890'  -- 珠江商管 
--select  b.*
from  #Provider2Unit a
inner join p_Provider2UnitHzDetail b on a.ProviderGUID = b.ProviderGUID AND  b.BUGUID = a.BUGUID
where a.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部

--修改p_provider 表上的冗余字段 ProviderUnitGUIDList ProviderUnitNameList
UPDATE a
SET   a.ProviderUnitGUIDList = REPLACE(a.ProviderUnitGUIDList, '2d08d5ea-6ff0-e311-9029-40f2e92b3fdd', '30e3b6af-6521-44c1-31d6-08da4991e890'),
      a.ProviderUnitNameList = REPLACE(a.ProviderUnitNameList, '集团总部', '珠江商管')
--SELECT  a.ProviderUnitGUIDList, a.ProviderUnitNameList,
--REPLACE(ProviderUnitGUIDList, '2d08d5ea-6ff0-e311-9029-40f2e92b3fdd', '30e3b6af-6521-44c1-31d6-08da4991e890') AS ProviderUnitGUIDListNew,
--REPLACE(ProviderUnitNameList, '集团总部', '珠江商管') AS ProviderUnitNameListNew
FROM  p_provider a
INNER JOIN #Provider2Unit b ON a.ProviderGUID = b.ProviderGUID 
WHERE 1=1



-- ---测试删除 广东永旺天河城商业有限公司 供应商服务公司后查询不了的问题
-- delete b
-- --SELECT DISTINCT  b.ProviderGUID
-- from  #Provider2Unit a
-- inner join p_Provider2Unit b on a.Provider2UnitGUID = b.Provider2UnitGUID
-- where b.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部
-- and  b.ProviderGUID ='3A10140F-3601-1D13-AB95-51F82AD06AD7' -- 广东永旺天河城商业有限公司

-- INSERT INTO  p_Provider2Unit (
--     CreatedGUID,
--     CreatedName,
--     CreatedTime,
--     ModifiedGUID,
--     ModifiedName,
--     ModifiedTime,
--     Provider2UnitGUID,
--     ProviderGUID,
--     BUGUID,
--     HzStatus
-- )
-- SELECT  CreatedGUID,
--     CreatedName,
--     CreatedTime,
--     ModifiedGUID,
--     ModifiedName,
--     ModifiedTime,
--     Provider2UnitGUID,
--     ProviderGUID,
--     BUGUID,
--     HzStatus FROM  p_Provider2Unit_bak20241213 b
-- where b.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部
-- and  b.ProviderGUID ='3A10140F-3601-1D13-AB95-51F82AD06AD7'


--修改p_provider 表上的冗余字段 ProviderUnitGUIDList ProviderUnitNameList
-- UPDATE p_provider
-- SET   ProviderUnitGUIDList ='30e3b6af-6521-44c1-31d6-08da4991e890' ,ProviderUnitNameList ='珠江商管'
-- FROM  p_provider where  ProviderGUID ='3A10140F-3601-1D13-AB95-51F82AD06AD7'


-- --修改p_ProviderRecord 表上的 BUGUID
-- UPDATE  p_ProviderRecord
-- SET BUGUID ='30e3b6af-6521-44c1-31d6-08da4991e890' 
-- FROM  p_ProviderRecord  WHERE  ProviderGUID ='3A10140F-3601-1D13-AB95-51F82AD06AD7'

--删除以后查询不到了供应商
-- INSERT INTO  dbo.p_Provider2Unit
-- (
--     CreatedGUID,
--     CreatedName,
--     CreatedTime,
--     ModifiedGUID,
--     ModifiedName,
--     ModifiedTime,
--     Provider2UnitGUID,
--     ProviderGUID,
--     BUGUID,
--     HzStatus
-- )
-- select  
--     a.CreatedGUID,
--     a.CreatedName,
--     a.CreatedTime,
--     a.ModifiedGUID,
--     a.ModifiedName,
--     a.ModifiedTime,
--     a.Provider2UnitGUID,
--     a.ProviderGUID,
--     a.BUGUID,
--     a.HzStatus
-- 	FROM  p_Provider2Unit_bak20241213 a
-- inner join  #Provider2Unit b on a.ProviderGUID = b.ProviderGUID
-- where  not exists (
--        select 1 from  p_Provider2Unit p where p.Provider2UnitGUID = a.Provider2UnitGUID
--      )

    -- AND p.ProviderGUID IN (
    --   'D01E0F6E-6829-E711-B3D4-40F2E92B3FDD',
    --   '3A0FE0A6-FF7A-5433-E9D1-9D1AD5F6E237',
    --   -- '3A10140F-3601-1D13-AB95-51F82AD06AD7',
    --   '3A0F971D-0753-73BE-6AD9-E66FE9BA65E7',
    --   '7A525B46-70F2-E511-9F09-40F2E92B3FDD',
    --   '3A0C7A30-02FF-6163-FE26-90F1D17F6B53',
    --   '3A0DB5C0-627C-B848-C58B-D6BBFA7AE057',
    --   '12BE934B-89BA-E511-B4AF-40F2E92B3FDD',
    --   '706A8359-7E9B-4AAB-97D5-8A4C6A824187',
    --   '3A0CC21F-36FC-8579-DB89-51B0920D7139',
    --   '3A0DC8E0-98C8-7189-0FC3-5803B90D9ECD',
    --  -- '39FD9BB2-2BEB-EDA8-B2A1-07E391B130CE',
    --   '1A96BAA2-425D-426E-8759-1FF8B1FC083A',
    --   '3A0DBFBD-BE33-BA8C-32C3-7A98B92D8B00',
    --   '3A0CA24C-FA30-61F1-4B70-A8E47A27BE32',
    --   '3A0BCBEC-13FF-B971-0283-F7F8D3A35992',
    --   '3A0CC15C-5D97-E2BE-C42B-7BCBE3F2EBDB',
    --   '3A0EEE21-A2D2-F28E-ADF5-6944519B58D9',
    --   '3A0EC921-5C0C-010A-C1A7-34FCD27A52EC',
    --   '3A0C7A4D-975D-4BF9-E137-324498B5F499',
    --   '3A0CC7D4-DF94-C1D5-9E7B-5E1CAAF3D6C9',
    --   '3A0C7A44-45AE-2ABA-94F1-3D2CE1948160'
    -- )