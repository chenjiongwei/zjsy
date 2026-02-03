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



---//////////////2025-05-16  现场签证关联联系单 ////////////////////////-----------------

-- 将Excel表数据插入临时表
CREATE TABLE [dbo].[待修复联系单20250516](
	[序号] [float] NULL,
	[联系单编号] [nvarchar](255) NULL,
	[联系单名称] [nvarchar](255) NULL,
	[联系单类型] [nvarchar](255) NULL,
	[变更编号] [nvarchar](255) NULL,
	[变更名称] [nvarchar](255) NULL,
	[变更类型] [nvarchar](255) NULL
) ON [PRIMARY]

GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (1, N'XM项外-2024（15）号', N'关于园区垃圾分类收集点扩大铺装和增加电源、园区新增照明灯的事宜', N'现场签证', N'XMKYZ-YL-[园建]-QZ-064', N'关于园区垃圾分类收集点扩大铺装和增加电源、园区新增照明灯的相关事宜', N'现场签证')
GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (2, N'XM项外-2023（11）号', N'关于展示区新建B户型样板房事宜', N'现场签证', N'XMKYZ-TJ-[B户型样板房]-QZ-018', N'关于展示区新建B户型样板房事宜', N'现场签证')
GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (3, N'XM-20241206-214', N'关于延展区花基、升井及地面打凿施工相关事宜', N'现场签证', N'XMKYZ-YL-[园建]-QZ-065', N'关于延展区花基、升井及地面打凿施工相关事宜', N'现场签证')
GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (4, N'XM-20241126-200', N'关于设计变更造成施工现场返工拆改的事宜', N'现场签证', N'XMKYZ-土建-[A6#栋、地下室]-QZ-052', N'关于设计变更造成施工现场返工拆改的事宜', N'现场签证')
GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (5, N'XM-20240424-162', N'关于A5负一层覆盖机房、地下室负二层泡沫罐间面积扩大事宜', N'现场签证', N'XMKYZ-TJ-[地下室]-QZ-047', N'关于A5负一层5G覆盖机房、地下室负二层泡沫罐间面积扩大事宜', N'现场签证')
GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (6, N'XM-20220602-69', N'关于样板房E、D户型雨棚更改事宜', N'现场签证', N'XMKYZ-TJ-[售楼部]-QZ-004', N'关于样板房E、D户型雨棚更改事宜', N'现场签证')
GO
INSERT [dbo].[待修复联系单20250516] ([序号], [联系单编号], [联系单名称], [联系单类型], [变更编号], [变更名称], [变更类型]) VALUES (7, N'BYH项外-2021（20）号', N'关于三个集装箱采购事宜', N'现场签证', N'XMKYZ-TJ-[公交车站]-QZ-021', N'关于三个集装箱采购事宜', N'现场签证')
GO


-- 备份数据
SELECT  * INTO cb_LocaleAlterApply_bak20250516 FROM  cb_LocaleAlterApply

--查询数据
SELECT a.ContractItemGUID,a.Name,alt.AlterGUID,alt.x_ContractItemGUID,alt.x_ContractItemName 
FROM  cb_ContractItem a
INNER JOIN [待修复联系单20250516] b ON a.[Code] =b.[联系单编号]
INNER JOIN cb_LocaleAlterApply alt ON alt.AlterCode =b.[变更编号]
WHERE alt.x_ContractItemGUID IS NULL 


-- 修复：将现场签证同联系单关联
UPDATE alt   SET  alt.x_ContractItemGUID =a.ContractItemGUID,alt.x_ContractItemName =a.Name
FROM  cb_ContractItem a
INNER JOIN [待修复联系单20250516] b ON a.[Code] =b.[联系单编号]
INNER JOIN cb_LocaleAlterApply alt ON alt.AlterCode =b.[变更编号]
WHERE alt.x_ContractItemGUID IS NULL 