-- 05实收款项汇总表
-- 2025-01-08 调整收款日期的取数口径

-- 创建临时表存储应收情况
select * into #应收情况 from
(
    -- 按项目分组统计应收款项
    select 
        sf.projguid,                                                                  -- 项目GUID
        sum(sf.RmbAmount) as 应收总额,                                               -- 应收总额
        sum(sf.RmbYe) as 未收总额,                                                   -- 未收总额
        
        -- 按款项类型统计应收笔数和金额
        sum(case when sf.itemtype='非贷款类房款' then 1 end) as 非贷款类房款应收笔数,
        sum(case when sf.itemtype='非贷款类房款' then sf.Rmbamount end) as 非贷款类房款应收金额,
        sum(case when sf.itemtype='贷款类房款' then 1 end) as 贷款类房款应收笔数,
        sum(case when sf.itemtype='贷款类房款' then sf.RmbAmount end) as 贷款类房款应收金额,
        sum(case when sf.itemtype='代收费用' then 1 end) as 代收费用应收笔数,
        sum(case when sf.itemtype='代收费用' then sf.RmbAmount end) as 代收费用应收金额,
        sum(case when sf.itemtype='其它' then 1 end) as 其他款项应收笔数,
        sum(case when sf.itemtype='其它' then sf.RmbAmount end) as 其他款项应收金额,
        sum(case when sf.itemtype='补充协议款' then 1 end ) as 补充协议款应收笔数,
        sum(case when sf.itemtype='补充协议款' then sf.RmbAmount end) as 补充协议款应收金额,

        -- 本年度应收统计
        sum(case when year(sf.lastdate)=@年份 then sf.RmbAmount end) as 本年应收,
        sum(case when year(sf.lastdate)=@年份 then sf.RmbYe end) as 本年应收未收,
        sum(case when year(sf.lastdate)=@年份 and sf.itemname like '%首期%' then sf.RmbYe end) as 本年首期应收未收,
        sum(case when year(sf.lastdate)=@年份 and sf.itemname like '%楼款%' then sf.RmbYe end) as 本年楼款应收未收,
        sum(case when year(sf.lastdate)=@年份 and sf.itemname like '%银行按揭%' then sf.RmbYe end) as 本年按揭应收未收,
        sum(case when year(sf.lastdate)=@年份 and sf.itemname like '%公积金%' then sf.RmbYe end) as 本年公积金应收未收,
        sum(case when year(sf.lastdate)=@年份 and sf.itemname like '%其他%' then sf.RmbYe end) as 本年其他应收未收,
        sum(case when year(sf.lastdate)=@年份 and sf.itemtype='补充协议款' then sf.RmbYe end) as 本年补充应收未收,

        -- 按月份统计应收和未收金额
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=1 then sf.RmbAmount end) as 一月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=1 then sf.RmbYe end) as 一月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=2 then sf.RmbAmount end) as 二月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=2 then sf.RmbYe end) as 二月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=3 then sf.RmbAmount end) as 三月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=3 then sf.RmbYe end) as 三月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=4 then sf.RmbAmount end) as 四月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=4 then sf.RmbYe end) as 四月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=5 then sf.RmbAmount end) as 五月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=5 then sf.RmbYe end) as 五月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=6 then sf.RmbAmount end) as 六月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=6 then sf.RmbYe end) as 六月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=7 then sf.RmbAmount end) as 七月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=7 then sf.RmbYe end) as 七月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=8 then sf.RmbAmount end) as 八月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=8 then sf.RmbYe end) as 八月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=9 then sf.RmbAmount end) as 九月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=9 then sf.RmbYe end) as 九月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=10 then sf.RmbAmount end) as 十月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=10 then sf.RmbYe end) as 十月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=11 then sf.RmbAmount end) as 十一月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=11 then sf.RmbYe end) as 十一月应收未收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=12 then sf.RmbAmount end) as 十二月应收,
        sum(case when year(sf.lastdate)=@年份 and month(sf.lastdate)=12 then sf.RmbYe end) as 十二月应收未收
    from data_wide_s_fee sf 
    inner join data_wide_s_trade t on sf.tradeguid = t.TradeGUID and (t.cstatus='激活' or t.ostatus='激活')
    group by sf.projguid
) tt

