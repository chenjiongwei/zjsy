
/*实收宽表-1.新增实收款项*/
SELECT g.GetinGUID,      --收款GUID
       g.VouchGUID,      --单据GUID
       g.SaleGUID,       --销售单GUID
       g.ItemType,       --款项类型
       g.ItemName,       --款项名称
       g.IsSysCx,        --是否冲销
       case when charindex('楼款',g.ItemName)>0 then '楼款'
            when charindex('首期',g.ItemName)>0 then '首期'
            when charindex('定金',g.ItemName)>0 then '定金'
            else '其他' end as Report_ItemName,     --款项名称（模糊匹配）
       g.ItemNameGUID,   --款项名称GUID
	   feeItem.FeeItemCode AS ItemCode,       --款项排序Code
       TopFeeItem.FeeItemCode AS TopItemCode,       --一级款项排序Code
       TopFeeItem.FeeItemGUID AS TopItemNameGUID,   --一级款项名称GUID
       g.Amount,         --收款金额
       g.RmbAmount,      --收款金额(人民币)
       g.RzBank,         --入账银行
       g.GetForm,        --支付方式
       g.PosCode,        --POS单号
       g.PosAmount,      --POS机手续费
       g.TaxAmount,      --税额
       /*增加财务认定口径的实收款日期*/
	    CASE 
            WHEN v.VouchType ='退款单' THEN  isnull (v.rzdate, v.KpDate)
            WHEN v.VouchType ='转账单' THEN  v.KpDate
            WHEN v.VouchType ='换票单' THEN  case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end 
            WHEN v.VouchType ='收款单' THEN 
            CASE 
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end ) >= 2024 AND g.GetForm  NOT LIKE '%POS%' THEN case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) >= 2024 AND g.GetForm  LIKE '%POS%'  AND  pp.ProjName IN ('珠江花玙苑','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心')  AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) >= 2024 AND g.GetForm  LIKE '%POS%'  AND  pp.ProjName IN ('珠江花玙苑','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','珠江金悦','中侨中心')  AND wd.x_NextWorkDate IS  NULL THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) ,23)
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) >= 2024 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName  IN ('珠江海珠里','珠江嘉园','时光荟','同嘉路项目','钟落潭项目')   THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) ,23)
                    
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) = 2023 AND g.GetForm  NOT LIKE '%POS%' THEN case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江花玙苑','花屿花城','西关都荟','荷景路项目','白云湖项目','广州珠江花城项目','同嘉路项目','钟落潭项目','珠江海珠里','珠江嘉园','时光荟') THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) ,23)
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江金悦','中侨中心') AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
                    WHEN YEAR(case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) = 2023 AND g.GetForm  LIKE '%POS%'  AND pp.ProjName IN ('珠江金悦','中侨中心') AND  wd.x_NextWorkDate IS  NULL THEN  CONVERT(VARCHAR ,DATEADD(DAY, 1, case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end) ,23)
            ELSE case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end END ELSE case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end END AS CWSKDate,

       /* 款项等于定金时，收款日期为转账单的实收日期 */
       case when g.ItemName = '定金' and v.VouchType = '转账单' then v.SkDate else g.GetDate end as SkDate, --收款日期
            /*  CASE WHEN g.GetForm LIKE '%POS%' AND wd.x_NextWorkDate IS NOT NULL THEN CONVERT(VARCHAR,wd.x_NextWorkDate,23) 
			 WHEN g.GetForm LIKE '%POS%' AND wd.x_NextWorkDate IS  NULL THEN CONVERT(VARCHAR ,DATEADD(DAY, 1, g.GetDate) ,23)
			 ELSE CONVERT(VARCHAR , g.GetDate ,23)  END AS HKdate,--回款到账日期 */
       g.RoomGUID,       --房间GUID
       g.PosGUID,        --银行回单GUID
       g.BeforeRmbYe,    --对冲前人民币余额
       g.TaxRate         --
FROM   s_Getin g
left join  p_project p on p.p_projectId = g.projguid
left join  p_project pp on pp.p_projectId = p.ParentGUID
left join  x_HoliDayDetial wd on CONVERT(VARCHAR ,DATEADD(DAY, 1, g.GetDate) ,23)  = CONVERT(VARCHAR,wd.x_vacationDate,23)
inner join s_voucher v on v.VouchGUID = g.VouchGUID
	   LEFT JOIN s_FeeItem feeItem
           ON g.ItemNameGuid = feeItem.FeeItemGUID
	   LEFT JOIN s_FeeItem TopFeeItem
           ON TopFeeItem.FeeItemGUID = feeItem.ParentGUID
       	 --  LEFT JOIN x_HoliDayDetial wd ON CONVERT(VARCHAR ,DATEADD(DAY, 1, g.GetDate) ,23)  = CONVERT(VARCHAR,wd.x_vacationDate,23)




/*实收宽表-3.单据信息*/
SELECT g.GetinGUID,                                                                --收款GUID
       CASE WHEN v.VouchType = '划拨单'
                 OR v.VouchType = 'POS机单' THEN '其他'
       WHEN v.SaleGUID IS NULL
            AND v.SaleType IS NOT NULL THEN '预收款'
       WHEN t.TradeGUID IS NOT NULL
            OR v.VouchType = '放款单' THEN '交易' ELSE g.SaleType END   SaleType,       --交易类型
  CASE WHEN t.TradeGUID IS  NULL THEN NULL
  WHEN t.ZcOrderDate IS NOT NULL THEN t.ZcOrderDate 
  ELSE t.ZcContractDate       END   ZcQsDate,         --最初签署日期
       v.Jkr,                                                                      --交款人
       v.kpr,                                                                      --开票人
       v.InvoType,                                                                 --票据类型
       v.InvoNO,                                                                   --票据号码
       v.AuditDate,                                                                --审核日期
       v.VouchType,                                                                --单据类型
	   v.AuditName,
    v.KpDate,
    v.SkDate AS VskDate,
       CASE WHEN v.VouchType = '划拨单' THEN '划出'
       WHEN v.VouchStatus IS NULL
            OR v.VouchStatus = '' THEN '激活' ELSE v.VouchStatus END AS VouchStatus, --单据状态
       v.Remark,v.RzDate,v.IsExport,v.IsNeedCreatePz                                                               --备注
FROM   s_Getin              g
       INNER JOIN s_Voucher v
           ON g.VouchGUID = v.VouchGUID
       LEFT JOIN s_Booking  b
           ON g.SaleGUID = b.BookingGUID
       LEFT JOIN s_Trade    t
           ON g.SaleGUID = t.TradeGUID
