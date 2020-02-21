

/* ZX30026MR001 
 * 版本:v1.0 
 * 用途:客制報表-當月保險報繳手續費 達成率排名
 * 作者:Brad
 * 參數傳入:@CNO:公司別
 *			@d1:起日期
 *			@d2:訖日期
 *			@GCode:分行
 *
 */

CREATE PROCEDURE [dbo].[ZX30026MR001] 
@CNO int,@d1 datetime,@d2 datetime,@GCode int
AS
BEGIN
SET NOCOUNT ON;

declare @wd int ,@wdSum int,@Period int
set @Period=dbo.DateToPeriod(@d1)
set @wd = 0
set @wdSum = 0

--建立容器
CREATE TABLE #List(GCode int ,FYB money, Tag money, Reach money, TagToDay money, TagToDayReach money)

--取得全組織單位
insert #List(GCode,FYB)
select GCode,0 from [Group] with (nolock)
where GCode=(case when @GCode=0 then GCode else @GCode end)
and isnull(VoidDate,@d1+1)>@d1


--取得各單位的報繳數字
;with #FYBLite(GCode,FYB)
as
(
	select IGCode, sum(ISNULL(b.FYB,0)) FYB 
	from Delivery a
	inner join Dlv_Content b on b.DlvCode = a.DlvCode
	inner join Dlv_Type c on a.DType=c.DType  
	inner join Dlv_Flow d on a.FL=d.FL and d.Feat=1 --流程計績
	left join Dlv_TypeD e on c.DType = e.DType 
	where a.CNO = @CNO
	and AplyDate between @d1 and @d2 
	and GCode = (case when @GCode=0 then GCode else @GCode end)
	and isnull(e.Feat,c.Feat) = 1  --契約計績
	group by IGCode
)

--報繳傳入各單位
update #List set FYB = ISNULL(b.FYB,0)
from #List a
left join #FYBLite b on a.GCode=b.GCode

--當月已工作天數
set @wd=dbo.GetWorkDays(@CNO,@d1,@d2)+1

--當月總工作天數
set @wdSum=dbo.GetWorkDays(@CNO,dbo.PeriodToDate(dbo.DateToPeriod(@d1),0),dbo.PeriodToDate(dbo.DateToPeriod(@d1),1))+1

--目標來源(目標數字)
update #List set Tag = b.Feat
,Reach = ROUND(a.FYB*100/b.Feat,2)
,TagToDay = case when @wdSum = 0 then b.Feat else ROUND(b.Feat*@wd/@wdSum,2) end 
,TagToDayReach = case when @wd=0 then 0 else ROUND(a.FYB*100/(b.Feat*@wd/@wdSum),2) end 
from #List a 
inner join  FeatTarget b on a.GCode=b.GCode 
where TargetType=0  --險種不拘
and FType = 2 --目標類型 : 受理佣收
and Period = @Period 


select ROW_NUMBER() OVER(ORDER BY a.Reach desc) AS 序號,b.Code 分行代號,b.Name 分行名稱,c.Name 分行經理,@wdSum 當月總工作日,@wd 當月累計已工作日,a.Tag 當月目標,a.FYB 當月報繳
,a.Reach 達成率,a.TagToDay 本月至今日應達成目標,a.TagToDayReach 本月至今日應達成目標之達成率
from #List a
left join [Group] b on a.GCode = b.GCode
left join MAN_Data c on b.ICBoss=c.Code
order by a.Reach desc

drop table #List 

end