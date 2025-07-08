
Dim Mstring

' stringa standard
' ST,  250,00,kg,ST,   00,00,kg,ST,   00,00,kg,ST,   00,00,kg

Dim STRING_TERM
Dim ShapeIndex
Dim SHAPE_MAX

Dim Pesi(4)

Dim Risposta

'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

		' TimerTask.Interval=250
		TimerTask.Interval=10

		'TERMINATORE SU CRLF

		STRING_TERM=vbcrlf

  '----------------------------------------- '
  ' Test FCS
  '----------------------------------------- '
  ' Dim Test
  ' Test="@00RJ00000005"
  ' Test=Test+FCS(Test)
  ' TextIO(0).Text=Test
  '----------------------------------------- '

		Dim i,u
		Dim mText

'		SHAPE_MAX=23
'		ShapeIndex=0

		for i=0 to 17
		  comboIO(i).Clear
		  comboIO(i).AddItem("0000")
		  comboIO(i).AddItem("0001")
    next

    for i=0 to 7
      TextIO(i).Text="0"
    next

  for i=0 to 17
		comboIO(i).ListIndex=0
	next

	 TextIO(7).Text="00"

  comboIO(18).Clear
  for i=0 to 15
    ComboIO(18).Additem(Format0String(Hex(2^i),8) + Format0String("0",4))
  next
  comboIO(18).ListIndex=0


	'ready
	comboIO(0).BackColor=vbGreen
	'ciclo
	comboIO(1).BackColor=vbGreen

	'forse movimento
	comboIO(2).BackColor=vbCyan

	' Paranchi alti
	For i=4 to 7
		comboIO(i).BackColor=vbYellow
	Next

	'Posizione X
	TextIO(0).BackColor=vbYellow
	'Posizione Y
	TextIO(1).BackColor=vbYellow


	' Stato di Allarme
	comboIO(3).BackColor=vbRed

	' Codice Allarme
	comboIO(18).BackColor=vbRed


	' Allarmi extracorsa Y e X
	For i=8 to 11
		comboIO(i).BackColor=vbMagenta
	Next



End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()

'		if(len(Risposta) ) then
'			TimerTask.SendString Risposta
'			Risposta=""
'		end if

	' MString="ST," + ComboIO(0).Text + ",kg,ST," + ComboIO(1).Text + ",kg,ST," + ComboIO(2).Text+ ",kg,ST," + ComboIO(3).Text+ ",kg" + vbcrlf

	' MString= ComboIO(4).Text & "," + ComboIO(0).Text + ",kg," & ComboIO(5).Text & "," + ComboIO(1).Text + ",kg," & ComboIO(6).Text & "," + ComboIO(2).Text+ ",kg," & ComboIO(7).Text & ","  + ComboIO(3).Text+ ",kg" + vbcrlf

	' TimerTask.SendString  MString ' "RALL" & vbcrlf

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

    ' AppendLog.RichAppendText vbGreen,"RICEVUTO COMANDO" & vbcrlf

		Mstring=StringReceived.InputString

    if(instr(Mstring,"WD")) then
      ' AppendLog.RichAppendText vbRed,"RICEVUTO COMANDO WD" & vbcrlf
      AppendLog.RichAppendText vbGreen,Mstring & vbcrlf & vbcrlf & vbcrlf & vbcrlf
		  Mstring="@" & Format0String(TextIO(7).text,2) & "WD00"
		  Mstring=Mstring & FCS(Mstring) & "*" & vbcr
		  ' TimerTask.SendString Mstring
		  Risposta=Mstring
		  TimerTask.SendString Risposta
		elseif(instr(Mstring,"RD")) then

      ' AppendLog.RichAppendText vbRed,"RICEVUTO COMANDO RD" & vbcrlf

      Mstring="@" & Format0String(TextIO(7).text,2) & "RD00"

			' primi 3
			' Word 200 201 202
      for i=0 to 2
		    Mstring=Mstring & Format0String(ComboIO(i).Text,4)
		  next

			' vuoto
			' Word 203
			Mstring=Mstring & Format0String("0",4)

			' paranchi
			' Word 204 205 206 207
      for i=4 to 7
		    Mstring=Mstring & Format0String(ComboIO(i).Text,4)
		  next

		  ' posizione X e Y
		  ' Word 208 209
		  ' Word 210 211
		  ' Mstring=Mstring & Format0String(Hex(Clng(TextIO(0).Text)),8) & Format0String(Hex(Clng(TextIO(1).Text)),8)


		  Mstring=Mstring & Format0String(Hex(Clng(TextIO(0).Text)),4) & "0000" & Format0String(Hex(Clng(TextIO(1).Text)),4) & "0000"


		  'Allarme
		  ' Word 212
		  Mstring=Mstring & Format0String(ComboIO(3).Text,4)


		' Allarmi extracorsa Y e X
		' Word 213 214 215 216
		For i=8 to 11
			Mstring=Mstring & Format0String(ComboIO(i).Text,4)
		Next


		' vuoto
		' Word 217
		' Mstring=Mstring+Format0String("0",4)

		' Codice Allarme
		' Word 218 219
	   Mstring=Mstring & ComboIO(18).Text




		  Mstring=Mstring & FCS(Mstring) & "*" & vbcr

      ' AppendLog.RichAppendText &HFF00FF,"STRINGA DA MANDARE:"& Mstring & vbcrlf
		  ' TimerTask.SendString Mstring
		  Risposta=Mstring


 			TimerTask.SendString Risposta

		end if

End Sub

'----------------------------------------------------
'	Called on received char
'
' Object CharReceive
'								InputString			passed from TestSer
'								OutputString		returned at TestSer
'----------------------------------------------------
Public Sub ReceiveChar()
			CharReceived.OutputString=CharReceived.InputString
End Sub


'---------------------------------------------------------
' Calcola l'FCS di un frame
'
'
public function FCS(Frame)
		Dim Ret
		Dim XorValue

		XorValue = 0

		NumBytes = len(Frame)

		For i = 1 To NumBytes
			XorValue = Asc(mid(Frame,i,1)) Xor XorValue
		Next


		Ret = Hex(XorValue)

		If len(Ret) = 1 Then Ret = "0" & Ret

		FCS=Ret
end function


'------------------------------------------------'
' formatta la stringa passata su 4 caratteri     '
' non esegue controlli sui caratteri passati     '
'------------------------------------------------'
public function Format0String(mstring,numchar)
  Dim lenstr

  lenstr=len(mstring)

  if(lenstr>numchar) then
    mstring=left(mstring,numchar)
  elseif(lenstr<numchar) then
      mstring=string(numchar-lenstr,"0") + mstring
  end if

  Format0String=mstring
end function



public function CheckSumMod100(Frame)
		Dim Ret
		Dim SumValue

		SumValue = 0

		NumBytes = len(Frame)

		For i = 1 To NumBytes
			SumValue = (SumValue + Asc(mid(Frame,i,1))) Mod 256
		Next

		Ret = SumValue Mod 100

		CheckSumMod100=Ret
end function
