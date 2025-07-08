
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


Dim waitReceive
Dim IndexCommand

Dim TxStringa



Dim SendReceive
Dim ContaTimeOut


Class ComandoRisposta
	Private m_Comando
	Private m_RispostaOK
	Private m_RispostaKO
	Private m_Codice
	Private m_InizioStringa
	Private m_Terminatore


Public Sub Class_Initialize
	m_Comando=""
	m_RispostaOK=""
	m_RispostaKO=""
	m_Codice="01"
	m_InizioStringa=Chr(27)
	m_Terminatore=Chr(2)
End Sub


Public Sub AppendCommand(Comando,RispostaOK,RispostaKO)
	m_Comando=Comando
	m_RispostaOK=RispostaOK
	m_RispostaKO=RispostaKO
End Sub


Public Sub CodeInizioFine(Codice, Inizio,Fine)
	m_Codice=Codice
	m_InizioStringa=Inizio
	m_Terminatore=Fine
End Sub

'------------------------------------------------------------------------
' Prende il comando
'------------------------------------------------------------------------
Public Function GetCommand()

	if (Instr(m_Comando,"ATTESA")>0) Then
		GetCommand=m_Comando
	Else
		GetCommand=m_InizioStringa+m_Codice+m_Comando+m_Terminatore
	End if


End Function

'------------------------------------------------------------------------
' Prende la risposta OK
'------------------------------------------------------------------------
Public Function GetRispostaOK()

	if (Instr(m_Comando,"ATTESA")>0) Then
		GetRispostaOK=m_RispostaOK
	Else
		GetRispostaOK=m_InizioStringa+m_Codice+m_RispostaOK+m_Terminatore
	End if
End Function


'------------------------------------------------------------------------
' Prende la risposta KO
'------------------------------------------------------------------------
Public Function GetRispostaKO()

	if (Instr(m_Comando,"ATTESA")>0) Then
		GetRispostaKO=m_RispostaKO
	Else
		GetRispostaKO=m_InizioStringa+m_Codice+m_RispostaKO+m_Terminatore
	End if
End Function



'------------------------------------------------------------------------
' Prende il terminatore
'------------------------------------------------------------------------
Public Function GetTerminatore()
	GetTerminatore=m_InizioStringa+m_Codice+m_RispostaKO+m_Terminatore
End Function

'------------------------------------------------------------------------
' Prende il Inizio
'------------------------------------------------------------------------
Public Function GetInizio()
	GetInizio=m_InizioStringa
End Function

'------------------------------------------------------------------------
' Prende il Codice
'------------------------------------------------------------------------
Public Function GetCodice()
	GetCodice=m_Codice
End Function



 Private Sub Class_Terminate   ' Setup Terminate event.
      ' MsgBox("Comando Risposta terminated")
End Sub


End Class




Dim AComandiRisposte
Dim MCollection

'01SKD
'01SKD
'01SKD
'01TSTCLR

'01WRYYOGURT BANANA   262,0gr P.P.POLL
'01INP1613I0010
'01SKD
'01SKD
'01SKD
'01TSTCLR
'01WRYTEST TEST TEST  262,0gr P.P.POLL
'01ATS01
'01WRYNr. Macchina                    
'01WBU0                               
'01INP1603I0010
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD
'01OIN
'01RBU
'01WRYMacchina nr.  3 BRIK Nr.3       
'01EKB
'01ATS11
'01ATS01
'01WRYCodice Prod. Ean                
'01WBU0                               
'01INP1613I0010
'01SKD
'01SKD
'01SKD
'01SKD
'01SKD



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
	 ' TimerTask.Interval=200
	 TimerTask.Interval=10
	IndexCommand=0

	ContaTimeOut=0
	SendReceive=1

	Set MCollection = CreateObject("Scripting.Dictionary")



	For i=0 to 24
		Set CComandiRisposte= New ComandoRisposta
		CComandiRisposte.CodeInizioFine "01",Chr(27),Chr(2)
		MCollection.Add i,CComandiRisposte
	Next



	MCollection.Item(0).AppendCommand "TSTCLR","TSTOK","ERR"
	MCollection.Item(1).AppendCommand "ATS01","ATSOK","ERR"
	MCollection.Item(2).AppendCommand "WRYYOGURT BANANA   262,0gr P.P.POLL","WRYOK","ERR"

	MCollection.Item(3).AppendCommand "ATS01","ATSOK","ERR"
	MCollection.Item(4).AppendCommand "WRYNr. Macchina                    ","WRYOK","ERR"
	MCollection.Item(5).AppendCommand "WBU0","WBUOK","ERR"
	MCollection.Item(6).AppendCommand "INP1613I0010","INPOK","ERR"
	MCollection.Item(7).AppendCommand "SKD","SKDI0","SKDI3"
	MCollection.Item(8).AppendCommand "RBU","RBU0                               ","ERR"


	MCollection.Item(9).AppendCommand "WRYMacchina nr.  3 BRIK Nr.3       ","WRYOK","ERR"
	MCollection.Item(10).AppendCommand "EKB","EKBOK","ERR"

	MCollection.Item(11).AppendCommand "ATS11","ATSOK","ERR"
	MCollection.Item(12).AppendCommand "ATTESA TASTO","ENT","CLR"
	MCollection.Item(13).AppendCommand "ATS01","ATSOK","ERR"


	MCollection.Item(14).AppendCommand "WBU0","WBUOK","ERR"
	MCollection.Item(15).AppendCommand "INP1613I0010","INPOK","ERR"
	MCollection.Item(16).AppendCommand "SKD","SKDI0","SKDI3"
	MCollection.Item(17).AppendCommand "OIN","OINENT","INCLR"
	MCollection.Item(18).AppendCommand "RBU","RBU0                               ","ERR"



	MCollection.Item(19).AppendCommand "ATS11","ATSOK","ERR"
	MCollection.Item(20).AppendCommand "ATTESA TASTO","ENT","CLR"
	MCollection.Item(21).AppendCommand "ATS01","ATSOK","ERR"

	MCollection.Item(22).AppendCommand "RBU","RBU0                               ","ERR"
	MCollection.Item(23).AppendCommand "EKB","EKBOK","ERR"

	MCollection.Item(24).AppendCommand "TSTCLR","TSTOK","ERR"


