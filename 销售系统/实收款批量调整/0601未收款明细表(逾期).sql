-- 0601未收款明细表(逾期)
-- 2025-01-08 调整收款日期的取数口径
        
        SELECT  CASE WHEN ISNULL(pp.SpreadName, '') = '' THEN pp.ProjName ELSE pp.SpreadName END AS 项目推广名 ,
                p.ProjShortName AS 分区名称 ,
                f.BldName AS 楼栋名称 ,
                f.UnitNo AS 单元 ,
                f.ShortRoomInfo AS 房号 ,
                f.RoomGUID AS 房源唯一编码 ,
                f.RoomInfo AS 房间全名 ,
                ISNULL(tr.OCstAllName, tr.CCstAllName) AS 客户名称 ,
                CASE WHEN tr.CStatus = '激活' AND tr.ContractType = '网签' THEN '网签' WHEN tr.CStatus = '激活' AND tr.ContractType = '草签' THEN '草签' ELSE '认购' END AS 销售状态 ,
                r.YsBldArea AS 预售建筑面积 ,
                r.YsTnArea AS 预售套内面积 ,
                --rex.ZcRgQsDate AS 认购日期 ,
				tr.ZcOrderDate AS 认购日期 ,
                tr.x_InitialledDate AS 草签日期 ,
                -- rex.ZcContractDate AS 签约日期 ,  --首次签约日期
				tr.ZcContractGUID AS 签约日期,
                ISNULL(tr.CPayForm, tr.OPayForm) AS 付款方式名称 ,
                ISNULL(tr.CCjTotal, tr.OCjTotal) AS 成交总价 ,
                ISNULL(tr.CZygw, tr.OZygw) AS 销售员 ,
                ISNULL(tr.CProjectTeam, tr.OProjectTeam) AS 所属团队 ,
                ISNULL(tr.CCstAllTel, tr.OCstAllTel) AS 联系电话 ,
                ISNULL(tr.CAddress, tr.OAddress) AS 地址 ,
                f.ItemName AS 款项名称 ,
                ISNULL(tr.CAjBank, tr.OAjBank) AS 按揭银行 ,
                f.RmbAmount AS 应交款 ,
                f.RmbYe AS 欠款 ,
                ISNULL(f.RmbAmount, 0) + ISNULL(f.RmbDsAmount, 0) - ISNULL(f.RmbYe, 0) AS 已交款 ,
                f.LastDate AS 付款期限 ,
                CASE WHEN  f.LastDate > GETDATE() THEN  DATEDIFF(DAY,f.LastDate,GETDATE() ) ELSE  0 END  AS 逾期天数 ,
                CASE  WHEN f.ItemName ='滞纳金'   THEN  f.RmbAmount END   AS 已产生滞纳金 ,
                NULL AS 结转金额 ,
                NULL AS 未收滞纳金 ,
                f.JmLateFee AS 累计已减免滞纳金
        FROM    data_wide_s_Fee f WITH  (NOLOCK )
                INNER JOIN dbo.data_wide_mdm_Project p WITH  (NOLOCK ) ON p.p_projectId = f.ProjGUID
                INNER JOIN data_wide_mdm_Project pp WITH  (NOLOCK ) ON p.ParentGUID = pp.p_projectId AND   pp.Level = 2
                LEFT JOIN data_wide_s_Trade tr WITH  (NOLOCK ) ON tr.RoomGUID = f.RoomGUID AND tr.IsLast = 1 and f.TradeGUID =tr.TradeGUID
                INNER JOIN dbo.data_wide_s_Room r WITH  (NOLOCK ) ON r.RoomGUID = f.RoomGUID
				-- LEFT  JOIN data_wide_dws_s_roomexpand rex ON rex.RoomGUID =r.RoomGUID
        WHERE   f.ProjGUID IN(@ProjGUID) AND  ISNULL(f.RmbYe, 0) > 0
        and datediff(dd,f.lastdate,getdate())>0
		AND  f.TradeStatus ='激活' and tr.ContractType=@ContractType and
		(case when datediff(dd,f.lastdate,getdate())<=7 then '逾期7天内' 
		     when datediff(dd,f.lastdate,getdate()) between 8 and 30 then '逾期7-30天'  
		     when datediff(dd,f.lastdate,getdate()) between 31 and 90 then '逾期30-90天'  
				 when datediff(dd,f.lastdate,getdate()) between 91 and 180 then '逾期90-180天'  
				 when datediff(dd,f.lastdate,getdate())>180 then '逾期180天以上'  
	  end=@yqtype or @yqtype='逾期待回款')