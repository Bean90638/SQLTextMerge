
/* ZX30026MR002
 * 版本:v1.0 
 * 用途:客制報表
 * 作者:Jack
 * 編寫日期:2018/10/05
 * 參數傳入:@CNO:公司別
 *			@DateTP:日期種類(1.進件日)
 *			@d1、@d2:日期
 *			@JT:險別
 */
 /*
1.以【財管&銷售主管】管轄單位推算出累計至當日業績達成率
2.資料來源:進件
3.篩選條件:輸入日的日期區間(起日預設當月第1天，迄日預計為當天)
4.組別:組織單位設定
5.當月財管&銷售主管總報繳:查詢當月總進件
6.財管&銷售主管達成率%:當月財管&銷售主管總報繳/當月財管&銷售主管總目標
7.須可匯出，欄位比照介面上的欄位
8.匯出格式為Excel和CSV(逗號分隔)
9.報表數字

P.S.當月財管&銷售主管總報銷:不含車險&旅平險
 */
CREATE PROCEDURE [dbo].[ZX30026MR002] 
@CNO int,@DateTP int,@d1 datetime,@d2 datetime,@JT int
AS
BEGIN
SET NOCOUNT ON;

--取時任財管&銷售主管
create table #MR002TmpBoss (GCode int,BossCode int)
insert #MR002TmpBoss (GCode,BossCode)
select a.GCode,a.BossCode
from Group_Chg a with (nolock)
left join [Group] b with (nolock) on a.GCode = b.GCode
where @d1 between a.SDate and a.EDate
and @d2 between a.SDate and a.EDate


--取各分行當月總報繳
create table #MR002TmpFYB (GCode int,FYB int)
insert #MR002TmpFYB (GCode,FYB)
select a.GCode,sum(isnull(b.FYB,0)) 
from Delivery a with (nolock)
inner join Dlv_Content b with (nolock) on b.DlvCode = a.DlvCode
inner join Dlv_Type c with (nolock) on a.DType=c.DType and c.Feat=1 --契約計績
inner join Dlv_Flow d with (nolock) on a.FL=d.FL and d.Feat=1 --流程計績
where a.CNO = @CNO
and (Case When @DateTP=1 Then dbo.Date(a.AplyDate) else dbo.Date(a.AplyDate) end) between @d1 and @d2
and a.Job_Type = (Case When @JT = 0 Then a.Job_Type else @JT end)
Group by a.GCode
 
select a.Code [分行代號],a.[Name] [分行名稱],a.GLevel [組別],isnull(f.[Name],c.[Name]) [財管&銷售主管],isnull(d.Feat,0) [當月財管&銷售主管總目標]
,isnull(b.FYB,0) [當月財管&銷售主管總報繳],Round((cast(isnull(b.FYB,0) as float)/isnull(d.Feat,1))*100,2) [財管&銷售主管達成率%]
from [Group] a with (nolock)
left join #MR002TmpFYB b on b.GCode = a.GCode
left join MAN_Data c with (nolock) on c.Code = a.BossCode
left join FeatTarget d with (nolock) on d.GCode = a.GCode and d.[Period] = dbo.DateToPeriod(@d1) and d.FType = 2
left join #MR002TmpBoss e on e.GCode = a.GCode
left join MAN_Data f with (nolock) on f.Code = e.BossCode
where isnull(a.VoidDate,@d1+1)>@d1


drop table #MR002TmpFYB

end