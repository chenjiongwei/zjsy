

/*
前期《关于珠江花城项目四期住宅逾期缴款客户处理的请示》签报已经审批通过，非客户原因导致逾期缴款情况且累计逾期未超过5个月的共22户房源。根据请示精神，对以上符合制度的延期缴款房源，在明源系统进行后台批
量执行缴款延期处理
*/

-- 查询款项的应收日期
SELECT f.TradeGUID,
f.FeeGUID,
       f.Amount,
	   f.ItemName,
	   f.ItemType,
	   f.lastDate
FROM s_Fee f
    INNER JOIN s_Contract c
        ON c.TradeGUID = f.TradeGUID
WHERE c.ContractGUID = 'e3273c38-6216-ee11-a748-005056a53239' AND f.ItemName  ='二期首期'

--修改款项的应收日期
UPDATE s_Fee SET lastDate = '2023/12/24' WHERE FeeGUID = '3E8518AD-67FC-ED11-A748-005056A53239'

-- 修改对冲表中对应款项的应收日期
UPDATE s_Cwfx SET YsDate ='2023-12-24' FROM  dbo.s_Cwfx  WHERE  TradeGUID = '2D8518AD-67FC-ED11-A748-005056A53239'
AND   YsItemNameGuid ='8890B2C3-37EA-4115-8A71-4F601C2EA7FC'