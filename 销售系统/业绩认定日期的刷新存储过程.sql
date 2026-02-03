USE [dotnet_erp60]
GO
/****** Object:  StoredProcedure [dbo].[PROC_S_UpdateRoomYeJi]    Script Date: 2025/5/30 11:16:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[PROC_S_UpdateRoomYeJi]
AS
BEGIN

/*
处理逻辑：主要涉及处理场景：退房、换房、新签、回款>10%
1  退房
1.1退房时间发生在今年，若有效的业绩认定日期在今年，则作废有效的业绩认定日期
1.2退房时间发生在今年，若有效的业绩认定日期在往年，则不处理
2  换房
--2.1  换房时间发生在今年，换出房间业绩认定日期为空，换入房间业绩认定日期为空，则插入换入房间业绩认定记录
--2.2  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期为空，则换出不变，新增换入房间业绩认定日期为换房执行时间
--2.3  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期今年，则换出不变；换入作废历史，新增换入房间业绩认定日期为换房执行时间
--2.4  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期去年，则换出不变，换入不变
--2.5  换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期为空，则换出作废，新增换入房间业绩认定日期为换出房间业绩认定日期
--2.6   换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期去年，则换出作废，换入不变
--2.7   换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期今年，则换出作废；换入作废历史，新增换入房间业绩认定日期为换出房间业绩认定日期
3 新签
3.1 新签房间无业绩认定日期,已收房款大于10%,则插入一条新增的业绩认定，业绩认定日期为签约日期
3.2 新签房间无业绩认定日期，已收房款小于10%,则不插入业绩认定数据
3.3 新签房间业绩认定日期在往年，则不处理
3.4 新签房间业绩认定日期在今年，则作废历史，插入新的
4 回款
4.1 新签房间无业绩认定日期，已收房款首次大于10%，则插入一条新增的业绩认定，业绩认定日期为当前收款日期

@20241030 edit by tangqn01
调整规则
签约日期（网签日期）在2024年11月1日及以后，
且项目所属公司在【城实公司、芳实公司、卓盈公司、湖南公司、安徽公司、侨房公司、城德公司、珠江建设】，
BUGUID IN ('709FCCC6-C47B-4761-9FBD-08DBA809E17C','8D97B491-D08B-4AA0-7A1F-08DC90A2FD61','1D716088-8A38-43FE-2CC6-08DCA05A50FA','F2F6996C-E6C9-4A2F-383F-08DCA05A50FA',
'44120972-185B-E411-902B-40F2E92B3FDD','2C8AFE08-EA4E-E611-B3D3-40F2E92B3FDD','DA9A38E3-0AAE-E511-B4AF-40F2E92B3FDD','71CAAFE7-05EF-4A82-A1C7-9F132AD1E6C3','0CFB9DDF-9A78-4CD3-AFDA-9E106C941376')
回款比例要求在15%及以上，才算有效业绩。其它项目10%（保持不变）

@20250108 edit by tangqn01
调整规则
1、转网签后撤销签约的房间要作废业绩认定日期
2、转网签后修改网签日期的对应业绩认定日期要处理
3、增加业绩认定场景字段和业绩认定作废场景字段
ALTER TABLE x_p_roomyeji ADD x_YeJiScene varchar(250) NULL;
ALTER TABLE x_p_roomyeji ADD x_ZfScene varchar(250) NULL;
*/
--1、转网签后撤销签约的房间要作废业绩认定日期
select 
    c.TradeGUID,
    c.RoomGUID,
    c.ContractGUID,
    c.CloseDate,
    yj.x_YeJiTime,
    yj.x_zfbz,
    yj.roomyejiGUID
into #cxqy
from s_Contract c
inner join x_p_roomyeji yj on yj.x_RoomGUID = c.RoomGUID and yj.x_zfbz ='激活' and yj.x_TradeGUID = c.TradeGUID and yj.x_ContractGUID = c.ContractGUID and year(yj.x_YeJiTime) = year(GETDATE())
where CloseReason ='撤销签约' 
    and ContractType ='网签'
    and year(CloseDate) = year(GETDATE());

UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
INNER JOIN #cxqy b on a.roomyejiGUID = b.roomyejiGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(a.x_YeJiTime) = year(GETDATE());

--2、转网签后修改网签日期的对应业绩认定日期要处理
SELECT 
    l.AfterModification,
    l.BeforeModification,
    l.AttributeText,
    l.AttributeName,
    l.ChangeDate,
    yj.roomyejiGUID,
	yj.x_YeJiTime
into #xgqyrq
FROM s_ModifyLog l
INNER JOIN s_Contract c ON l.SaleGUID = c.ContractGUID AND c.Status ='激活'
INNER JOIN x_p_roomyeji yj on yj.x_RoomGUID = c.RoomGUID and yj.x_zfbz ='激活' and yj.x_TradeGUID = c.TradeGUID and yj.x_ContractGUID = c.ContractGUID
WHERE l.AttributeText ='网签日期' 
    and l.AttributeName ='NetContractDate'
    and convert(varchar(10),l.BeforeModification,120) = convert(varchar(10),yj.x_YeJiTime,120)
    and year(yj.x_YeJiTime) = year(GETDATE())
    and convert(varchar(10),l.ChangeDate,120) = convert(varchar(10),GETDATE(),120);

UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
INNER JOIN #xgqyrq b on a.roomyejiGUID = b.roomyejiGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(a.x_YeJiTime) = year(GETDATE());

--0 公用表，签约日期在本年的房间回款比例符合10%的房间,需考虑往年签约今年回款比例达到10%的房间
--签约日期处理逻辑：草签日期 x_InitialledDate 网签日期 NetContractDate 二者取最小的日期作为签约日期
--过滤已有有效认定的记录
--@20241030 edit by tangqn01
--增加回款比例限制要求
SELECT 
    g.RoomGUID,
    t.TradeGUID,
    c.ContractGUID,
	c.CjRmbTotal,
    c.BUGUID,
	SUM(g.RmbAmount) AS RmbAmount
INTO #hk
FROM dbo.s_Getin g
INNER JOIN dbo.s_Voucher v ON g.VouchGUID = v.VouchGUID AND ISNULL(v.VouchStatus,'') <> '作废' --AND v.AuditDate IS NOT NULL
LEFT JOIN s_FeeItem feeItem ON feeItem.FeeItemGUID = g.ItemNameGUID
INNER JOIN dbo.s_Contract c ON g.SaleGUID = c.TradeGUID AND c.Status ='激活'
INNER JOIN dbo.s_Trade t ON t.TradeGUID = c.TradeGUID  AND t.TradeStatus = '激活' AND t.ContractGUID = c.ContractGUID
WHERE ISNULL(g.status,'') <>'作废'
AND g.SaleType =  '交易'
--AND g.ItemType LIKE '%房款%'
AND g.ItemType IN ('贷款类房款', '非贷款类房款','补充协议款')
AND ISNULL(feeItem.IsFk, 0) = 1
AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE yj.x_RoomGUID = c.RoomGUID AND yj.x_TradeGUID = c.TradeGUID AND yj.x_ContractGUID = c.ContractGUID AND yj.x_zfbz ='激活')
--AND YEAR(CASE WHEN c.x_InitialledDate > c.NetContractDate THEN c.NetContractDate ELSE c.x_InitialledDate END) = YEAR(GETDATE())
GROUP BY 
	g.RoomGUID,
    t.TradeGUID,
    c.ContractGUID,
	c.BUGUID,
	c.CjRmbTotal
HAVING SUM(g.RmbAmount)/c.CjRmbTotal >= 0.095;

