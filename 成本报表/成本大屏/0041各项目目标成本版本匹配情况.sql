/*
处理逻辑
成本系统版本	主项计划版本	一致	匹配			
成本系统版本	主项计划版本	差一个版本	根据时间（主项计划时间+期限） > 当前时间比 			匹配
成本系统版本	主项计划版本	差两个版本	不匹配	
当【项目进度】为“已完工”时，【项目目标成本与项目计划节点是否匹配】模块中的【是否匹配】均调整为固定值“匹配”
20240722取掉成本“装修版”的判断
*/
WITH dtl AS (
                SELECT bu.BUName ,
                    p.BUGUID ,
                    p.ProjName ,
                    p.p_projectId ,
                    VersionName AS 当前目标成本版本 ,
                    CONVERT(VARCHAR(10), t.ApproveDate, 121) AS 当前目标成本版本审核日期 ,
                    CASE WHEN 装修版节点审核日期 IS NOT NULL THEN '大货区装修施工图出图'
                         ELSE CASE WHEN 施工图版节点审核日期 IS NOT NULL THEN '全套施工图出图（封板图）'
                         ELSE CASE WHEN 启动版节点审核日期 IS NOT NULL THEN '目标成本评审会（启动版）' 
                         ELSE CASE WHEN 可研版节点审核日期 IS NOT NULL THEN '投资专业评审会（可研报告）' 
                         ELSE '未审核项目主项计划' END END
                        END
                    END AS 当前项目进度,
                    CASE WHEN VersionName = '可研版' THEN 1
                         WHEN VersionName = '启动版' THEN 2
                         WHEN VersionName = '施工图版' THEN 3
                         WHEN VersionName = '装修版' THEN 4
                    END AS 目标成本版本,
                    --CASE WHEN VersionName = '可研版' AND   可研版节点审核日期 IS NOT NULL THEN '匹配'
                    --     WHEN VersionName = '启动版' AND   启动版节点审核日期 IS NOT NULL THEN '匹配'
                    --     WHEN VersionName = '施工图版' AND  施工图版节点审核日期 IS NOT NULL THEN '匹配'
                    --     WHEN VersionName = '装修版' AND   装修版节点审核日期 IS NOT NULL THEN '匹配'
                    --     ELSE '不匹配'
                    --END AS 进度与目标成本是否匹配 ,

                    ISNULL(CONVERT(VARCHAR(10), jh.可研版节点审核日期, 121), '') AS 可研版节点审核日期 ,
                    ISNULL(CONVERT(VARCHAR(10), jh.启动版节点审核日期, 121), '') AS 启动版节点审核日期 ,
                    ISNULL(CONVERT(VARCHAR(10), jh.施工图版节点审核日期, 121), '') AS 施工图版节点审核日期 ,
                    ISNULL(CONVERT(VARCHAR(10), jh.装修版节点审核日期, 121), '') AS 装修版节点审核日期,
                    CASE 
					     WHEN ISNULL(CONVERT(VARCHAR(10), jh.装修版节点审核日期, 121), '') <> '' THEN 4
                         WHEN ISNULL(CONVERT(VARCHAR(10), jh.施工图版节点审核日期, 121), '') <> '' THEN 3
                         WHEN ISNULL(CONVERT(VARCHAR(10), jh.启动版节点审核日期, 121), '') <> '' THEN 2
                         WHEN ISNULL(CONVERT(VARCHAR(10), jh.可研版节点审核日期, 121), '') <> '' THEN 1
                    END AS 进度版本,
					case when   p.IsMineDisk =1  then  '建设中' when   p.IsMineDisk =2   then '已完工' when p.IsMineDisk =3 then  '未开始' end  as  项目进度
            FROM   data_wide_mdm_Project p
                    --查询最新版目标成本，不取调整版
            INNER JOIN dbo.data_wide_mdm_BusinessUnit bu ON bu.BUGUID = p.BUGUID
            OUTER APPLY (SELECT  TOP 1   TCV.TargetCostVersionName AS VersionName ,
                                        ApproveDate
                        FROM    data_wide_cb_TargetCostStageVersion TCSV
                                INNER JOIN data_wide_cb_TargetCostVersion TCV ON TCV.TargetCostVersionGUID = TCSV.TargetCostVersionGUID
                        WHERE   TCSV.ApproveStateEnum = 3 AND   TargetCostVersionName <> '调整版' AND  TCSV.ProjectGUID = p.p_projectId
                        ORDER BY TCV.RowIndex DESC) t
            --查询当前进度系统版本
            LEFT JOIN(SELECT    a.ProjGUID ,
                                a.PlanObjectGUID ,
                                MAX(CASE WHEN a.TaskName = '投资专业评审会（可研报告）' THEN ActualFinishTime END) AS '可研版节点审核日期' ,
                                MAX(CASE WHEN a.TaskName = '目标成本评审会（启动版）' THEN ActualFinishTime END) AS '启动版节点审核日期' ,
                                DATEADD(DAY,60, MAX(CASE WHEN a.TaskName = '全套施工图出图（封板图）' THEN ActualFinishTime END) ) AS '施工图版节点审核日期' , --取工作项名称like“全套施工图出图”+60天
                                DATEADD(DAY,45, MAX(CASE WHEN a.TaskName = '大货区装修施工图出图' THEN ActualFinishTime END) ) AS '装修版节点审核日期' -- 工作项名称like“大货区装修出图”+45天
                        FROM  data_wide_jh_TaskDetail a
                        WHERE a.ApproveState = 2
                        GROUP BY a.ProjGUID ,
                                a.PlanObjectGUID) jh ON jh.PlanObjectGUID = p.p_projectId
            WHERE  p.Level = 3 and  p.IsMineDisk in ( 1,2,3)  --AND  p.p_projectId ='9D6B5F12-ECCF-E911-8A8E-40F2E92B3FDA'
			
			)
