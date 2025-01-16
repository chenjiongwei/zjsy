--------------//////////////////修复SQL///////////////////////////--------------------------------------------
-- 备份数据表
select * into p_Provider2UnitAdjust_bak20240111 from p_Provider2UnitAdjust
select * into p_Provider2Unit_bak20240111 from p_Provider2Unit
select * into p_Provider2UnitHzDetail_bak20240111 from p_Provider2UnitHzDetail
select  * into p_ProviderRecord_bak20240111 from p_ProviderRecord


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
'3A0B11C1-918B-3497-0B6C-7DA862356D25',
'3A0DC7DA-4A8E-2A5D-72AF-6912A6D5CC47',
'DD1950BB-CCFC-4701-8D6B-C5AE203E155E',
'39F6AC51-EC9D-0F74-A0E4-7F9744A23655',
'39F842A8-9231-1070-C3CE-4F5D7371473A',
'B9E81047-B276-E811-AEF9-40F2E92B3FDA',
'4E5CC59C-937B-E911-8A8E-40F2E92B3FDA',
'39FB3126-FA7F-4D08-A1CB-88524FFBC317',
'F2ACC77C-ED7F-EB11-8B9A-005056A53239',
'C4FC46E7-6B21-EA11-8A8E-40F2E92B3FDA',
'A33CD6EB-2FFE-4FE8-ACC2-73AFABCF3A43',
'D543E631-3390-EB11-8B9A-005056A53239',
'351C4E25-62D2-EB11-8B9A-005056A53239',
'2FF55A4F-8960-4E21-83E2-F6A7F6C446A8',
'14F48A97-17A6-EA11-A1D4-40F2E92B3FDD',
'B28DDC03-29AC-E911-8A8E-40F2E92B3FDA',
'CB2605AA-00A7-EA11-A1D4-40F2E92B3FDD',
'8AFE8B7C-0D34-4863-9D55-7F31048CFC68',
'3A0E59D2-D61E-6135-D8C0-A31CBD966BAE',
'3A10F57B-B934-5678-F58E-BB9E92FD9C77',
'F0C24220-9D3E-E611-B3D2-40F2E92B3FDD'
)



-- 删除 供应商所属集团总部服务公司的记录 p_Provider2Unit
delete b
--SELECT DISTINCT  b.ProviderGUID
from  #Provider2Unit a
inner join p_Provider2Unit b on a.Provider2UnitGUID = b.Provider2UnitGUID
where b.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部


-- -- 将珠江商管插入服务公司
-- DECLARE @UserGUID uniqueidentifier
-- DECLARE @UserName nvarchar(50)
-- DECLARE @NewBUGUID uniqueidentifier -- 新公司GUID

-- select  @NewBUGUID=BUGUID from  myBusinessUnit  where  BUName ='珠江商管'
-- SELECT  @UserGUID = UserGUID ,@UserName = UserName FROM  dbo.myuser WHERE  UserCode ='admin'

-- INSERT  INTO dbo.p_Provider2Unit
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
-- SELECT  
--     @UserGUID AS  CreatedGUID,
--     @UserName AS  CreatedName,
--     GETDATE() AS  CreatedTime,
--     @UserGUID AS  ModifiedGUID,
--     @UserName AS  ModifiedName,
--     GETDATE() AS  ModifiedTime,
--     newid() AS  Provider2UnitGUID,
--     a.ProviderGUID,
--     @NewBUGUID as BUGUID,
--     0 AS  HzStatus
-- FROM #Provider2Unit a
-- LEFT JOIN  (
--    SELECT  ProviderGUID,COUNT(1) AS UnitNUm  
--    FROM  p_Provider2Unit 
--    WHERE BUGUID ='30e3b6af-6521-44c1-31d6-08da4991e890'  -- 珠江商管
--    GROUP BY  ProviderGUID 
-- ) b ON a.ProviderGUID =b.ProviderGUID
--  WHERE  b.ProviderGUID IS NULL 



--修改p_ProviderRecord 表上的 BUGUID
UPDATE  a
SET  a.BUGUID ='8D97B491-D08B-4AA0-7A1F-08DC90A2FD61'  -- 城实公司
-- select  a.*
FROM  p_ProviderRecord a
inner join  #Provider2Unit b on a.ProviderGUID =b.ProviderGUID
WHERE  a.BUGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部



--修改p_Provider2UnitHzDetail
update b  
   set b.BUGUID ='8D97B491-D08B-4AA0-7A1F-08DC90A2FD61',  -- 城实公司
   b.HtBUGUID = '8D97B491-D08B-4AA0-7A1F-08DC90A2FD61'  -- 城实公司 
--select  b.*
from  #Provider2Unit a
inner join p_Provider2UnitHzDetail b on a.ProviderGUID = b.ProviderGUID AND  b.BUGUID = a.BUGUID
where a.BuGUID ='2d08d5ea-6ff0-e311-9029-40f2e92b3fdd' -- 集团总部

-- --修改p_provider 表上的冗余字段 ProviderUnitGUIDList ProviderUnitNameList
-- UPDATE a
-- SET   a.ProviderUnitGUIDList = REPLACE(a.ProviderUnitGUIDList, '2d08d5ea-6ff0-e311-9029-40f2e92b3fdd', '30e3b6af-6521-44c1-31d6-08da4991e890'),
--       a.ProviderUnitNameList = REPLACE(a.ProviderUnitNameList, '集团总部', '珠江商管')
-- --SELECT  a.ProviderUnitGUIDList, a.ProviderUnitNameList,
-- --REPLACE(ProviderUnitGUIDList, '2d08d5ea-6ff0-e311-9029-40f2e92b3fdd', '30e3b6af-6521-44c1-31d6-08da4991e890') AS ProviderUnitGUIDListNew,
-- --REPLACE(ProviderUnitNameList, '集团总部', '珠江商管') AS ProviderUnitNameListNew
-- FROM  p_provider a
-- INNER JOIN #Provider2Unit b ON a.ProviderGUID = b.ProviderGUID 
-- WHERE 1=1
