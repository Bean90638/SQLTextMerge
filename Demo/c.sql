

/* ZX30026MR005
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
1.以【分行】計算月份及當日件數、手續費收入(進件FYB)
2.資料來源:進件
3.篩選條件:單一日期篩選，以選擇日期所屬月份，計算當月1號至選擇日期的累計報繳(進件)
4.件數:進件
5.手續費收入:進件(FYB)
6.須可匯出，欄位比照介面上的欄位
7.匯出格式為Excel和CSV(逗號分隔)
 */
CREATE PROCEDURE [dbo].[ZX30026MR005] 
@CNO int,@DateTP int ,@d1 datetime,@d2 datetime,@JT int
AS
BEGIN
SET NOCOUNT ON;

Create Table #MR005TmpD(DlvCoded int)
Create Table #MR005TmpM(DlvCodem int)
Create Table #MR005Tmp(GCode int,cntd int,FYBd int,cntm int,FYBm int)

--取當日進件
insert #MR005TmpD (DlvCoded)
select a.DlvCode
from Delivery a with (nolock)
inner join Dlv_Type b with (nolock) on a.DType=b.DType and b.Feat=1 --契約計績
inner join Dlv_Flow c with (nolock) on a.FL=c.FL and c.Feat=1 --流程計績
where a.CNO = @CNO
and (Case When @DateTP=1 Then dbo.Date(a.AplyDate) else dbo.Date(a.AplyDate) end) between @d1 and @d2
and a.Job_Type = (Case When @JT = 0 Then a.Job_Type else @JT end)

--計算當日件數及報繳
insert #MR005Tmp (GCode,cntd,FYBd,cntm,FYBm)
select a.GCode,count(1),sum(isnull(c.FYB,0))+sum(isnull(a.FYB,0)),0,0
from Delivery a  with (nolock)
inner join #MR005TmpD b on a.DlvCode = b.DlvCoded
left join Dlv_Content c with (nolock) on a.DlvCode = c.DlvCode
group by a.GCode

--取當月進件
insert #MR005TmpM (DlvCodem)
select a.DlvCode
from Delivery a with (nolock)
inner join Dlv_Type b with (nolock) on a.DType=b.DType and b.Feat=1 --契約計績
inner join Dlv_Flow c with (nolock) on a.FL=c.FL and c.Feat=1 --流程計績
where a.CNO = @CNO
and (Case When @DateTP=1 Then dbo.Date(a.AplyDate) else dbo.Date(a.AplyDate) end) 
between dbo.PeriodToDate(dbo.DateToPeriod(@d1),0) and @d1
and a.Job_Type = (Case When @JT = 0 Then a.Job_Type else @JT end)

--計算當月件數及報繳
insert #MR005Tmp (GCode,cntd,FYBd,cntm,FYBm)
select a.GCode,0,0,count(1),sum(isnull(c.FYB,0))+sum(isnull(a.FYB,0))
from Delivery a  with (nolock)
inner join #MR005TmpM b on a.DlvCode = b.DlvCodem
left join Dlv_Content c with (nolock) on b.DlvCodem = c.DlvCode
group by a.GCode

select a.[Name] [分行],sum(isnull(b.cntd,0)) [件數],sum(isnull(b.FYBd,0)) [手續費收入],sum(isnull(b.cntm,0)) [當月累計件數]
,sum(isnull(b.FYBm,0)) [當月累計手續費收入] 
from [Group] a  with (nolock)
left join #MR005Tmp b on b.GCode = a.GCode
where isnull(a.VoidDate,@d1+1)>@d1
group by a.[Name]

drop table #MR005TmpD
drop table #MR005TmpM
drop table #MR005Tmp
end