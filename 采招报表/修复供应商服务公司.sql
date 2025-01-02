
--------------//////////////////修复SQL///////////////////////////--------------------------------------------
-- 备份数据表
select * into p_Provider2UnitAdjust_bak20241230 from p_Provider2UnitAdjust
select * into p_Provider2Unit_bak20241230 from p_Provider2Unit
select * into p_Provider2UnitHzDetail_bak20241230 from p_Provider2UnitHzDetail
select  * into p_ProviderRecord_bak20241230 from p_ProviderRecord
select * into p_Provider_bak20241230 from p_Provider


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
  '265CDEE9-0E5B-4958-8E3C-AFC0D42B65BD',
  '96D4B7A6-A1F6-4D81-8991-2AD74B814A41',
  'CB770496-0635-44D3-A35E-16A471507482',
  'A820C78E-450C-4270-95D0-2B766137F3AA',
  '0A23AD8A-2D03-E411-9029-40F2E92B3FDD',
  '735C458A-E257-492F-B154-8DD5FF04265A',
  '39F83DD3-9531-473A-ABDC-C0319F824ED8',
  '71B191AA-DB10-E611-ADB3-40F2E92B3585'
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
