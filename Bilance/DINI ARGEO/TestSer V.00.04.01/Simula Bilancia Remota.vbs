
'********************************************************************************************
' Script per la richiesta peso a celle digitali ASCELL
'
'
' definire MAX_CELLE sotto
' Mettere nel COMMAND di TestSer questo {02}GCODICE{03}
' Mettere come Terminator Tx Manual a 000
' Mettere come Rx Terminator CR
'	Attivare il Check Tx Rts
' Attivare la Connessione
'	Attivare il Check Script
' Premere Start per iniziare il ciclo
'
'
'
' NB: questo script deve essere rinominato o copiato in Script.vbs nella stessa directory di TestSer
'
'			quando di accendono le celle si deve attendere la fine della fase di "boot" prima di inviare dati
'			altrimenti vanno in palla
'
'********************************************************************************************


Dim ContaSecondi
Dim Max_Secondi
Dim waitReceive

Dim LastOkReception
Dim TimeLastOkReception
Dim LastMax_Secondi

Dim StringRemoteScale(2)
Dim IndexString
Dim NumString



'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

	' AppendLog.RichAppendText &hFF,"PASSATO 1" & vbcrlf

	 StringRemoteScale(0)="000000"
	 StringRemoteScale(1)="001000"
	 
	 ' AppendLog.RichAppendText &hFF,"PASSATO 2" & vbcrlf
	 
	 NumString = 2
	 IndexString = 0
	 
	 'waitReceive=FALSE
	 waitReceive=TRUE
	 ' TimerTask.Interval=10000
	 Max_Secondi=5
	 TimerTask.Interval=1000

	' AppendLog.RichAppendText &hFF,"PASSATO 3" & vbcrlf

End Sub


'----------------------------------------------------
'	called at unload testser
'
'---------------------------------------------------
Public Sub EndTask()


End Sub

'----------------------------------------------------
'	called at timer
'
'			TimerTask.Interval
'			TimerTask.SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub Task()
		ContaSecondi=ContaSecondi+1

		' AppendLog.RichAppendText &hFF,"PASSATO " & ContaSecondi & vbcrlf
		
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


		' AppendLog.RichAppendText &hFF,"APPESA" & vbcrlf
		
		StringToSend.OutputString=StringRemoteScale(IndexString) + CHR(13)

		' AppendLog.RichAppendText &hFF,StringRemoteScale(IndexString) & vbcrlf
		
		if (ContaSecondi>=Max_Secondi) then
			ContaSecondi=0
			
			IndexString = IndexString +1
			
			if(IndexString >= NumString) then
				IndexString = 0				
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

		if(StringReceived.OutputString<>"" And Instr(StringReceived.OutputString,"OK")=0) then

			LastOkReception=Date()
			TimeLastOkReception=Time()
			LastMax_Secondi=Max_Secondi

			if(waitReceive) then
				AppendLog.RichAppendText &hFF,"RESET COUNTER" & vbcrlf
				ContaSecondi=0
			end if

			waitReceive=FALSE

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