-- 创建临时表存储实收情况
select * into #实收情况 from
(
    -- 按项目分组统计实收款项
    select 
        sg.projguid,                                                                  -- 项目GUID
        sum(sg.RmbAmount) as 实收总额,                                               -- 实收总额

        -- 按款项类型统计实收笔数和金额
        sum(case when sg.itemtype='非贷款类房款' then 1 end) as 非贷款类房款实收笔数,
        sum(case when sg.itemtype='非贷款类房款' then sg.RmbAmount end) as 非贷款类房款实收金额,
        sum(case when sg.itemtype='贷款类房款' then 1 end) as 贷款类房款实收笔数,
        sum(case when sg.itemtype='贷款类房款' then sg.RmbAmount end) as 贷款类房款实收金额,
        sum(case when sg.itemtype='代收费用' then 1 end) as 代收费用实收笔数,
        sum(case when sg.itemtype='代收费用' then sg.RmbAmount end) as 代收费用实收金额,
        sum(case when sg.itemtype='其它' then 1 end) as 其他款项实收笔数,
        sum(case when sg.itemtype='其它' then sg.RmbAmount end) as 其他款项实收金额,
        sum(case when sg.itemtype='补充协议款' then 1 end ) as 补充协议款实收笔数,
        sum(case when sg.itemtype='补充协议款' then sg.RmbAmount end) as 补充协议款实收金额,

        -- 业绩口径和本年度实收统计
        SUM(case when year(sg.cwskdate)=@年份 AND sg.itemtype IN ('非贷款类房款','贷款类房款','补充协议款') then sg.RmbAmount end) AS 业绩口径本年实收,
        sum(case when year(sg.cwskdate)=@年份 then sg.RmbAmount end) as 本年累计实收,

        -- 按月份统计实收金额
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=1 then sg.RmbAmount end) as 一月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=2 then sg.RmbAmount end) as 二月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=3 then sg.RmbAmount end) as 三月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=4 then sg.RmbAmount end) as 四月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=5 then sg.RmbAmount end) as 五月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=6 then sg.RmbAmount end) as 六月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=7 then sg.RmbAmount end) as 七月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=8 then sg.RmbAmount end) as 八月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=9 then sg.RmbAmount end) as 九月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=10 then sg.RmbAmount end) as 十月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=11 then sg.RmbAmount end) as 十一月累计实收,
        sum(case when year(sg.cwskdate)=@年份 and month(sg.cwskdate)=12 then sg.RmbAmount end) as 十二月累计实收
    from data_wide_s_getin sg 
    left join data_wide_s_trade st on sg.SaleGUID=st.tradeguid and st.IsLast = 1   -- and (st.cstatus='激活' or st.ostatus='激活')
    where isnull(sg.vouchstatus,'')<>'作废' AND  sg.VouchType NOT IN ( 'POS机单', '划拨单', '放款单' )
    group by sg.projguid
) tt