SELECT  * ,
        CASE  
		WHEN  项目进度 ='已完工' THEN  '匹配'  
        WHEN ISNULL(当前目标成本版本,'') ='' THEN '未开始'
	    WHEN 当前目标成本版本 = '方案版' THEN  '不匹配'
        WHEN ISNULL(进度版本,0) - ISNULL(目标成本版本,0) > 1 THEN '不匹配'
        WHEN 进度版本 = 目标成本版本 THEN '匹配'
        WHEN ISNULL(进度版本,0) - ISNULL(目标成本版本,0) = 1
            THEN 

            CASE WHEN 当前目标成本版本 = '可研版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,5,CONVERT(DATETIME, 启动版节点审核日期)),120) >= CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '匹配'
                WHEN 当前目标成本版本 = '可研版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,5,CONVERT(DATETIME, 启动版节点审核日期)),120) < CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '不匹配'
                WHEN 当前目标成本版本 = '启动版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,60,CONVERT(DATETIME, 施工图版节点审核日期)),120) >= CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '匹配'
                WHEN 当前目标成本版本 = '启动版' 
                    AND CONVERT(VARCHAR(10),DATEADD(DAY,60,CONVERT(DATETIME, 施工图版节点审核日期)),120) < CONVERT(VARCHAR(10),GETDATE(),120)
                THEN '不匹配'
                --WHEN 当前目标成本版本 = '施工图版' 
                --    AND CONVERT(VARCHAR(10),DATEADD(DAY,45,CONVERT(DATETIME, 装修版节点审核日期)),120) >= CONVERT(VARCHAR(10),GETDATE(),120)
                --THEN '匹配'
                --WHEN 当前目标成本版本 = '施工图版' 
                --    AND CONVERT(VARCHAR(10),DATEADD(DAY,45,CONVERT(DATETIME, 装修版节点审核日期)),120) < CONVERT(VARCHAR(10),GETDATE(),120)
                --THEN '不匹配'
				WHEN 当前目标成本版本 in ('施工图版','装修版') THEN  '匹配'
            END
        WHEN ISNULL(目标成本版本,0) - ISNULL(进度版本,0) = 1 THEN '匹配'
		WHEN 当前目标成本版本 in ('施工图版','装修版') THEN  '匹配'
        WHEN 当前项目进度 = '未审核项目主项计划' THEN  '无主项计划'
        END AS 进度与目标成本是否匹配
FROM    dtl;