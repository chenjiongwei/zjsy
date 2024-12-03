SELECT 
	e.projshortname AS 项目名称,
	d.projshortname AS 组团名称,
	f.bldname AS 楼栋,
	c.room AS 房号,
	c.Roominfo AS 房间全名,
	a.BuyerAllNames AS 客户名称,
	i.Jkr AS 交款人,
	isnull(h.SaleType,'预收款') AS 交易类型,
	h.GetDate AS 收款日期,
	i.KpDate AS 开票日期,
	i.VouchType AS 票据类型,
	i.InvoNO AS 票据编号,
	h.ItemType AS 款项类型,
	h.ItemName AS 款项名称,
	h.Bz AS 币种,
	h.Amount AS 金额,
	h.ExRate AS 汇率,
	h.RmbAmount AS 折人民币金额,
	h.GetForm AS 支付方式,
	'' AS 摘要,
	h.RzBank AS 入账银行,
	h.PosTerminal AS 刷卡终端,
	h.PosCode AS POS单号,
	'' AS 银行卡,
	h.FsettlCode AS 结算方式,
	h.FsettleNo AS 结算单号,
	h.GetForm AS 银付方式,
	i.Kpr AS 开票人,
	i.Remark AS 备注,
	CONVERT(varchar(100), i.AuditDate, 23) AS 审核日期,
    h.TaxRate AS 税率,
    h.TaxAmount AS 税额 
FROM s_Getin h 
LEFT JOIN s_Trade AS a ON h.saleguid = a.TradeGUID AND isnull(h.status,'')<>'作废'
LEFT JOIN s_Voucher AS i ON i.VouchGUID = h.VouchGUID AND isnull(i.VouchStatus,'')<>'作废'
LEFT JOIN s_Booking AS g ON g.BookingGUID = i.SaleGUID AND i.SaleType = '预约单'
LEFT JOIN s_room AS c ON c.RoomGUID = h.RoomGUID
LEFT JOIN p_project AS d ON d.p_projectId = i.projguid
LEFT JOIN p_project AS e ON e.p_projectId = d.ParentGUID
LEFT JOIN s_Building AS f ON f.bldguid = c.bldguid
WHERE isnull(h.Status,'') <> '作废' AND (a.tradestatus='激活' OR isnull(g.Status,'') <> '作废') 
--AND a.ProjGUID IN (@var_projguid)
AND EXISTS(SELECT 1 FROM dbo.p_project pp WHERE pp.ParentGUID IN (@var_projguid) AND pp.p_projectId = h.ProjGUID)
AND i.KpDate >= @var_startdate AND i.KpDate <= @var_enddate
ORDER BY e.projshortname,d.projshortname,f.bldname,c.room,h.GetDate


