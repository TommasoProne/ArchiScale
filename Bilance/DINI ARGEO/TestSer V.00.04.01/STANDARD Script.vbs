
Dim Mstring
Dim STRING_TERM
Dim ShapeIndex
Dim SHAPE_MAX

'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

		TimerTask.Interval=400

		'TERMINATORE SU CRLF

		STRING_TERM=vbcrlf

		Dim i

		SHAPE_MAX=23
		ShapeIndex=0

		For i=0 to SHAPE_MAX
			FrmCommand.ShpOutput(i).FillColor=VBRed
			FrmCommand.ShpOutput(i).FillStyle=VBSolid
		Next
End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()

	TimerTask.SendString "RALL" & vbcrlf
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


						FrmCommand.ShpOutput(ShapeIndex).FillColor=VBRed

						ShapeIndex=ShapeIndex+1
						if(ShapeIndex>SHAPE_MAX) then ShapeIndex=0

						FrmCommand.ShpOutput(ShapeIndex).FillColor=VBGreen


					'CharReceived.OutputString=String(5,chr(8)) & CharReceived.OutputString
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


