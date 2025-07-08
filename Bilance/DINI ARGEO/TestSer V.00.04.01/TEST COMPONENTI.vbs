
Dim mString

'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()
	Dim Obj
	Dim indice
	On Error Resume Next

		AppendLog.RichAppendText vbRed,"PROVA" & vbcrlf

		 For Each Obj In FormMain

		 	Indice=Obj.Index

			AppendLog.RichAppendText vbRed,Obj.Name & " Indice " & Indice & vbcrlf
		 next

		TimerTask.Interval=50


End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()


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

