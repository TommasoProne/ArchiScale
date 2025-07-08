
Dim Mstring

' stringa standard
' ST,  250,00,kg,ST,   00,00,kg,ST,   00,00,kg,ST,   00,00,kg


Dim STRING_TERM
Dim ShapeIndex
Dim SHAPE_MAX

Dim COUNTER
Dim COUNTER2

Dim Pesi(4)

'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

		TimerTask.Interval=50

		'TERMINATORE SU CRLF

		STRING_TERM=vbcrlf

		COUNTER=0


		Dim i,u
		Dim mText

'		SHAPE_MAX=23
'		ShapeIndex=0

		For i=0 to 3
			comboIO(i).Clear
			For u=0 to 3
				select case u

					case 0:
									mText="    0.00"

					case 1:
									mText="  250.00"

					case 2:
									mText="  500.00"

					case 3:
									mText="  750.00"
				end select

				comboIO(i).Additem(mText)
			Next
		Next


  for i=4 to 7
    	comboIO(i).Additem("ST")
    	comboIO(i).Additem("US")
  next

  for i=0 to 7
		comboIO(i).ListIndex=0
	next


'		For i=0 to SHAPE_MAX
'			FrmCommand.ShpOutput(i).FillColor=VBRed
'			FrmCommand.ShpOutput(i).FillStyle=VBSolid
'		Next

End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()

'	For i=0 to 4
'		Pesi(i)=0
'	Next
'
'	for i=0 to 11
'
'		if(FrmCommand.ChkInput(i).Value) Then
'			index= i Mod 4
'			Pesi(Index)=Pesi(Index)+250
'		End if
'
'	Next

	''' ST,   0,00,kg,ST,   0,00,kg,ST,   0,00,kg,ST,   0,00,kg
	''' ST,  250,00,kg,ST,   00,00,kg,ST,   00,00,kg,ST,   00,00,kg
	''MString="ST," + FormatNumber(Pesi(0),5)

'	MString1 = FormatNumber(Pesi(0),2)
'	MString1 = String(8-Len(MString1)," ")+MString1

'	MString2 = FormatNumber(Pesi(1),2)
'	MString2 = String(8-Len(MString2)," ")+MString2

'	MString3 = FormatNumber(Pesi(2),2)
'	MString3 = String(8-Len(MString3)," ")+MString3

'	MString4 = FormatNumber(Pesi(3),2)
'	MString4 = String(8-Len(MString4)," ")+MString4


'	MString="ST," + MString1 + ",kg,ST," + MString2 + ",kg,ST," + + MString3 + ",kg,ST," + + MString4 + ",kg" + vbcrlf





	' MString="ST," + ComboIO(0).Text + ",kg,ST," + ComboIO(1).Text + ",kg,ST," + ComboIO(2).Text+ ",kg,ST," + ComboIO(3).Text+ ",kg" + vbcrlf

'	MString= ComboIO(4).Text & "," + ComboIO(0).Text + ",kg," & ComboIO(5).Text & "," + ComboIO(1).Text + ",kg," & ComboIO(6).Text & "," + ComboIO(2).Text+ ",kg," & ComboIO(7).Text & ","  + ComboIO(3).Text+ ",kg" + vbcrlf

	MString2 = Cstr(COUNTER)
	MString2 = String(5-Len(MString2)," ")+MString2 +".00"

	MString3 = Cstr(COUNTER2)
	MString3 = String(5-Len(MString3)," ")+MString3 +".00"

	MString= ComboIO(4).Text & "," + MString2 + ",kg," & ComboIO(5).Text & "," + MString3 + ",kg," & ComboIO(6).Text & "," + ComboIO(2).Text+ ",kg," & ComboIO(7).Text & ","  + ComboIO(3).Text+ ",kg" + vbcrlf

	COUNTER=COUNTER+1

	if(COUNTER>255) then
		COUNTER=0
		COUNTER2=COUNTER2+1
		if(COUNTER2>255) then
			COUNTER2=0
		end if
	end if



	TimerTask.SendString  MString & MString & MString & MString & MString & MString & MString & MString & MString

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





End Sub