---、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、、
WITH
    --正常收退款
    GetInOut
    AS
    (
        SELECT
            e.projshortname AS 项目名称,
            d.projshortname AS 组团名称,
            f.bldname AS 楼栋,
            c.room AS 房号,
            c.Roominfo AS 房间全名,
            a.BuyerAllNames AS 客户名称,
            i.Jkr AS 交款人,
            isnull(h.SaleType,'预收款') AS 交易类型,
            h.GetDate AS 收款日期,
            i.KpDate AS 开票日期,
            i.VouchType AS 票据类型,
            i.InvoNO AS 票据编号,
            h.ItemType AS 款项类型,
            h.ItemName AS 款项名称,
            h.Bz AS 币种,
            h.Amount AS 金额,
            h.ExRate AS 汇率,
            h.RmbAmount AS 折人民币金额,
            h.GetForm AS 支付方式,
            '' AS 摘要,
            h.RzBank AS 入账银行,
            h.PosTerminal AS 刷卡终端,
            h.PosCode AS POS单号,
            '' AS 银行卡,
            h.FsettlCode AS 结算方式,
            h.FsettleNo AS 结算单号,
            h.GetForm AS 银付方式,
            i.Kpr AS 开票人,
            i.Remark AS 备注,
            CONVERT(varchar(100), i.AuditDate, 23) AS 审核日期,
            h.TaxRate AS 税率,
            h.TaxAmount AS 税额
        FROM s_Getin h
            LEFT JOIN s_Trade AS a ON h.saleguid = a.TradeGUID AND isnull(h.status,'')<>'作废'
            LEFT JOIN s_Voucher AS i ON i.VouchGUID = h.VouchGUID AND isnull(i.VouchStatus,'')<>'作废'
            LEFT JOIN s_Booking AS g ON g.BookingGUID = i.SaleGUID AND i.SaleType = '预约单'
            LEFT JOIN s_room AS c ON c.RoomGUID = h.RoomGUID
            LEFT JOIN p_project AS d ON d.p_projectId = i.projguid
            LEFT JOIN p_project AS e ON e.p_projectId = d.ParentGUID
            LEFT JOIN s_Building AS f ON f.bldguid = c.bldguid
            LEFT JOIN s_TaxInvoice AS j ON j.Glsk = i.VouchGUID AND j.ChInvoNO IS NULL
        WHERE isnull(h.Status,'') <> '作废' AND (a.tradestatus='激活' OR isnull(g.Status,'') <> '作废') AND
            ISNULL(h.IsSysCx,0) <> 1 AND h.ProjGUID IN (@var_projguid) AND i.KpDate >= @var_startdate AND i.KpDate <= @var_enddate
    ),
    --换票冲销
    HPCX
    AS
    (
        SELECT
            e.projshortname AS 项目名称,
            d.projshortname AS 组团名称,
            f.bldname AS 楼栋,
            c.room AS 房号,
            c.Roominfo AS 房间全名,
            a.BuyerAllNames AS 客户名称,
            i.Jkr AS 交款人,
            isnull(h.SaleType,'预收款') AS 交易类型,
            h.GetDate AS 收款日期,
            j.KpDate AS 开票日期,
            j.VouchType AS 票据类型,
            i.InvoNO AS 票据编号,
            h.ItemType AS 款项类型,
            h.ItemName AS 款项名称,
            h.Bz AS 币种,
            h.Amount AS 金额,
            h.ExRate AS 汇率,
            h.RmbAmount AS 折人民币金额,
            h.GetForm AS 支付方式,
            '' AS 摘要,
            h.RzBank AS 入账银行,
            h.PosTerminal AS 刷卡终端,
            h.PosCode AS POS单号,
            '' AS 银行卡,
            h.FsettlCode AS 结算方式,
            h.FsettleNo AS 结算单号,
            h.GetForm AS 银付方式,
            j.Kpr AS 开票人,
            j.Remark AS 备注,
            CONVERT(varchar(100), j.AuditDate, 23) AS 审核日期,
            h.TaxRate AS 税率,
            h.TaxAmount AS 税额
        FROM s_Getin h
            LEFT JOIN s_Trade AS a ON h.saleguid = a.TradeGUID AND isnull(h.status,'')<>'作废'
            LEFT JOIN s_Getin AS b ON b.GetinGUID = h.PreGetinGUID
            LEFT JOIN s_Voucher AS i ON i.VouchGUID = b.VouchGUID AND isnull(i.VouchStatus,'')<>'作废'
            LEFT JOIN s_Booking AS g ON g.BookingGUID = i.SaleGUID AND i.SaleType = '预约单'
            LEFT JOIN s_room AS c ON c.RoomGUID = b.RoomGUID
            LEFT JOIN p_project AS d ON d.p_projectId = i.projguid
            LEFT JOIN p_project AS e ON e.p_projectId = d.ParentGUID
            LEFT JOIN s_Building AS f ON f.bldguid = c.bldguid
            LEFT JOIN s_Voucher AS j ON j.VouchGUID = h.VouchGUID AND isnull(i.VouchStatus,'')<>'作废'
            LEFT JOIN s_TaxInvoice AS k ON k.Glsk = i.VouchGUID AND k.ChInvoNO IS NULL
        WHERE isnull(h.Status,'') <> '作废' AND (a.tradestatus='激活' OR isnull(g.Status,'') <> '作废') AND
            ISNULL(h.IsSysCx,0) = 1 AND (j.InvoType = '收据' OR j.InvoType = '无票据') AND
            h.ProjGUID IN (@var_projguid) AND j.KpDate >= @var_startdate AND j.KpDate <= @var_enddate
    ),
    --合并
    MergeInOut
    AS
    (
            SELECT
                项目名称, 组团名称, 楼栋, 房号, 房间全名, 客户名称, 交款人, 交易类型, 收款日期, 开票日期, 票据类型, 票据编号,
                款项类型, 款项名称, 币种, 金额, 汇率, 折人民币金额, 支付方式, 摘要, 入账银行, 刷卡终端, POS单号, 银行卡,
                结算方式, 结算单号, 银付方式, 开票人, 备注, 审核日期, 税率, 税额
            FROM GetInOut
        UNION ALL
            SELECT
                项目名称, 组团名称, 楼栋, 房号, 房间全名, 客户名称, 交款人, 交易类型, 收款日期, 开票日期, 票据类型, 票据编号,
                款项类型, 款项名称, 币种, 金额, 汇率, 折人民币金额, 支付方式, 摘要, 入账银行, 刷卡终端, POS单号, 银行卡,
                结算方式, 结算单号, 银付方式, 开票人, 备注, 审核日期, 税率, 税额
            FROM HPCX
    )
SELECT 项目名称, 组团名称, 楼栋, 房号, 房间全名, 客户名称, 交款人, 交易类型, 收款日期, 开票日期, 票据类型, 票据编号,
    款项类型, 款项名称, 币种, 金额, 汇率, 折人民币金额, 支付方式, 摘要, 入账银行, 刷卡终端, POS单号, 银行卡,
    结算方式, 结算单号, 银付方式, 开票人, 备注, 审核日期, 税率, 税额
FROM MergeInOut
ORDER BY 项目名称,组团名称,楼栋,房号,收款日期