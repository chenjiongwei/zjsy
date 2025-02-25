-- DROP TABLE 待修复联系单 

--1.1 查询工作联系单明细
SELECT 
    a.[ContractItemGUID],--联系单GUID
    bu.BUName AS 公司,
    [Code] AS 联系单编号,
    [Name] AS 联系单名称,
    x_IsExec AS 是否执行,
    ItemType AS 联系单类型,
    FinalEstimateAmount_Bz AS 最后预估金额,
    ApplierName AS 申请人,
    LaunchTime AS 发起日期,
    a.ApproveState AS 审批状态,
    a.x_ContractGUID AS 关联合同GUID,
    a.x_ContractName AS 关联合同名称,
    c.ContractCode AS 关联合同编号
into #conitem 
FROM cb_ContractItem a
    INNER JOIN myBusinessUnit bu ON a.BuGUID = bu.BUGUID
    LEFT JOIN dbo.cb_Contract c ON c.ContractGUID = a.x_ContractGUID
WHERE 1 = 1


-- 查找目前在系统中不存在的联系单
SELECT  a.*  -- INTO 系统中不存在联系单 
FROM  [联系单修复]  a
LEFT  JOIN  #conitem  b ON a.联系单编号 =b.联系单编号 AND  b.公司 = a.公司
WHERE  b.联系单编号 IS NULL 

-- DROP TABLE  关联合同名称不存在
-- 依据关联合同名称修复关联合同信息
SELECT  a.*  INTO  关联合同名称不存在
FROM  [联系单修复]  a
inner   JOIN  #conitem  b ON a.联系单编号 =b.联系单编号 AND  b.公司 = a.公司
left join  cb_Contract c on a.关联合同编号 = c.ContractCode 
WHERE a.关联合同名称 IS NOT NULL AND  c.ContractName IS NULL

-- 2.1 开始修复
-- 备份数据表
SELECT  * INTO cb_ContractItem_bak20241206  FROM  cb_ContractItem
-- 查询更新信息
SELECT DISTINCT  b.ContractItemGUID,c.ContractCode,c.ContractName,c.ContractGUID
INTO #Updateconitem
FROM  [联系单修复]  a
inner   JOIN  #conitem  b ON a.联系单编号 =b.联系单编号 AND  b.公司 = a.公司
INNER  join  cb_Contract c on a.关联合同编号 = c.ContractCode 
WHERE a.关联合同名称 IS NOT NULL 

--查询更新信息
SELECT  a.ContractItemGUID,b.ContractItemGUID,b.ContractCode,b.ContractGUID,a.x_ContractGUID,a.x_ContractName
from cb_ContractItem a
INNER  JOIN   #Updateconitem  b ON a.ContractItemGUID = b.ContractItemGUID
where a.x_ContractGUID is  null 

--更新关联合同信息
UPDATE a
SET a.x_ContractGUID = b.ContractGUID,a.x_ContractName = b.ContractName
FROM cb_ContractItem a
INNER  JOIN   #Updateconitem  b ON a.ContractItemGUID = b.ContractItemGUID
where a.x_ContractGUID is  null

--删除临时表
drop table #conitem 
drop table #Updateconitem 




-- 关联错误进行修复
-- 备份数据表
SELECT  * INTO  cb_ContractItem_bak20241209  FROM  cb_ContractItem 
-- 查询错误数据
select * from cb_ContractItem where Code  in 
('jyfdc-2024-01-0001',
'一期 设变-D-21会审',
'一期 设变-D-22会审',
'设变-水-20会审',
'璟逸工【2021】5号',
'璟逸工【2021】52号',
'璟逸工【2023】50号',
'jyfdc-2023-06-0011',
'璟逸工[2023]69号-关于花屿花城项目1-3#楼空调孔整改的事宜',
'jyfdc-2023-06-0009',
'设变-水-16的会审',
'一期 设变-D-20会审',
'一期 设变-D-19会审'
)
-- 更新关联合同信息 
update  a
set a.x_ContractGUID = (select ContractGUID from cb_Contract where ContractCode = '穗珠建专分字第20199号'),
   a.x_ContractName = (select ContractName from cb_Contract where ContractCode = '穗珠建专分字第20199号')
from  cb_ContractItem a
where Code  in 
('jyfdc-2024-01-0001',
'一期 设变-D-21会审',
'一期 设变-D-22会审',
'设变-水-20会审',
'璟逸工【2021】5号',
'璟逸工【2021】52号',
'璟逸工【2023】50号',
'jyfdc-2023-06-0011',
'璟逸工[2023]69号-关于花屿花城项目1-3#楼空调孔整改的事宜',
'jyfdc-2023-06-0009',
'设变-水-16的会审',
'一期 设变-D-20会审',
'一期 设变-D-19会审'
)

