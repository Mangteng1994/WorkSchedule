Sub CalendarSchedule()
     Dim targetYear As Integer, targetMonth As Integer
     Dim startDate As Date, endDate As Date
     Dim baseDate As Date, shiftOrder As Variant
     Dim calendarRow As Integer, calendarCol As Integer
     Dim i As Integer, daysInMonth As Integer
     Dim ws As Worksheet
     
     '【1】用户输入验证
     On Error Resume Next
     targetYear = InputBox("请输入年份（如2025）", "年份输入")
     If targetYear < 2000 Or targetYear > 2100 Then
         MsgBox "无效年份输入", vbCritical
         Exit Sub
     End If
     targetMonth = InputBox("请输入月份（1-12）", "月份输入")
     If targetMonth < 1 Or targetMonth > 12 Then
         MsgBox "无效月份输入", vbCritical
         Exit Sub
     End If
     startDate = DateSerial(targetYear, targetMonth, 1)
     endDate = DateSerial(targetYear, targetMonth + 1, 1) - 1
     daysInMonth = Day(endDate)
     
     '【2】初始化日历框架（网页4+网页7逻辑）[4,7](@ref)
     Set ws = ThisWorkbook.Sheets.Add(After:=Sheets(Sheets.Count))
     ws.Name = Format(startDate, "yyyy-mm")
     With ws
         ' 标题设置
         .Range("A1:G1").Merge
         .Range("A1") = Format(startDate, "yyyy年m月") & "排班表"
         .Range("A2:G2") = Array("周一", "周二", "周三", "周四", "周五", "周六", "周日") ' 修改为周一开始
         .Columns("A:G").ColumnWidth = 14
         .Rows(1).RowHeight = 30
     End With
     
     '【3】排班规则配置（网页1核心逻辑）[1](@ref)
     baseDate = DateSerial(2025, 4, 26) ' 基准日期班次
     shiftOrder = Array("夜班", "下班", "休息", "休息", "白班", "连班")
     
     '【4】智能日期填充（网页8日期定位优化）[8](@ref)
     calendarRow = 3
     Dim firstDayCol As Integer
     firstDayCol = Weekday(startDate, vbMonday) ' 修改为周一开始
     
     ' 填充首周前导空白（解决空白行关键）
     For i = 1 To firstDayCol - 1
         ws.Cells(calendarRow, i).Value = ""
     Next i
     
     '【5】循环生成日历（网页3颜色标记整合）[3](@ref)
     For i = 1 To daysInMonth
         Dim currentDate As Date
         currentDate = DateSerial(targetYear, targetMonth, i)
         
         ' 动态定位行列（网页7定位算法）[7](@ref)
         calendarCol = Weekday(currentDate, vbMonday) ' 修改为周一开始
         If calendarCol = 1 And i > 1 Then calendarRow = calendarRow + 1
         
         ' 写入日期与班次（网页6数据整合）[6](@ref)
         With ws.Cells(calendarRow, calendarCol)
             Dim currentShift As String
             currentShift = GetShift(currentDate, baseDate, shiftOrder)
             .Value = i & vbNewLine & currentShift
             .NumberFormat = "@"
             .RowHeight = 45
             Call SetShiftColor(ws.Cells(calendarRow, calendarCol), currentShift)
         End With
         
         ' 智能换行控制（解决两行空格问题）
         If calendarCol = 7 And i < daysInMonth Then
             calendarRow = calendarRow + 1
             ' 预填充下周前导空白
             If Weekday(currentDate + 1, vbMonday) > 1 Then
                 For j = 1 To Weekday(currentDate + 1, vbMonday) - 1
                     ws.Cells(calendarRow, j).Value = ""
                 Next j
             End If
         End If
     Next i
     
     '【6】格式美化（网页4样式优化）[4](@ref)
     With ws.UsedRange
         .Borders.LineStyle = xlContinuous
         .HorizontalAlignment = xlCenter
         .VerticalAlignment = xlCenter
     End With
     MsgBox "日历排班表已生成！", vbInformation
 End Sub
 
 Function GetShift(currentDate As Date, baseDate As Date, shiftOrder As Variant)
     Dim offsetDays As Integer
     offsetDays = DateDiff("d", baseDate, currentDate)
     GetShift = shiftOrder((offsetDays Mod 6 + 6) Mod 6)
 End Function
 
 Sub SetShiftColor(cell As Range, shiftType As String)
     Select Case shiftType
         Case "夜班":
             cell.Interior.Color = RGB(255, 230, 204) ' 橙色
             cell.Font.Bold = True
         Case "白班":
             cell.Interior.Color = RGB(198, 224, 180) ' 绿色
             cell.Font.Bold = True
         Case "连班":
             cell.Interior.Color = RGB(220, 230, 250) ' 蓝色
             cell.Font.Bold = True
         Case "休息":
             cell.Font.Color = RGB(150, 150, 150) ' 灰色
             cell.Interior.Color = RGB(255, 255, 255)
     End Select
 End Sub
