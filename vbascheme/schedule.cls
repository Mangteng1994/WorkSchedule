Sub CalendarSchedule()
     Dim targetYear As Integer, targetMonth As Integer
     Dim startDate As Date, endDate As Date
     Dim baseDate As Date, shiftOrder As Variant
     Dim calendarRow As Integer, calendarCol As Integer
     Dim i As Integer, daysInMonth As Integer
     Dim ws As Worksheet
     Dim settingsWs As Worksheet ' 新增：用于引用 Settings 工作表
     Dim shiftRange As Range ' 新增：用于读取班次顺序
     Dim cell As Range ' 新增：用于遍历班次单元格
     Dim tempArray() As String ' 新增：用于构建班次数组
     Dim k As Integer ' 新增：数组索引

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
     
     '【3】从 Settings 工作表读取排班规则配置
     On Error Resume Next
     Set settingsWs = ThisWorkbook.Sheets("Settings")
     If settingsWs Is Nothing Then
         MsgBox "未找到名为 'Settings' 的配置工作表！请先创建。", vbCritical
         Exit Sub
     End If
     On Error GoTo 0 ' 恢复错误处理

     ' 读取基准日期
     If IsDate(settingsWs.Range("B1").Value) Then
         baseDate = settingsWs.Range("B1").Value
     Else
         MsgBox "Settings 工作表 B1 单元格的基准日期格式无效！", vbCritical
         Exit Sub
     End If

     ' 读取班次顺序 (从 B2 开始向右读取，直到空单元格)
     Set shiftRange = settingsWs.Range("B2", settingsWs.Cells(2, settingsWs.Columns.Count).End(xlToLeft))
     If shiftRange.Columns.Count < 1 Or IsEmpty(settingsWs.Range("B2").Value) Then
         MsgBox "Settings 工作表 B2 单元格开始的班次顺序未配置或为空！", vbCritical
         Exit Sub
     End If

     ReDim tempArray(1 To shiftRange.Columns.Count) ' 调整数组大小
     k = 1
     For Each cell In shiftRange
         If Not IsEmpty(cell.Value) Then
             tempArray(k) = CStr(cell.Value)
             k = k + 1
         Else
             ' 如果中间遇到空单元格，则停止读取
             ReDim Preserve tempArray(1 To k - 1)
             Exit For
         End If
     Next cell
     shiftOrder = tempArray ' 将临时数组赋值给 shiftOrder

     ' 检查 shiftOrder 是否为空
     If Not IsArray(shiftOrder) Or UBound(shiftOrder) < LBound(shiftOrder) Then
         MsgBox "未能成功读取班次顺序！", vbCritical
         Exit Sub
     End If


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
             ' 调用 GetShift 时传递读取到的配置
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
     Dim offsetDays As Long ' 使用 Long 防止溢出
     Dim shiftCount As Integer

     ' 确保 shiftOrder 是有效的数组
     If Not IsArray(shiftOrder) Then
        GetShift = "错误:无效班次"
        Exit Function
     End If
     
     ' 获取班次数量 (数组从1开始)
     On Error Resume Next ' 处理空数组或未初始化的情况
     shiftCount = UBound(shiftOrder) - LBound(shiftOrder) + 1
     If Err.Number <> 0 Or shiftCount <= 0 Then
         GetShift = "错误:班次为空"
         On Error GoTo 0
         Exit Function
     End If
     On Error GoTo 0

     offsetDays = DateDiff("d", baseDate, currentDate)
     ' 修正模运算，确保索引在数组范围内 (LBound 到 UBound)
     GetShift = shiftOrder(((offsetDays Mod shiftCount) + shiftCount) Mod shiftCount + LBound(shiftOrder))
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

 ' --- 新增配置修改子过程 ---
 Sub ConfigureSettings()
     Dim settingsWs As Worksheet
     Dim newBaseDate As String
     Dim newShiftOrderStr As String
     Dim shiftArray As Variant
     Dim i As Integer
     Dim promptMsg As String
     Dim currentShifts As String

     On Error Resume Next
     Set settingsWs = ThisWorkbook.Sheets("Settings")
     If settingsWs Is Nothing Then
         MsgBox "未找到名为 'Settings' 的配置工作表！请先创建。", vbCritical
         Exit Sub
     End If
     On Error GoTo 0

     ' --- 获取并显示当前设置 ---
     currentShifts = ""
     On Error Resume Next ' 防止 B2 开始没有数据时出错
     For i = 2 To settingsWs.Cells(2, settingsWs.Columns.Count).End(xlToLeft).Column
         If Not IsEmpty(settingsWs.Cells(2, i).Value) Then
             currentShifts = currentShifts & settingsWs.Cells(2, i).Value & ","
         End If
     Next i
     If Len(currentShifts) > 0 Then currentShifts = Left(currentShifts, Len(currentShifts) - 1) ' 移除末尾逗号
     On Error GoTo 0

     ' --- 输入新的基准日期 ---
     promptMsg = "当前基准日期: " & Format(settingsWs.Range("B1").Value, "yyyy/mm/dd") & vbCrLf & vbCrLf & "请输入新的基准日期 (格式 YYYY/MM/DD):"
     newBaseDate = InputBox(promptMsg, "配置基准日期", Format(settingsWs.Range("B1").Value, "yyyy/mm/dd"))

     ' 验证日期格式并写入
     If IsDate(newBaseDate) Then
         settingsWs.Range("B1").Value = CDate(newBaseDate)
         settingsWs.Range("B1").NumberFormat = "yyyy/mm/dd" ' 设置单元格格式
     ElseIf newBaseDate <> "" Then ' 如果用户输入了但格式不对
         MsgBox "输入的日期格式无效！基准日期未更改。", vbExclamation
     End If ' 如果用户取消或输入空，则不更改

     ' --- 输入新的班次顺序 ---
     promptMsg = "当前班次顺序: " & currentShifts & vbCrLf & vbCrLf & "请输入新的班次顺序，用英文逗号分隔 (例如: 班次1,班次2,休息):"
     newShiftOrderStr = InputBox(promptMsg, "配置班次顺序", currentShifts)

     If newShiftOrderStr <> "" Then
         ' 清除旧的班次顺序 (从 B2 开始)
         settingsWs.Range("B2:XFD2").ClearContents ' 清除足够多的列

         ' 分割输入的字符串并写入
         shiftArray = Split(newShiftOrderStr, ",")
         For i = 0 To UBound(shiftArray)
             settingsWs.Cells(2, i + 2).Value = Trim(shiftArray(i)) ' 写入 B2, C2, ...
         Next i
         MsgBox "排班规则已更新！", vbInformation
     ElseIf newShiftOrderStr = "" And currentShifts <> "" Then ' 用户清空了输入框
         If MsgBox("您似乎清空了班次顺序，确定要删除所有班次吗？", vbQuestion + vbYesNo, "确认清空") = vbYes Then
              settingsWs.Range("B2:XFD2").ClearContents
              MsgBox "班次顺序已清空！", vbInformation
         Else
              MsgBox "班次顺序未更改。", vbInformation
         End If
     Else ' 用户取消
         MsgBox "班次顺序未更改。", vbInformation
     End If

 End Sub