--签约日期（网签日期）在2024年11月1日及以后，且项目所属公司在【城实公司、芳实公司、卓盈公司、湖南公司、安徽公司、侨房公司、城德公司、珠江建设、程锦公司】，回款比例要求在15%及以上，才算有效业绩。其它项目10%（保持不变）
delete from #hk where BUGUID IN (
    '709FCCC6-C47B-4761-9FBD-08DBA809E17C','8D97B491-D08B-4AA0-7A1F-08DC90A2FD61',
    '1D716088-8A38-43FE-2CC6-08DCA05A50FA','F2F6996C-E6C9-4A2F-383F-08DCA05A50FA',
    '44120972-185B-E411-902B-40F2E92B3FDD','2C8AFE08-EA4E-E611-B3D3-40F2E92B3FDD',
    'DA9A38E3-0AAE-E511-B4AF-40F2E92B3FDD','71CAAFE7-05EF-4A82-A1C7-9F132AD1E6C3',
    '0CFB9DDF-9A78-4CD3-AFDA-9E106C941376','ADFA37CD-7FEE-4C34-99EE-08DD01CAD6A3'
)
and RmbAmount/CjRmbTotal < 0.145;

--1退房 
--1.1  退房时间发生在今年，若有效的业绩认定日期在今年，则作废有效的业绩认定日期
SELECT
    c.RoomGUID,
	c.Status,
    r.BUGUID,
    r.ProjGUID,
    r.BldGUID,
    c.TradeGUID,
    c.ContractGUID,
	y.x_YeJiTime,
	s.ExecDate,
    c.x_InitialledDate,
    c.NetContractDate,
    --CASE WHEN c.x_InitialledDate > c.NetContractDate THEN c.NetContractDate ELSE c.x_InitialledDate END AS QsDate --网签日期
    c.NetContractDate AS QsDate --网签日期
INTO #tf
from s_Contract c 
INNER JOIN s_SaleModiApply s on c.ContractGUID = s.SaleGUID and s.ApplyType='退房' AND s.ApplyStatus ='已执行'
INNER JOIN s_Room r on r.RoomGUID = c.RoomGUID
LEFT JOIN dbo.x_p_roomyeji y ON y.x_RoomGUID = c.RoomGUID and y.x_TradeGUID = c.TradeGUID and y.x_ContractGUID = c.ContractGUID AND ISNULL(y.x_zfbz,'激活') = '激活'
where c.CloseReason = '退房'
AND YEAR(s.ExecDate) = YEAR(GETDATE()) --退房执行日期在今年
AND YEAR(y.x_YeJiTime) = YEAR(GETDATE()); 

UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #tf b on a.x_RoomGUID = b.RoomGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(b.x_YeJiTime) = year(GETDATE());

--2  换房
--2.1  换房时间发生在今年，换出房间业绩认定日期为空，换入房间业绩认定日期为空，则插入换入房间业绩认定记录
--2.2  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期为空，则换出不变，插入换入
--2.3  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期今年，则换出不变；换入作废历史，插入新的
--2.4  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期去年，则换出不变，换入不变
--2.5  换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期为空，则换出作废，插入换入
--2.6  换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期去年，则换出作废，换入不变
--2.7  换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期今年，则换出作废；换入作废历史，插入新的
--
SELECT
	c.RoomGUID AS OldRoomGUID,
	y.x_YeJiTime AS OldRoomYeJiTime,
	s.ExecDate,
	c1.ContractGUID,
	c1.TradeGUID,
	c1.RoomGUID AS NewRoomGUID,
    r.BUGUID,
    r.ProjGUID,
    r.BldGUID,
	c1.Status,
    c1.BldArea,
    c1.TnArea,
    r.RoomInfo,
    r.RoomNo AS RoomCode,
    c1.CjRmbTotal,
	y1.x_YeJiTime AS NewRoomYeJiTime
