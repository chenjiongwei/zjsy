--  备份数据表
-- select * into jh_ProjectPlanTaskCompile_bak20241216 from jh_ProjectPlanTaskCompile
-- select * into jh_PlanTaskExecute_bak20241216 from jh_PlanTaskExecute

-- 查询协同和机械厂-编制版主项计划
SELECT 
    c.PlanName,
    c.ApproveState,
    c.ApproveDate,
    c.PlanVersionGUID,
    a.ProjectPlanTaskCompileGUID,
    a.TaskGUID,
    a.TaskName,
    a.TaskTypeGUID,
    a.TaskTypeName
into  #ProjectPlanTaskCompile 
FROM 
    jh_ProjectPlanTaskCompile a
INNER JOIN 
    jh_PlanTaskExecute b ON a.ProjectPlanTaskCompileGUID = b.PlanTaskExecuteGUID
INNER JOIN 
    jh_PlanVersion c ON b.PlanVersionGUID = c.PlanVersionGUID
WHERE  1=1
    AND  a.TaskTypeName = '2级' 
    AND c.PlanName in ('AF0212045（7号地块）-协同和机械厂') -- 主项计划名称
    and a.TaskName in ('设计单位统筹设计方案和施工方案','保护性清理方案报审完成','保护性清理工程审定报价','现场测量及现状图纸绘制','修缮设计方案编制','修缮方案编制要求预沟通','修缮方案预审','修缮方案调整','修缮方案报审预约专家现场查勘','修缮方案专家会评审','完善修缮方案')
union all 
-- 查询2号地块-编制版主项计划
SELECT 
    c.PlanName,
    c.ApproveState,
    c.ApproveDate,
    c.PlanVersionGUID,
    a.ProjectPlanTaskCompileGUID,
    a.TaskGUID,
    a.TaskName,
    a.TaskTypeGUID,
    a.TaskTypeName
FROM 
    jh_ProjectPlanTaskCompile a
INNER JOIN 
    jh_PlanTaskExecute b ON a.ProjectPlanTaskCompileGUID = b.PlanTaskExecuteGUID
INNER JOIN 
    jh_PlanVersion c ON b.PlanVersionGUID = c.PlanVersionGUID
WHERE  1=1
    AND  a.TaskTypeName = '2级' 
    AND c.PlanName in ('AF0212034（2号地块）-AF0212034（2号地块）') -- 主项计划名称
    and a.TaskName in ('报规专项图纸或方案(人防、消防等)','完成单体报建图及技术审查') -- 主项计划节点名称
union all
-- 查询3号地块-编制版主项计划
SELECT 
    c.PlanName,
    c.ApproveState,
    c.ApproveDate,
    c.PlanVersionGUID,
    a.ProjectPlanTaskCompileGUID,
    a.TaskGUID,
    a.TaskName,
    a.TaskTypeGUID,
    a.TaskTypeName
FROM 
    jh_ProjectPlanTaskCompile a
INNER JOIN 
    jh_PlanTaskExecute b ON a.ProjectPlanTaskCompileGUID = b.PlanTaskExecuteGUID
INNER JOIN 
    jh_PlanVersion c ON b.PlanVersionGUID = c.PlanVersionGUID
WHERE  1=1
    AND  a.TaskTypeName = '2级' 
    AND c.PlanName in ('AF0212039（3号地块）-AF0212039（3号地块）') -- 主项计划名称
    and a.TaskName in ('报规专项图纸或方案(人防、消防等)','完成单体报建图') -- 主项计划节点名称

select * from #ProjectPlanTaskCompile


-- 查询协同和机械厂-执行版主项计划
select  
    c.PlanName,
    c.ApproveState,
    c.ApproveDate,
    c.PlanVersionGUID,
    b.PlanTaskExecuteGUID,
    b.TaskGUID,
    b.TaskName,
    b.TaskTypeGUID,
    b.TaskTypeName
