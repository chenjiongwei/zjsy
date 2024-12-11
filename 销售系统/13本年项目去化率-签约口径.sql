
-- DECLARE @date datetime =getdate() 
select  
tt.项目,
tt.项目推广名称,
tt.分期,
tt.业态,
isnull(tt.年初可售余货套数已定价,0) as 年初可售余货套数已定价,
isnull(tt.年初可售余货面积已定价,0) as 年初可售余货面积已定价,
isnull(tt.年初可售余货货值已定价,0)*0.0001 as 年初可售余货货值已定价,
isnull(tt.年初可售余货套数未定价,0) as 年初可售余货套数未定价,
isnull(tt.年初可售余货面积未定价,0) as 年初可售余货面积未定价,
isnull(tt.年初可售余货货值未定价,0)*0.0001 as 年初可售余货货值未定价,
isnull(tt.本年新供货套数已定价,0) as 本年新供货套数已定价,
isnull(tt.本年新供货面积已定价,0) as 本年新供货面积已定价,
isnull(tt.本年新供货货值已定价,0)*0.0001 as 本年新供货货值已定价,
isnull(tt.本年新供货套数未定价,0) as 本年新供货套数未定价,
isnull(tt.本年新供货面积未定价,0) as 本年新供货面积未定价,
isnull(tt.本年新供货货值未定价,0)*0.0001 as 本年新供货货值未定价,
isnull(tt.年初可售余货套数已定价,0)+isnull(tt.本年新供货套数已定价,0) as 年初总可售套数已定价,
isnull(tt.年初可售余货面积已定价,0)+isnull(tt.本年新供货面积已定价,0) as 年初总可售面积已定价,
(isnull(tt.年初可售余货货值已定价,0)+isnull(tt.本年新供货货值已定价,0))*0.0001 as 年初总可售货值已定价,
isnull(tt.年初可售余货套数未定价,0)+isnull(tt.本年新供货套数未定价,0) as 年初总可售套数未定价,
isnull(tt.年初可售余货面积未定价,0)+isnull(tt.本年新供货面积未定价,0) as 年初总可售面积未定价,
(isnull(tt.年初可售余货货值未定价,0)+isnull(tt.本年新供货货值未定价,0))*0.0001 as 年初总可售货值未定价,
isnull(tt.本年已签约套数,0) as 本年已签约套数,
isnull(tt.本年已签约面积,0) as 本年已签约面积,
isnull(tt.本年已签约金额,0)*0.0001 as 本年已签约金额,
-- isnull(tt.本年已签约套数/nullif(isnull(tt.年初可售余货套数已定价,0)+isnull(tt.本年新供货套数已定价,0),0),0) as 套数去化率已定价,
case when  (isnull(tt.年初可售余货套数已定价,0)+isnull(tt.本年新供货套数已定价,0) ) =0  then  0 else  
   isnull(tt.本年已签约套数,0)  *1.0 / ( isnull(tt.年初可售余货套数已定价,0)+isnull(tt.本年新供货套数已定价,0)) end  as 套数去化率已定价,
isnull(tt.本年已签约面积/nullif(isnull(tt.年初可售余货面积已定价,0) + isnull(tt.本年新供货面积已定价,0),0),0) as 面积去化率已定价,
isnull(tt.本年已签约金额/nullif(isnull(tt.年初可售余货货值已定价,0)+isnull(tt.本年新供货货值已定价,0),0),0) as 货值去化率已定价,
-- isnull(tt.本年已签约套数/nullif(isnull(tt.年初可售余货套数未定价,0)+isnull(tt.本年新供货套数未定价,0),0),0) as 套数去化率未定价,
case when  ( isnull(tt.年初可售余货套数未定价,0)+isnull(tt.本年新供货套数未定价,0) +  isnull(tt.年初可售余货套数已定价,0)+isnull(tt.本年新供货套数已定价,0)  ) =0 then 0  else 
   isnull(tt.本年已签约套数,0) *1.0 /  (isnull(tt.年初可售余货套数未定价,0)+isnull(tt.本年新供货套数未定价,0) +  isnull(tt.年初可售余货套数已定价,0)+isnull(tt.本年新供货套数已定价,0)  ) end  as 套数去化率未定价,