INTO #hf
from s_Contract c --旧合同
INNER JOIN s_SaleModiApply s on c.ContractGUID = s.SaleGUID and s.ApplyType='换房' AND s.ApplyStatus ='已执行'
INNER JOIN s_SaleModiRoom smr on smr.SaleModiApplyGUID = s.SaleModiApplyGUID
INNER JOIN s_Contract c1 on s.NewSaleGUID = c1.ContractGUID --新合同
INNER JOIN s_Trade t on t.TradeGUID = c1.TradeGUID
INNER JOIN s_Room r on r.RoomGUID = c1.RoomGUID
LEFT JOIN #hk hk on hk.TradeGUID = c1.TradeGUID and hk.ContractGUID = c1.ContractGUID and hk.RoomGUID = c1.RoomGUID
LEFT JOIN dbo.x_p_roomyeji y ON y.x_RoomGUID = c.RoomGUID AND ISNULL(y.x_zfbz,'激活') = '激活'and y.x_TradeGUID = c.TradeGUID and y.x_ContractGUID = c.ContractGUID
LEFT JOIN dbo.x_p_roomyeji y1 ON y1.x_RoomGUID = c1.RoomGUID AND ISNULL(y1.x_zfbz,'激活') = '激活' and y.x_TradeGUID = c1.TradeGUID and y.x_ContractGUID = c1.ContractGUID
WHERE c.CloseReason = '换房'
AND YEAR(s.ExecDate)>= YEAR(GETDATE());

--2.1  换房时间发生在今年，换出房间业绩认定日期为空，换入房间业绩认定日期为空，则插入换入房间业绩认定记录
--不处理，作为新增处理
--2.2  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期为空，则换出不变，新增换入房间业绩认定日期为换房执行时间
INSERT INTO  x_p_roomyeji(
        CreatedGUID,
        CreatedName,
        CreatedTime,
        ModifiedGUID,
        ModifiedName,
        ModifiedTime,
        roomyejiGUID,
        x_RoomGUID,
        x_BUGUID,
        x_ProjGUID,
        x_BldGUID,
        x_TradeGUID,
        x_ContractGUID,
        x_Status,--销售状态
        x_BldArea,
        x_TnArea,
        x_RoomInfo,
        x_RoomCode,        
        x_YeJiPrice,
        x_YeJiTime,
        x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    hf.NewRoomGUID, --x_RoomGUID
    hf.BUGUID, --x_BUGUID
    hf.ProjGUID, --x_ProjGUID
    hf.BldGUID, --x_BldGUID
    hf.TradeGUID AS x_TradeGUID,
    hf.ContractGUID AS x_ContractGUID,
    hf.Status AS x_Status,--销售状态
    hf.BldArea AS x_BldArea,
    hf.TnArea AS x_TnArea,
    hf.RoomInfo AS x_RoomInfo,
    hf.RoomCode AS x_RoomCode,        
    hf.CjRmbTotal AS x_YeJiPrice,
    hf.ExecDate AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #hf hf
WHERE  (YEAR(hf.OldRoomYeJiTime) < YEAR(GETDATE()) AND hf.NewRoomYeJiTime IS NULL)
AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE  yj.x_RoomGUID = hf.NewRoomGUID and yj.x_zfbz = '激活');

--2.3  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期今年，则换出不变；换入作废历史，新增换入房间业绩认定日期为换房执行时间
UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #hf b ON a.x_RoomGUID = b.NewRoomGUID
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(b.NewRoomYeJiTime) = YEAR(GETDATE()) 
    AND YEAR(b.OldRoomYeJiTime) < YEAR(GETDATE());

INSERT INTO  x_p_roomyeji(
        CreatedGUID,
        CreatedName,
        CreatedTime,
        ModifiedGUID,
        ModifiedName,
        ModifiedTime,
        roomyejiGUID,
        x_RoomGUID,
        x_BUGUID,
        x_ProjGUID,
        x_BldGUID,
        x_TradeGUID,
        x_ContractGUID,
        x_Status,--销售状态
        x_BldArea,
        x_TnArea,
        x_RoomInfo,
        x_RoomCode,        
        x_YeJiPrice,
        x_YeJiTime,
        x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    hf.NewRoomGUID, --x_RoomGUID
    hf.BUGUID, --x_BUGUID
    hf.ProjGUID, --x_ProjGUID
    hf.BldGUID, --x_BldGUID
    hf.TradeGUID AS x_TradeGUID,
    hf.ContractGUID AS x_ContractGUID,
    hf.Status AS x_Status,--销售状态
    hf.BldArea AS x_BldArea,
    hf.TnArea AS x_TnArea,
    hf.RoomInfo AS x_RoomInfo,
    hf.RoomCode AS x_RoomCode,        
    hf.CjRmbTotal AS x_YeJiPrice,
    hf.ExecDate AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #hf hf
WHERE YEAR(hf.OldRoomYeJiTime) < YEAR(GETDATE()) 
    AND YEAR(hf.NewRoomYeJiTime) =YEAR(GETDATE())
    AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE  yj.x_RoomGUID = hf.NewRoomGUID and yj.x_zfbz = '激活');