into  #PlanTaskExecute 
from   jh_PlanTaskExecute b 
INNER JOIN  jh_PlanVersion c ON b.PlanVersionGUID = c.PlanVersionGUID
where  1=1 
and b.TaskTypeName ='2级' 
and c.PlanName = 'AF0212045（7号地块）-协同和机械厂' -- 主项计划名称
and b.TaskName in ('设计单位统筹设计方案和施工方案','保护性清理方案报审完成','保护性清理工程审定报价','现场测量及现状图纸绘制','修缮设计方案编制','修缮方案编制要求预沟通','修缮方案预审','修缮方案调整','修缮方案报审预约专家现场查勘','修缮方案专家会评审','完善修缮方案') 
union all 
-- 查询2号地块-执行版主项计划
select  
    c.PlanName,
    c.ApproveState,
    c.ApproveDate,
    c.PlanVersionGUID,
    b.PlanTaskExecuteGUID,
    b.TaskGUID,
    b.TaskName,
    b.TaskTypeGUID,
    b.TaskTypeName
from   jh_PlanTaskExecute b 
INNER JOIN  jh_PlanVersion c ON b.PlanVersionGUID = c.PlanVersionGUID
where  1=1 
and b.TaskTypeName ='2级' 
and c.PlanName = 'AF0212034（2号地块）-AF0212034（2号地块）' -- 主项计划名称
and b.TaskName in ('报规专项图纸或方案(人防、消防等)','完成单体报建图及技术审查')   -- 主项计划节点名称
union all
-- 查询3号地块-执行版主项计划
select  
    c.PlanName,
    c.ApproveState,
    c.ApproveDate,
    c.PlanVersionGUID,
    b.PlanTaskExecuteGUID,
    b.TaskGUID,
    b.TaskName,
    b.TaskTypeGUID,
    b.TaskTypeName
from   jh_PlanTaskExecute b 
INNER JOIN  jh_PlanVersion c ON b.PlanVersionGUID = c.PlanVersionGUID
where  1=1 
and b.TaskTypeName ='2级' 
and c.PlanName = 'AF0212039（3号地块）-AF0212039（3号地块）' -- 主项计划名称
and b.TaskName in ('报规专项图纸或方案(人防、消防等)','完成单体报建图')  -- 主项计划节点名称

select * from #PlanTaskExecute


-- 修改协同和机械厂主项计划节点信息
/*
--查询2级计划工作项类别
declare @TaskTypeGUIDNew varchar(50)
declare @TaskTypeNameNew varchar(50)
declare @TaskTypeGUIDOld varchar(50)
declare @TaskTypeNameOld varchar(50)

SELECT @TaskTypeNameOld = TaskTypeName, @TaskTypeGUIDOld =TaskTypeGUID  
FROM jh_TaskType WHERE  TaskTypeName='2级' AND  PlanTypes ='1,2'

SELECT @TaskTypeNameNew = TaskTypeName, @TaskTypeGUIDNew =TaskTypeGUID  
FROM jh_TaskType WHERE  TaskTypeName='3级' AND  PlanTypes ='1,2'

-- 修改协同和机械厂-编制版主项计划
-- SELECT  a.TaskTypeGUID,a.TaskTypeName,@TaskTypeGUIDNew, @TaskTypeNameNew 
update  a set a.TaskTypeGUID = @TaskTypeGUIDNew,a.TaskTypeName = @TaskTypeNameNew 
from jh_ProjectPlanTaskCompile a
inner join  #ProjectPlanTaskCompile  b on a.ProjectPlanTaskCompileGUID =b.ProjectPlanTaskCompileGUID
where  a.TaskTypeGUID = @TaskTypeGUIDOld

-- 修改协同和机械厂-执行版主项计划
-- SELECT  a.TaskTypeGUID,a.TaskTypeName,@TaskTypeGUIDNew, @TaskTypeNameNew 
update  a set a.TaskTypeGUID = @TaskTypeGUIDNew,a.TaskTypeName = @TaskTypeNameNew 
from jh_PlanTaskExecute a
inner join  #PlanTaskExecute  b on a.PlanTaskExecuteGUID =b.PlanTaskExecuteGUID
where  a.TaskTypeGUID = @TaskTypeGUIDOld
*/