'
'	For i=0 to 10
'		Set AComandiRisposte= New ComandoRisposta
'		AComandiRisposte.CodeInizioFine "01",Chr(27),Chr(2)
'	Next
'
'
'	AComandiRisposte(0).AppendCommand "WRYYOGURT BANANA   262,0gr P.P.POLL","WRYOK","ERR"
'	AComandiRisposte(1).AppendCommand "SKD","SKDI0","SKDI3"
'	AComandiRisposte(2).AppendCommand "INP1613I0010","INPOK","ERR"
'
'	AComandiRisposte(3).AppendCommand "ATS01","ATSOK","ERR"
'	AComandiRisposte(4).AppendCommand "ATS11","ATSOK","ERR"
'	AComandiRisposte(5).AppendCommand "WBU0","WBUOK","ERR"
'
'	AComandiRisposte(6).AppendCommand "OIN","INENT","INCLR"
'	AComandiRisposte(7).AppendCommand "TSTCLR","WBUOK","ERR"
'	AComandiRisposte(8).AppendCommand "RBU","RBU","ERR"
'	AComandiRisposte(9).AppendCommand "EKB","EKBOK","ERR"
'
'	AComandiRisposte(10).AppendCommand "TSTCLR","TSTOK","ERR"



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

			'MsgBox(AComandiRisposte(IndexCommand).GetCommand())

			'StringToSend.OutputString = AComandiRisposte(IndexCommand).GetCommand()

				if(SendReceive=1) then

					Dim MCommand

					MCommand=MCollection.Item(IndexCommand).GetCommand

					SendReceive=2
					ContaTimeOut=0

					if(Instr(MCommand,"ATTESA")) Then
										AppendLog.RichAppendText vbCyan,MCommand & vbCrLf
					Else
						AppendLog.RichAppendText &hFF,"TX: "
						TimerTask.SendString MCommand
					End if



			Else

				if(Instr( MCollection.Item(IndexCommand).GetCommand,"ATTESA")=0) then
					ContaTimeOut=ContaTimeOut+1

					if(ContaTimeOut>5) then
							ContaTimeOut=0
							SendReceive=1

							AppendLog.RichAppendText &hFF,"Time Out " & vbcrlf
					End if
				End if
			End if

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


			StringToSend.OutputString = StringToSend.InputString


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

		if(StringReceived.OutputString<>"") Then

				AppendLog.RichAppendText vbMagenta," Test: " &  MCollection.Item(IndexCommand).GetRispostaOK & " E " & MCollection.Item(IndexCommand).GetRispostaKO & vbcrlf

			'risposta giusta
			if(Instr(StringReceived.OutputString,MCollection.Item(IndexCommand).GetRispostaOK)>0) then

						AppendLog.RichAppendText vbMagenta,"OK Stringa " & vbcrlf
					 IndexCommand=IndexCommand+1

					 if(IndexCommand>=MCollection.Count) then
				  		IndexCommand=0
					 End if

					SendReceive=1
					ContaTimeOut=0

			Else
				'risposta sbagliata
				if(Instr(StringReceived.OutputString,MCollection.Item(IndexCommand).GetRispostaKO)>0) then

					if(InStr(StringReceived.OutputString,"ERR")) then
						AppendLog.RichAppendText vbRed,"Errore Stringa " & vbcrlf
					End if

					SendReceive=1
					ContaTimeOut=0
				End if

			End if

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




