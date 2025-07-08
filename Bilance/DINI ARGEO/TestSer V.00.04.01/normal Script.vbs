
Dim Mstring
Dim STRING_TERM
Dim ExcelRow
Dim ExcelColumn
Dim ExcelSheet
Dim XLApp
Dim ExcelGetVersion
Dim WshNetwork
'Dim strUser
Dim strPCName
Dim ExcelFileName
Dim numeroprove
Dim TaskAttivo

const MAXPROVE=5 '(5)  0 infinite

'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()


	 TimerTask.Interval=5000
	 Mstring=""


		ExcelFileName=CStr(Day(Date)) & CStr(Month(Date)) & CStr(Year(Date)) & "-" & CStr(Hour(Time)) & CStr(Minute(Time)) & CStr(Second(Time))& ".XLS"
		' MsgBox ExcelFileName

		numeroprove=MAXPROVE

		TaskAttivo=True

		'TERMINATORE SU CRLF
		ExcelRow=1
		ExcelColumn=1

		Set WshNetwork = CreateObject("WScript.Network")
		'strUser = WshNetwork.UserName
		strPCName = WshNetwork.ComputerName


   Set XLApp = CreateObject("Excel.Application", strPCName)

   GetVersion = XLApp.Version


	 'if(GetVersion)

	 'Set XLApp=Nothing

		Set ExcelSheet = CreateObject("Excel.Sheet")
		ExcelSheet.Application.Visible = True

		STRING_TERM=vbcrlf

End Sub


'----------------------------------------------------
'	called at unload testser
'
'---------------------------------------------------
Public Sub EndTask()

	'MsgBox "USCITA"

	ExcelSheet.SaveAs "C:\DOCS\" & ExcelFileName
						' Close Excel with the Quit method on the Application object.
	ExcelSheet.Application.Quit
						' Release the object variable.
	Set ExcelSheet = Nothing


End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()

	if(TaskAttivo=True) then
		TimerTask.SendString "READ" & vbcrlf
	end if
	' msgBox "ATTIVO"
End Sub

'			StringReceived
' 		StringToSend
'			CharReceive
'			TimerTask
'
'----------------------------------------------------
'	Called before send string
'
' Object StringToSend
'								InputString			passed from TestSer
'								OutputString		returned at TestSer
'----------------------------------------------------
Public Sub SendString()
		StringToSend.OutputString=StringToSend.InputString
End Sub


'----------------------------------------------------
'	Called on received string
'
' Object StringReceived
'								InputString			passed from TestSer
'								OutputString		returned at TestSer
'----------------------------------------------------
Public Sub ReceiveString()

		'StringReceived.OutputString="QUESTA E' LA STRINGA RICEVUTA:" & chr(34) & StringReceived.InputString & chr(34)
		StringReceived.OutputString=StringReceived.InputString

End Sub

'----------------------------------------------------
'	Called on received char
'
' Object CharReceive
'								InputString			passed from TestSer
'								OutputString		returned at TestSer
'----------------------------------------------------
Public Sub ReceiveChar()
		Dim Pos

		Mstring=Mstring+CharReceived.InputString
		Pos=InStr(Mstring,STRING_TERM)

		if(Pos) then
				Pos=InStr(Mstring,"ST")
				if(Pos) then

					CharReceived.OutputString=Mid(Mstring,1,Pos-1) + "STABILE" + Mid(Mstring,Pos+2)
					'CharReceived.OutputString=String(5,chr(8)) & CharReceived.OutputString

						' Place some text in the first cell of the sheet.
						ExcelSheet.ActiveSheet.Cells(ExcelRow,ExcelColumn).Value = CharReceived.OutputString
						ExcelColumn=ExcelColumn+1

						if(ExcelColumn>10) then
								ExcelColumn=1
								ExcelRow=ExcelRow+1
						end if

						' eventualmente dopo X prove salva il file e finisce
						if(numeroprove) then

							numeroprove=numeroprove-1

							if(numeroprove=0) then
									EndTask()
									TaskAttivo=False
							end if

						end if



						' Save the sheet.
						'ExcelSheet.SaveAs "C:\DOCS\TEST.XLS"
						' Close Excel with the Quit method on the Application object.
						'ExcelSheet.Application.Quit
						' Release the object variable.
						'Set ExcelSheet = Nothing



				else
					CharReceived.OutputString="ERROR" & vbcrlf
				end if

				Mstring=""
		else
			CharReceived.OutputString=""
	  end if



'		Pos=InStr(CharReceived.InputString,"ST")
'		if(Pos) then
'			CharReceived.OutputString=Mid(CharReceived.InputString,1,Pos-1) + "STABILE" + Mid(CharReceived.InputString,Pos+2)
'		else
'			CharReceived.OutputString=CharReceived.InputString
'	  end if


' linea standard
'			CharReceived.OutputString=CharReceived.InputString

End Sub




