
Dim Mstring
Dim InitStringToSend
Dim Status
Dim Risposta



Public Sub ResetStatus()

    Status = 0
		InitStringToSend = ""

		TimerTask.Interval=250

		FormMain.Check2.Value = 1
		FormMain.Combo3.ListIndex = 1   ' 1 carattere di terminazione

		FormMain.Option3(2)= 1          ' Nessun Terminatore
		FormMain.Option4(3)= 1          ' Terminatore a caratteri
		FormMain.Check1.Value = 0       ' Nessuna Attesa risposta

		FormMain.cbosend.text = "M/THIS IS MY SCROLLING MESSAGE/"

    AppendLog.RichAppendText &hFA,"RESET STATUS" & vbcrlf
    
End Sub


'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

		ResetStatus()

End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()

	
		select case(Status)
		
		  case 1:
            AppendLog.RichAppendText &h10,"INIZIO TASK"  & vbcrlf
            Status = Status + 1

		  case 2:
            AppendLog.RichAppendText &h10,"INVIO ENQ"  & vbcrlf
            MString = Chr(5)    ' ENQ
				    TimerTask.SendString MString
				    Status = Status + 1

		  case 4:
            ' TimerTask.Interval = 10
						AppendLog.RichAppendText &h10,"INVIO STRINGA"  & vbcrlf
    				MString = Chr(2)    ' STX
    				MString = MString + InitStringToSend + LTrim(FormatNumber(CheckSumMod100(InitStringToSend),0))
				    MString = MString + Chr(3)    ' ETX
						TimerTask.SendString MString
						Status = Status + 1
				    
		  case 6:
						AppendLog.RichAppendText &h10,"ARRIVATO  ACK " &  StringReceived.InputString  & vbcrlf
						ResetStatus()
						' FormMain.chkEnableScript.Value = 0
						' WScript.Quit 0
		end select


AppendLog.RichAppendText &h10,"STATUS =" &  FormatNumber(Status,0)  & vbcrlf

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

		if(TimerTask.Interval) then
		
			if(Status = 0 ) then
			  Status = 1
			  InitStringToSend = StringToSend.InputString
			  AppendLog.RichAppendText &h10,"COPIA STRINGA -->" &  InitStringToSend  & vbcrlf
			  StringToSend.OutputString = ""
			else
	    	StringToSend.OutputString = StringToSend.InputString
	    	AppendLog.RichAppendText &h10,"STRINGA -->" &  StringToSend.OutputString  & vbcrlf
			end if
	end if
	
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

		AppendLog.RichAppendText &hFF,"ARRIVATO  -->" &  StringReceived.InputString  & vbcrlf
    

			select case (Status)
					case 3:
					      AppendLog.RichAppendText &hFF,"STAUTS 3" 
                if(Instr(StringReceived.InputString,CHR(6)) <> 0) then
                  Status = Status +1
                  AppendLog.RichAppendText &h20," -OK-"  & vbcrlf
								else
								  AppendLog.RichAppendText &hFF,"ERRORE KO"  & vbcrlf
								  ResetStatus()
								end if
					case 5
						if(Instr(StringReceived.InputString,CHR(3))<> 0) then
							  TimerTask.SendString CHR(6)
			  				Status =  Status + 1
						end if

			end select

   
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



public function CheckSumMod100(Frame)
		Dim Ret
		Dim SumValue
		Dim i

		SumValue = 0

		NumBytes = len(Frame)

		For i = 1 To NumBytes
			SumValue = (SumValue + Asc(mid(Frame,i,1))) Mod 256
		Next

		Ret = SumValue Mod 100

		CheckSumMod100=Ret
end function
