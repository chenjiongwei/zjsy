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
        sum(case when year(bld.FactNotOpen)<year(@date) and (year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(@date) or isnull(st.x_InitialledDate,st.CNetQsDate) is null) and isnull(sr.Total,0)<>0 then CASE WHEN  sr.bldarea IS NULL   THEN 0 ELSE 1 END  else 0 end) as 年初可售余货套数已定价,
        sum(case when year(bld.FactNotOpen)<year(@date) and (year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(@date) or isnull(st.x_InitialledDate,st.CNetQsDate) is null) and isnull(sr.Total,0)<>0 then sr.bldarea else 0 end) as 年初可售余货面积已定价,
        sum(case when year(bld.FactNotOpen)<year(@date) and (year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(@date) or isnull(st.x_InitialledDate,st.CNetQsDate) is null) 
        and isnull(sr.Total,0)<>0 then isnull(isnull(st.ccjtotal,st.ocjtotal),sr.djtotal) else 0 end) as 年初可售余货货值已定价,
        
        -- 标准总价为空或未建立房间都判定为未定价
        sum(case when (sr.MasterBldGUID is null or isnull(sr.Total,0)=0 ) and year(bld.FactNotOpen)<year(@date) then 
            case when sr.MasterBldGUID is null then   bld.SetNum+bld.CarNum else  case when  sr.Total is null  then  0 else  1 end  END END  ) as 年初可售余货套数未定价,
        sum(case when (sr.MasterBldGUID is null or isnull(sr.Total,0)=0 ) and year(bld.FactNotOpen)<year(@date) then 
            case when sr.MasterBldGUID is null then   bld.AvailableArea else  case when sr.Total is null then 0 else sr.bldarea end  end end ) as 年初可售余货面积未定价,
        sum(case when (sr.MasterBldGUID is null or isnull(sr.Total,0)=0 ) and year(bld.FactNotOpen)<year(@date) 
            then case when sr.MasterBldGUID is null then   bld.SaleAmount else  case when  sr.Total is null then 0 else sr.djtotal end  end end ) as 年初可售余货货值未定价,

        sum(case when year(bld.FactNotOpen)=year(@date) and isnull(sr.Total,0)<>0 then CASE WHEN  sr.bldarea IS NULL   THEN 0 ELSE 1 END   else 0 end) as 本年新供货套数已定价,
        sum(case when year(bld.FactNotOpen)=year(@date) and isnull(sr.Total,0)<>0 then sr.bldarea else 0 end) as 本年新供货面积已定价,
        sum(case when year(bld.FactNotOpen)=year(@date) and isnull(sr.Total,0)<>0 then isnull(isnull(st.ccjtotal,st.ocjtotal),sr.djtotal) else 0 end) as 本年新供货货值已定价,

        sum(case when (sr.MasterBldGUID is null or isnull(sr.Total,0)=0) and year(bld.FactNotOpen)=year(@date) then 
            case when sr.MasterBldGUID is null then   bld.SetNum+bld.CarNum else  case when  sr.Total is null  then  0 else  1 end  end end ) as 本年新供货套数未定价,
        sum(case when (sr.MasterBldGUID is null or isnull(sr.Total,0)=0) and year(bld.FactNotOpen)=year(@date) then 
            case when sr.MasterBldGUID is null then   bld.AvailableArea else  case when sr.Total is null then 0 else sr.bldarea end  end end ) as 本年新供货面积未定价,
        sum(case when (sr.MasterBldGUID is null or isnull(sr.Total,0)=0) and year(bld.FactNotOpen)=year(@date) then 
            case when sr.MasterBldGUID is null then   bld.SaleAmount else  case when  sr.Total is null then 0 else sr.djtotal end  end end ) as 本年新供货货值未定价,

        sum (case when year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(@date) then CASE WHEN  sr.bldarea IS NULL   THEN 0 ELSE 1 END  else 0 end ) as 本年已签约套数,
        sum(case when year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(@date) then sr.bldarea else 0 end) as 本年已签约面积,
        sum(case when year(isnull(st.x_InitialledDate,st.CNetQsDate))=year(@date) then st.ccjtotal else 0 end) as 本年已签约金额
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