-- 汇总查询结果
select 
    fq.buguid,                                                                        -- 事业部GUID
    fq.p_projectid,                                                                   -- 项目ID
    pro.projname as 项目名称,                                                        -- 项目名称
    pro.SpreadName as 推广项目名称,                                                  -- 推广项目名称
    fq.projshortname as 分期名称,                                                    -- 分期名称

    -- 总体金额统计(单位:万元)
    isnull(sum(sf.应收总额),0)*0.0001 as 应收总额,	
    isnull(sum(sg.实收总额),0)*0.0001 as 实收总额,	
    isnull(sum(sf.未收总额),0)*0.0001 as 未收总额,

    -- 按款项类型统计应收情况
    isnull(sum(sf.非贷款类房款应收笔数),0) as 非贷款类房款应收笔数,
    isnull(sum(sf.非贷款类房款应收金额),0)*0.0001 as 非贷款类房款应收金额,
    isnull(sum(sf.贷款类房款应收笔数),0) as 贷款类房款应收笔数,
    isnull(sum(sf.贷款类房款应收金额),0)*0.0001 as 贷款类房款应收金额,
    isnull(sum(sf.代收费用应收笔数),0) as 代收费用应收笔数,
    isnull(sum(sf.代收费用应收金额),0)*0.0001 as 代收费用应收金额,
    isnull(sum(sf.其他款项应收笔数),0) as 其他款项应收笔数,
    isnull(sum(sf.其他款项应收金额),0)*0.0001 as 其他款项应收金额,
    isnull(sum(sf.补充协议款应收笔数),0) as 补充协议款项应收笔数,
    isnull(sum(sf.补充协议款应收金额),0)*0.0001 as 补充协议款项应收金额,

    -- 按款项类型统计实收情况
    isnull(sum(sg.非贷款类房款实收笔数),0) as 非贷款类房款实收笔数,
    isnull(sum(sg.非贷款类房款实收金额),0)*0.0001 as 非贷款类房款实收金额,
    isnull(sum(sg.贷款类房款实收笔数),0) as 贷款类房款实收笔数,
    isnull(sum(sg.贷款类房款实收金额),0)*0.0001 as 贷款类房款实收金额,
    isnull(sum(sg.代收费用实收笔数),0) as 代收费用实收笔数,
    isnull(sum(sg.代收费用实收金额),0)*0.0001 as 代收费用实收金额,
    isnull(sum(sg.其他款项实收笔数),0) as 其他款项实收笔数,
    isnull(sum(sg.其他款项实收金额),0)*0.0001 as 其他款项实收金额,
    isnull(sum(sg.补充协议款实收笔数),0) as 补充协议款实收笔数,
    isnull(sum(sg.补充协议款实收金额),0)*0.0001 as 补充协议款实收金额,

    -- 业绩统计
    isnull(sum(sg.业绩口径本年实收),0) as 业绩口径本年实收,

    -- 本年度汇总统计
    isnull(sum(sf.本年应收),0) as 本年应收,
    isnull(sum(sf.本年应收),0)-isnull(sum(sf.本年应收未收),0) as 本年应收实收,
    isnull(sum(sg.本年累计实收),0) as 本年累计实收,
    isnull(sum(sf.本年应收未收),0) as 本年应收未收,
    isnull(sum(sf.本年首期应收未收),0) as 本年首期应收未收,
    isnull(sum(sf.本年楼款应收未收),0) as 本年楼款应收未收,
    isnull(sum(sf.本年按揭应收未收),0) as 本年按揭应收未收,
    isnull(sum(sf.本年公积金应收未收),0) as 本年公积金应收未收,
    isnull(sum(sf.本年其他应收未收),0) as 本年其他应收未收,	
    isnull(sum(sf.本年补充应收未收),0) as 本年补充协议款应收未收,		

    -- 按月份统计应收实收情况
    isnull(sum(sf.一月应收),0) as 一月应收,
    isnull(sum(sf.一月应收),0)-isnull(sum(sf.一月应收未收),0) as 一月应收实收,
    isnull(sum(sg.一月累计实收),0) as 一月累计实收,
    isnull(sum(sf.一月应收未收),0) as 一月应收未收,
    isnull(sum(sf.二月应收),0) as 二月应收,
    isnull(sum(sf.二月应收),0)-isnull(sum(sf.二月应收未收),0) as 二月应收实收,
    isnull(sum(sg.二月累计实收),0) as 二月累计实收,
    isnull(sum(sf.二月应收未收),0) as 二月应收未收,
    isnull(sum(sf.三月应收),0) as 三月应收,
    isnull(sum(sf.三月应收),0)-isnull(sum(sf.三月应收未收),0) as 三月应收实收,
    isnull(sum(sg.三月累计实收),0) as 三月累计实收,
    isnull(sum(sf.三月应收未收),0) as 三月应收未收,
    isnull(sum(sf.四月应收),0) as 四月应收,
    isnull(sum(sf.四月应收),0)-isnull(sum(sf.四月应收未收),0) as 四月应收实收,
    isnull(sum(sg.四月累计实收),0) as 四月累计实收,
    isnull(sum(sf.四月应收未收),0) as 四月应收未收,
    isnull(sum(sf.五月应收),0) as 五月应收,
    isnull(sum(sf.五月应收),0)-isnull(sum(sf.五月应收未收),0) as 五月应收实收,
    isnull(sum(sg.五月累计实收),0) as 五月累计实收,
    isnull(sum(sf.五月应收未收),0) as 五月应收未收,
    isnull(sum(sf.六月应收),0) as 六月应收,
    isnull(sum(sf.六月应收),0)-isnull(sum(sf.六月应收未收),0) as 六月应收实收,
    isnull(sum(sg.六月累计实收),0) as 六月累计实收,
    isnull(sum(sf.六月应收未收),0) as 六月应收未收,
    isnull(sum(sf.七月应收),0) as 七月应收,
    isnull(sum(sf.七月应收),0)-isnull(sum(sf.七月应收未收),0) as 七月应收实收,
    isnull(sum(sg.七月累计实收),0) as 七月累计实收,
    isnull(sum(sf.七月应收未收),0) as 七月应收未收,
    isnull(sum(sf.八月应收),0) as 八月应收,
    isnull(sum(sf.八月应收),0)-isnull(sum(sf.八月应收未收),0) as 八月应收实收,
    isnull(sum(sg.八月累计实收),0) as 八月累计实收,
    isnull(sum(sf.八月应收未收),0) as 八月应收未收,
    isnull(sum(sf.九月应收),0) as 九月应收,
    isnull(sum(sf.九月应收),0)-isnull(sum(sf.九月应收未收),0) as 九月应收实收,
    isnull(sum(sg.九月累计实收),0) as 九月累计实收,
    isnull(sum(sf.九月应收未收),0) as 九月应收未收,
    isnull(sum(sf.十月应收),0) as 十月应收,
    isnull(sum(sf.十月应收),0)-isnull(sum(sf.十月应收未收),0) as 十月应收实收,
    isnull(sum(sg.十月累计实收),0) as 十月累计实收,
    isnull(sum(sf.十月应收未收),0) as 十月应收未收,
    isnull(sum(sf.十一月应收),0) as 十一月应收,
    isnull(sum(sf.十一月应收),0)-isnull(sum(sf.十一月应收未收),0) as 十一月应收实收,
    isnull(sum(sg.十一月累计实收),0) as 十一月累计实收,
    isnull(sum(sf.十一月应收未收),0) as 十一月应收未收,
    isnull(sum(sf.十二月应收),0) as 十二月应收,
    isnull(sum(sf.十二月应收),0)-isnull(sum(sf.十二月应收未收),0) as 十二月应收实收,
    isnull(sum(sg.十二月累计实收),0) as 十二月累计实收,
    isnull(sum(sf.十二月应收未收),0) as 十二月应收未收
from #实收情况 sg 
left join #应收情况 sf on sf.projguid=sg.projguid
inner join data_wide_mdm_project fq on sg.projguid=fq.p_projectid
inner join data_wide_mdm_project pro on fq.parentguid=pro.p_projectid
where sg.projguid in (@projguid)
group by 
    pro.projname,
    pro.SpreadName,
    fq.projshortname,
    fq.buguid,
    fq.p_projectid
order by 
    pro.projname,
    fq.projshortname

-- 清理临时表
drop table #应收情况,#实收情况