--2.4  换房时间发生在今年，换出房间业绩认定日期往年，换入房间业绩认定日期去年，则换出不变，换入不变
--无需处理
--2.5  换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期为空，则换出作废，新增换入房间业绩认定日期为换出房间业绩认定日期
UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #hf b ON a.x_RoomGUID = b.OldRoomGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(b.OldRoomYeJiTime) = YEAR(GETDATE()) 
    AND b.NewRoomYeJiTime IS NULL;

INSERT INTO  x_p_roomyeji(
        CreatedGUID,
        CreatedName,
        CreatedTime,
        ModifiedGUID,
        ModifiedName,
        ModifiedTime,
        roomyejiGUID,
        x_RoomGUID,
        x_BUGUID,
        x_ProjGUID,
        x_BldGUID,
        x_TradeGUID,
        x_ContractGUID,
        x_Status,--销售状态
        x_BldArea,
        x_TnArea,
        x_RoomInfo,
        x_RoomCode,        
        x_YeJiPrice,
        x_YeJiTime,
        x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    hf.NewRoomGUID, --x_RoomGUID
    hf.BUGUID, --x_BUGUID
    hf.ProjGUID, --x_ProjGUID
    hf.BldGUID, --x_BldGUID
    hf.TradeGUID AS x_TradeGUID,
    hf.ContractGUID AS x_ContractGUID,
    hf.Status AS x_Status,--销售状态
    hf.BldArea AS x_BldArea,
    hf.TnArea AS x_TnArea,
    hf.RoomInfo AS x_RoomInfo,
    hf.RoomCode AS x_RoomCode,        
    hf.CjRmbTotal AS x_YeJiPrice,
    hf.OldRoomYeJiTime AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #hf hf
WHERE YEAR(hf.OldRoomYeJiTime) = YEAR(GETDATE()) 
AND hf.NewRoomYeJiTime IS NULL
AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE  yj.x_RoomGUID = hf.NewRoomGUID and yj.x_zfbz = '激活');

--2.6   换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期去年，则换出作废，换入不变
UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #hf b ON a.x_RoomGUID = b.OldRoomGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(b.OldRoomYeJiTime) = YEAR(GETDATE()) 
    AND year(b.NewRoomYeJiTime) < YEAR(GETDATE());

--2.7   换房时间发生在今年，换出房间业绩认定日期今年，换入房间业绩认定日期今年，则换出作废；换入作废历史，新增换入房间业绩认定日期为换出房间业绩认定日期
UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #hf b ON a.x_RoomGUID = b.OldRoomGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(b.OldRoomYeJiTime) = YEAR(GETDATE()) 
    AND year(b.NewRoomYeJiTime) = YEAR(GETDATE());

UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #hf b ON a.x_RoomGUID = b.NewRoomGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND year(b.OldRoomYeJiTime) = YEAR(GETDATE()) 
    AND year(b.NewRoomYeJiTime) = YEAR(GETDATE());