isnull(tt.本年已签约面积/nullif(isnull(tt.年初可售余货面积未定价,0)+isnull(tt.本年新供货面积未定价,0) + isnull(tt.年初可售余货面积已定价,0)+isnull(tt.本年新供货面积已定价,0),0),0) as 面积去化率未定价,
isnull(tt.本年已签约金额/nullif(isnull(tt.年初可售余货货值未定价,0)+isnull(tt.本年新供货货值未定价,0) + isnull(tt.年初可售余货货值已定价,0)+isnull(tt.本年新供货货值已定价,0),0),0) as 货值去化率未定价
from 
(
        select 
        pro.ProjName as 项目,
        pro.SpreadName as 项目推广名称,
        bld.stageName as 分期,
        bld.ProductTypeName as 业态,
        sum(case when year(bld.FactNotOpen)<year(getdate()) and (year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) or isnull(st.x_InitialledDate,st.CNetQsDate) is null) then CASE WHEN  sr.bldarea IS NULL   THEN 0 ELSE 1 END  else 0 end) as 年初可售余货套数已定价,
        sum(case when year(bld.FactNotOpen)<year(getdate()) and (year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) or isnull(st.x_InitialledDate,st.CNetQsDate) is null) then sr.bldarea else 0 end) as 年初可售余货面积已定价,
        sum(case when year(bld.FactNotOpen)<year(getdate()) and (year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) or isnull(st.x_InitialledDate,st.CNetQsDate) is null) then isnull(isnull(st.ocjtotal,st.ccjtotal),sr.djtotal) else 0 end) as 年初可售余货货值已定价,
        
        sum(case when sr.MasterBldGUID is null and year(bld.FactNotOpen)<year(getdate()) then bld.SetNum+bld.CarNum else 0 end) as 年初可售余货套数未定价,
        sum(case when sr.MasterBldGUID is null and year(bld.FactNotOpen)<year(getdate()) then bld.AvailableArea else 0 end) as 年初可售余货面积未定价,
        sum(case when sr.MasterBldGUID is null and year(bld.FactNotOpen)<year(getdate()) then bld.SaleAmount else 0 end) as 年初可售余货货值未定价,

        sum(case when year(bld.FactNotOpen)=year(getdate()) then CASE WHEN  sr.bldarea IS NULL   THEN 0 ELSE 1 END   else 0 end) as 本年新供货套数已定价,
        sum(case when year(bld.FactNotOpen)=year(getdate()) then sr.bldarea else 0 end) as 本年新供货面积已定价,
        sum(case when year(bld.FactNotOpen)=year(getdate()) then isnull(isnull(st.ocjtotal,st.ccjtotal),sr.djtotal) else 0 end) as 本年新供货货值已定价,
        sum(case when sr.MasterBldGUID is null and year(bld.FactNotOpen)=year(getdate()) then bld.SetNum+bld.CarNum else 0 end) as 本年新供货套数未定价,
        sum(case when sr.MasterBldGUID is null and year(bld.FactNotOpen)=year(getdate()) then bld.AvailableArea else 0 end) as 本年新供货面积未定价,
        sum(case when sr.MasterBldGUID is null and year(bld.FactNotOpen)=year(getdate()) then bld.SaleAmount else 0 end) as 本年新供货货值未定价,

        sum (case when year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) then CASE WHEN  sr.bldarea IS NULL   THEN 0 ELSE 1 END  else 0 end) as 本年已签约套数,
        sum(case when year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) then sr.bldarea else 0 end) as 本年已签约面积,
        sum(case when year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(getdate()) then st.ccjtotal else 0 end) as 本年已签约金额
        from data_wide_mdm_building bld 
        left join data_wide_s_room sr on sr.MasterBldGUID=bld.BuildingGUID
        left join data_wide_s_trade st on sr.roomguid=st.roomguid and (st.cstatus='激活' or st.ostatus='激活')
        left join data_wide_mdm_project pro on bld.projectguid=pro.p_projectid
        where bld.stageguid in (@projguid)
        group by 
        pro.ProjName,
        pro.SpreadName,
        bld.stageName,
        bld.ProductTypeName
) tt


-- -- =IIF( ( Sum(Fields!年初总可售套数未定价.Value) + Sum(Fields!年初总可售套数已定价.Value) ) =0,0,Sum(Fields!本年已签约套数.Value)/IIF(  ( Sum(Fields!年初总可售套数未定价.Value) + Sum(Fields!年初总可售套数已定价.Value) )  =0,1,( Sum(Fields!年初总可售套数未定价.Value) + Sum(Fields!年初总可售套数已定价.Value) )))

-- =IIF(Sum(Fields!年初总可售面积未定价.Value)=0,0,Sum(Fields!本年已签约面积.Value)/IIF(Sum(Fields!年初总可售面积未定价.Value)=0,1,Sum(Fields!年初总可售面积未定价.Value)))


-- =IIF( ( Sum(Fields!年初总可售面积未定价.Value) + Sum(Fields!年初总可售面积已定价.Value) ) =0,0,Sum(Fields!本年已签约面积.Value)/IIF(  ( Sum(Fields!年初总可售面积未定价.Value) + Sum(Fields!年初总可售面积已定价.Value) )  =0,1,( Sum(Fields!年初总可售面积未定价.Value) + Sum(Fields!年初总可售面积已定价.Value) )))

-- =IIF( ( Sum(Fields!年初总可售货值未定价.Value) + Sum(Fields!年初总可售货值已定价.Value) ) =0,0,Sum(Fields!本年已签约金额.Value)/IIF(  ( Sum(Fields!年初总可售货值未定价.Value) + Sum(Fields!年初总可售货值已定价.Value) )  =0,1,( Sum(Fields!年初总可售货值未定价.Value) + Sum(Fields!年初总可售货值已定价.Value) )))

-- =IIF(Sum(Fields!年初总可售货值未定价.Value)=0,0,Sum(Fields!本年已签约金额.Value)/IIF(Sum(Fields!年初总可售货值未定价.Value)=0,1,Sum(Fields!年初总可售货值未定价.Value)))
