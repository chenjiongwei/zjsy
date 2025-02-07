    -- 2024-12-11 chenjw 增加01考核汇总表的“本年至今回笼金额”字段的穿透明细表
IF  @版本号='实时' 
 BEGIN
    SELECT  
    null as SnapshotTime,
    '实时' as VersionNo,
    st.BUGUID as 公司GUID,
    g.ParentProjGUID AS ProjGUID, --父级项目GUID
    g.ParentProjName AS 项目名称, --父级项目名称
    g.ProjName AS 分期名称, --项目名称
    g.RoomInfo as 房间信息, 
    convert(nvarchar(10),st.CQsDate,111) AS 签约日期,
    v.vouchtype as 单据类型,
    g.ItemType as 款项类型,
    g.ItemName as 款项名称,
    g.SkDate as 收款日期,
    g.Jkr as 交款人,
   -- SUM(ISNULL(g.RmbAmount,0)/ 10000.0 ) AS 累计回笼日期, 
    ISNULL(g.RmbAmount,0) / 10000.0   AS 本年至今回笼金额  --本年至今回笼金额
    FROM   data_wide_s_Getin g WITH(NOLOCK)
    LEFT JOIN data_wide_s_Voucher v WITH(NOLOCK)ON g.VouchGUID = v.VouchGUID
    LEFT join data_wide_s_trade st on g.SaleGUID=st.tradeguid and (st.cstatus='激活' or st.ostatus='激活')
    WHERE isnull(g.VouchStatus,'') <> '作废' 
	AND  g.ItemType IN ('贷款类房款', '非贷款类房款','补充协议款' ) --and g.ItemName !='诚意金'
	AND	 g.VouchType not in ('POS机单','划拨单','放款单')
    and  DATEDIFF(YEAR, ISNULL(g.CWSkDate,0), GETDATE()) = 0    and  st.BUGUID in (@buguid) and g.ParentProjGUID in (@Projguid) 
end 
ELSE
BEGIN
    SELECT  
        [SnapshotTime],
        [VersionNo],
        [公司GUID],
        [ProjGUID],
        [项目名称],
        [分期名称],
        [房间信息],
        [签约日期],
        [单据类型],
        [款项类型],
        [款项名称],
        [收款日期],
        [交款人],
        [本年至今回笼金额]
    from   Result_ThisYearGetAmountDetail
    where [VersionNo] = @版本号
        and [ProjGUID] in (@ProjGUID)
END