INSERT INTO  x_p_roomyeji(
        CreatedGUID,
        CreatedName,
        CreatedTime,
        ModifiedGUID,
        ModifiedName,
        ModifiedTime,
        roomyejiGUID,
        x_RoomGUID,
        x_BUGUID,
        x_ProjGUID,
        x_BldGUID,
        x_TradeGUID,
        x_ContractGUID,
        x_Status,--销售状态
        x_BldArea,
        x_TnArea,
        x_RoomInfo,
        x_RoomCode,        
        x_YeJiPrice,
        x_YeJiTime,
        x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    hf.NewRoomGUID, --x_RoomGUID
    hf.BUGUID, --x_BUGUID
    hf.ProjGUID, --x_ProjGUID
    hf.BldGUID, --x_BldGUID
    hf.TradeGUID AS x_TradeGUID,
    hf.ContractGUID AS x_ContractGUID,
    hf.Status AS x_Status,--销售状态
    hf.BldArea AS x_BldArea,
    hf.TnArea AS x_TnArea,
    hf.RoomInfo AS x_RoomInfo,
    hf.RoomCode AS x_RoomCode,        
    hf.CjRmbTotal AS x_YeJiPrice,
    hf.OldRoomYeJiTime AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #hf hf
WHERE year(hf.OldRoomYeJiTime) = YEAR(GETDATE()) 
AND year(hf.NewRoomYeJiTime) = YEAR(GETDATE())
AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE  yj.x_RoomGUID = hf.NewRoomGUID and yj.x_zfbz = '激活');


--签约临时表
--过滤已有有效认定的记录
SELECT DISTINCT
    c.RoomGUID,
	c.Status,
    r.BUGUID,
    r.ProjGUID,
    r.BldGUID,
    c.TradeGUID,
    c.ContractGUID,
    c.BldArea,
    c.TnArea,
    r.RoomInfo,
    r.RoomNo AS RoomCode,
	y.x_YeJiTime,
    --CASE WHEN c.x_InitialledDate IS NULL  OR c.NetContractDate IS NULL THEN ISNULL(c.NetContractDate,c.x_InitialledDate) WHEN c.x_InitialledDate >  c.NetContractDate THEN  c.NetContractDate ELSE c.x_InitialledDate END AS QsDate, --网签日期
	c.NetContractDate AS QsDate, --网签日期
	c.CjRmbTotal,
    hk.RmbAmount    
INTO #xq
FROM dbo.s_Contract c 
INNER JOIN dbo.s_Trade t ON t.TradeGUID = c.TradeGUID  AND t.TradeStatus = '激活'-- AND t.PreTradeGUID IS NULL
LEFT JOIN dbo.s_Order o on c.LastSaleGUID = o.OrderGUID
INNER JOIN dbo.s_Room r on r.RoomGUID = c.RoomGUID
LEFT JOIN dbo.x_p_roomyeji y ON y.x_RoomGUID = c.RoomGUID AND ISNULL(y.x_zfbz,'激活') = '激活' and y.x_TradeGUID = c.TradeGUID and y.x_ContractGUID = c.ContractGUID
INNER JOIN #hk hk on hk.TradeGUID = c.TradeGUID and hk.ContractGUID = c.ContractGUID and hk.RoomGUID = c.RoomGUID
WHERE c.Status ='激活'
AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE  yj.x_RoomGUID = c.RoomGUID and yj.x_zfbz = '激活');

--0 回款
--0.1 新签房间无业绩认定日期，已收房款首次大于10%，则插入一条新增的业绩认定，业绩认定日期为当前收款日期
--获得首次签约时间
WITH Payment AS 
(
    SELECT 
        c.BUGUID,
        g.SaleGUID,
        t.RoomGUID,
        g.GetDate,
        c.CjRmbTotal,
        sum(g.RmbAmount) RmbAmount
    FROM dbo.s_Getin g
    INNER JOIN dbo.s_Contract c on g.SaleGUID = c.TradeGUID AND c.Status ='激活'
    INNER JOIN dbo.s_Trade t ON t.TradeGUID = c.TradeGUID  AND t.TradeStatus = '激活' AND t.ContractGUID = c.ContractGUID
    WHERE ISNULL(g.status,'') <>'作废'
    AND g.SaleType =  '交易'
    AND g.ItemType LIKE '%房款%'
    --AND YEAR(CASE WHEN c.x_InitialledDate > c.NetContractDate THEN c.NetContractDate ELSE c.x_InitialledDate END) = YEAR(GETDATE())
    GROUP BY   
        c.BUGUID,
        g.SaleGUID,
        t.RoomGUID,
        g.GetDate,
        c.CjRmbTotal
),
PaymentCTE AS (
    SELECT
        g.BUGUID,
        g.SaleGUID,
        g.GetDate,
        g.RmbAmount,
        g.CjRmbTotal,
        sum(g.RmbAmount) OVER (PARTITION BY g.SaleGUID  ORDER BY g.GetDate ASC) AS running_total
    FROM Payment g
)
SELECT
    SaleGUID,
    MIN(GetDate) AS GetDate
