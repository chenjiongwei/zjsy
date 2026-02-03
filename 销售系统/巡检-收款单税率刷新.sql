-- 判断下款项名称是否在业务参数里面开启了固定税率，是的话按固定税率刷，否就按上面的增值税率刷

-- 查询需要刷新税率的收款单：根据是否锁定税率(x_IsLocktax)决定使用订单税率(Rate)或固定税率(x_Locktax)
select g.TaxRate as '实收款税率', r.roominfo as '房间信息', ord.Rate as '订单增值税率',
       v.VouchGUID as '单据GUID', g.GetinGUID as '实收款GUID', 
       g.itemtype as '款项类型', g.ItemName as '款项名称',case when isnull( x_IsLocktax,0)=1 then '是' else '否' end as '是否开启固定税率', x_Locktax as '固定税率'
into #getin
from s_voucher v
inner join s_Getin g on g.VouchGUID = v.VouchGUID
inner join s_FeeItem sit on sit.FeeItemGUID = g.ItemNameGUID 
inner join (
    select tradeguid, orderguid as saleguid, roomguid, Rate from s_order where status = '激活'
    union all
    select tradeguid, contractguid as saleguid, roomguid, Rate from s_contract where status = '激活'
) ord on g.SaleGUID = ord.TradeGUID
left join s_room r on ord.roomguid = r.roomguid
where (isnull(x_IsLocktax,0) = 0 and isnull(g.TaxRate,0) <> ord.Rate)
   or (isnull(x_IsLocktax,0) = 1 and isnull(g.TaxRate,0) <> isnull(x_Locktax,0))


--备份数据表
select  a.* into s_getin_bak20250710
from s_getin a
inner join  #getin b on a.GetinGUID = b.实收款GUID

-- 查询异常数据
select a.GetinGUID,a.TaxRate,a.TaxAmount,a.Amount,b.订单增值税率,b.是否开启固定税率,b.固定税率, 
   case when isnull(a.TaxAmount,0) < 0 then 0  else   a.Amount * (1- b.订单增值税率 /100.0) * b.订单增值税率 /100.0 end as '税金'
from s_getin a
inner join  #getin b on a.GetinGUID = b.实收款GUID
where  b.是否开启固定税率 ='否' and isnull(a.TaxRate,0) <> isnull(b.订单增值税率,0)

-- 修改数据
update a 
set a.TaxRate = b.订单增值税率,
    a.TaxAmount = case when isnull(a.TaxAmount,0) < 0 then 0  else   a.Amount * (1- b.订单增值税率 /100.0) * b.订单增值税率 /100.0 end
-- select a.GetinGUID,a.TaxRate,a.TaxAmount,a.Amount,b.订单增值税率,b.是否开启固定税率,b.固定税率, 
--    case when isnull(a.TaxAmount,0) < 0 then 0  else   a.Amount * (1- b.订单增值税率 /100.0) * b.订单增值税率 /100.0 end as '税金'
from s_getin a
inner join  #getin b on a.GetinGUID = b.实收款GUID
where  b.是否开启固定税率 ='否' and isnull(a.TaxRate,0) <> isnull(b.订单增值税率,0)

