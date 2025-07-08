
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


'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

	 'waitReceive=FALSE
	 waitReceive=TRUE
	 ' TimerTask.Interval=10000
	 Max_Secondi=30
	 TimerTask.Interval=1000


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



		' quindi 60 * 5  = 300 sono 5 minuti

		if(waitReceive) then
			ContaSecondi=0

		end if

		AppendLog.RichAppendText &hFF,"SECONDI " &  Max_Secondi-ContaSecondi & " AL RESET - ULTIMA COMUNICAZIONE :" & LastOkReception & " " & TimeLastOkReception & " Minuti " & (LastMax_Secondi/60) &vbcrlf

		if (ContaSecondi>=Max_Secondi) then
			ContaSecondi=0
			waitReceive=TRUE
			Max_Secondi=Max_Secondi+120
			StringToSend.OutputString="CMDRESET" + CHR(13) + CHR(10)
			AppendLog.RichAppendText &hFF,"RESET STRUMENTO ATTESA RESET COUNTER" & vbcrlf
		else
			StringToSend.OutputString=StringToSend.InputString

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