INTO #schk
FROM (
    SELECT
        BUGUID,
        SaleGUID,
        GetDate,
        running_total,
        running_total/CjRmbTotal AS percent_complete
    FROM
        PaymentCTE b
) AS P
WHERE P.percent_complete >= CASE WHEN P.BUGUID IN (
    '709FCCC6-C47B-4761-9FBD-08DBA809E17C','8D97B491-D08B-4AA0-7A1F-08DC90A2FD61',
    '1D716088-8A38-43FE-2CC6-08DCA05A50FA','F2F6996C-E6C9-4A2F-383F-08DCA05A50FA',
    '44120972-185B-E411-902B-40F2E92B3FDD','2C8AFE08-EA4E-E611-B3D3-40F2E92B3FDD',
    'DA9A38E3-0AAE-E511-B4AF-40F2E92B3FDD','71CAAFE7-05EF-4A82-A1C7-9F132AD1E6C3',
    '0CFB9DDF-9A78-4CD3-AFDA-9E106C941376','ADFA37CD-7FEE-4C34-99EE-08DD01CAD6A3') 
THEN 0.145 ELSE 0.095 END
GROUP BY SaleGUID

INSERT INTO  x_p_roomyeji(
    CreatedGUID,
    CreatedName,
    CreatedTime,
    ModifiedGUID,
    ModifiedName,
    ModifiedTime,
    roomyejiGUID,
    x_RoomGUID,
    x_BUGUID,
    x_ProjGUID,
    x_BldGUID,
    x_TradeGUID,
    x_ContractGUID,
    x_Status,--销售状态
    x_BldArea,
    x_TnArea,
    x_RoomInfo,
    x_RoomCode,        
    x_YeJiPrice,
    x_YeJiTime,
    x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    xq.RoomGUID, --x_RoomGUID
    xq.BUGUID, --x_BUGUID
    xq.ProjGUID, --x_ProjGUID
    xq.BldGUID, --x_BldGUID
    xq.TradeGUID AS x_TradeGUID,
    xq.ContractGUID AS x_ContractGUID,
    xq.Status AS x_Status,--销售状态
    xq.BldArea AS x_BldArea,
    xq.TnArea AS x_TnArea,
    xq.RoomInfo AS x_RoomInfo,
    xq.RoomCode AS x_RoomCode,        
    xq.CjRmbTotal AS x_YeJiPrice,
    CASE WHEN xq.QsDate <= schk.GetDate then schk.GetDate else xq.QsDate end AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #xq xq
INNER JOIN #schk schk on schk.SaleGUID = xq.TradeGUID
WHERE xq.x_YeJiTime IS NULL
AND NOT EXISTS (SELECT 1 FROM dbo.x_p_roomyeji yj WHERE  yj.x_RoomGUID = xq.RoomGUID and yj.x_zfbz = '激活');

--3 新签
--3.1 新签房间无业绩认定日期,已收房款大于10%,则插入一条新增的业绩认定，业绩认定日期为签约日期

INSERT INTO  x_p_roomyeji(
        CreatedGUID,
        CreatedName,
        CreatedTime,
        ModifiedGUID,
        ModifiedName,
        ModifiedTime,
        roomyejiGUID,
        x_RoomGUID,
        x_BUGUID,
        x_ProjGUID,
        x_BldGUID,
        x_TradeGUID,
        x_ContractGUID,
        x_Status,--销售状态
        x_BldArea,
        x_TnArea,
        x_RoomInfo,
        x_RoomCode,        
        x_YeJiPrice,
        x_YeJiTime,
        x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    xq.RoomGUID, --x_RoomGUID
    xq.BUGUID, --x_BUGUID
    xq.ProjGUID, --x_ProjGUID
    xq.BldGUID, --x_BldGUID
    xq.TradeGUID AS x_TradeGUID,
    xq.ContractGUID AS x_ContractGUID,
    xq.Status AS x_Status,--销售状态
    xq.BldArea AS x_BldArea,
    xq.TnArea AS x_TnArea,
    xq.RoomInfo AS x_RoomInfo,
    xq.RoomCode AS x_RoomCode,        
    xq.CjRmbTotal AS x_YeJiPrice,
    CASE WHEN xq.QsDate <= schk.GetDate then schk.GetDate else xq.QsDate end AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #xq xq
INNER JOIN #schk schk on schk.SaleGUID = xq.TradeGUID
LEFT JOIN dbo.x_p_roomyeji y ON y.x_RoomGUID = xq.RoomGUID and y.x_TradeGUID = xq.TradeGUID and y.x_ContractGUID = xq.ContractGUID AND ISNULL(y.x_zfbz,'激活') = '激活'
WHERE xq.x_YeJiTime IS NULL 
AND xq.RmbAmount IS NOT NULL
AND y.x_YeJiTime IS NULL;

--3.2 新签房间无业绩认定日期，已收房款小于10%,则不插入业绩认定数据
--不作处理
--3.3 新签房间业绩认定日期在往年，则不处理
--不作处理

--3.4 新签房间业绩认定日期在今年，则作废历史，插入新的
UPDATE a
    SET a.x_zfbz ='作废'
FROM x_p_roomyeji a 
JOIN #xq b ON a.x_RoomGUID = b.RoomGUID 
WHERE ISNULL(a.x_zfbz,'激活') ='激活' 
    AND YEAR(b.x_YeJiTime) = YEAR(GETDATE());

INSERT INTO  x_p_roomyeji(
        CreatedGUID,
        CreatedName,
        CreatedTime,
        ModifiedGUID,
        ModifiedName,
        ModifiedTime,
        roomyejiGUID,
        x_RoomGUID,
        x_BUGUID,
        x_ProjGUID,
        x_BldGUID,
        x_TradeGUID,
        x_ContractGUID,
        x_Status,--销售状态
        x_BldArea,
        x_TnArea,
        x_RoomInfo,
        x_RoomCode,        
        x_YeJiPrice,
        x_YeJiTime,
        x_zfbz -- 作废,激活
)
SELECT
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS CreatedGUID,
    '系统管理员' AS CreatedName,
    GETDATE() AS CreatedTime,
    '4230BC6E-69E6-46A9-A39E-B929A06A84E8' AS ModifiedGUID,
    '系统管理员' AS ModifiedName,
    GETDATE() AS ModifiedTime,
    NEWID() AS roomyejiGUID,
    xq.RoomGUID, --x_RoomGUID
    xq.BUGUID, --x_BUGUID
    xq.ProjGUID, --x_ProjGUID
    xq.BldGUID, --x_BldGUID
    xq.TradeGUID AS x_TradeGUID,
    xq.ContractGUID AS x_ContractGUID,
    xq.Status AS x_Status,--销售状态
    xq.BldArea AS x_BldArea,
    xq.TnArea AS x_TnArea,
    xq.RoomInfo AS x_RoomInfo,
    xq.RoomCode AS x_RoomCode,        
    xq.CjRmbTotal AS x_YeJiPrice,
    xq.QsDate AS x_YeJiTime,
    '激活' AS x_zfbz -- 作废,激活
FROM #xq xq
LEFT JOIN dbo.x_p_roomyeji y ON y.x_RoomGUID = xq.RoomGUID AND y.x_TradeGUID = xq.TradeGUID AND y.x_ContractGUID = xq.ContractGUID AND ISNULL(y.x_zfbz,'激活') = '激活'
WHERE YEAR(xq.x_YeJiTime) = YEAR(GETDATE())
    AND xq.RmbAmount IS NOT NULL
	AND y.x_YeJiTime IS NULL;

DROP TABLE #tf,#hf,#hk,#xq,#schk,#cxqy,#xgqyrq;
END;



