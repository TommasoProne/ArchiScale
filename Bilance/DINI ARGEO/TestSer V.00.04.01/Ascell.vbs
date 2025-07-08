
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


Dim Mstring
Dim STRING_TERM
Dim STRING_INIT

Dim peso1
Dim peso2
Dim sommavalida

Const  MAX_CELLE = 2

Dim pesi()
Dim pesiricevuti()
Dim CodiceCella
Dim UltimoPesoUtile
Dim StringaPesiSingoli





'/*=******************************************************************** 22/06/07
'INPUT:
'
'OUTPUT:
'
'[GENERICA]
'*****************************************************************************=*/

Private Sub AzzeraPesiRicevuti()
	Dim i

	for i=1 to MAX_CELLE
		pesiricevuti(i)=0
	next

End Sub




'/*=******************************************************************** 22/06/07
'INPUT:
'
'OUTPUT:
'
'[GENERICA]
'*****************************************************************************=*/

Private Function PesoValido()
	Dim i,valido

	valido=True

	 StringaPesiSingoli="  "
	for i=1 to MAX_CELLE
		 if(pesiricevuti(i)=0) then
			valido=False
			StringaPesiSingoli=""
			'exit for
		else
			StringaPesiSingoli =StringaPesiSingoli & "CELLA(" & CStr(i) & ") PESO =" & CStr(pesi(i)) & " "
		end if
	next

	PesoValido=valido

End Function



'/*=******************************************************************** 22/06/07
'INPUT:
'
'OUTPUT:
'
'[GENERICA]
'*****************************************************************************=*/

Public Function SommaPesi()
	Dim i,SommaTPesi

	SommaTPesi=0

	if(PesoValido()) then

			for i=1 to MAX_CELLE
		 		SommaTPesi=SommaTPesi+pesi(i)
			next

			AzzeraPesiRicevuti()
			UltimoPesoUtile=SommaTPesi
	else
		SommaTPesi=UltimoPesoUtile
	end if


	SommaPesi=SommaTPesi

End Function


'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()


	 TimerTask.Interval=0
	 Mstring=""

	 ReDim pesi(MAX_CELLE)
	 ReDim pesiricevuti(MAX_CELLE)

	 AzzeraPesiRicevuti()

	 STRING_TERM=CHR(3)
	 STRING_INIT=CHR(2)

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
		Dim Pos

		Pos=InStr(StringToSend.InputString,"CODICE")

		if(Pos) then

			' ciclo io tra le celle definite
			CodiceCella=CodiceCella+1

			if(CodiceCella>MAX_CELLE) then
				CodiceCella=1
			end if

			StringToSend.OutputString=Mid(StringToSend.InputString,1,Pos-1) & Cstr(CodiceCella) & Mid(StringToSend.InputString,Pos+6)
			'StringToSend.OutputString="PASSATO" & Pos &  StringToSend.OutputString & vbcrlf

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

End Sub

'----------------------------------------------------
'	Called on received char
'
' Object CharReceive
'								InputString			passed from TestSer
'								OutputString		returned at TestSer
'----------------------------------------------------
Public Sub ReceiveChar()
		Dim Pos,Index
		Dim Checksum

		Mstring=Mstring+CharReceived.InputString
		Pos=InStr(Mstring,STRING_TERM)

		if(Pos) then

				Pos=InStr(Mstring,STRING_INIT)

				'CharReceived.OutputString=" ** TROVATO TERM " & vbcrlf


				If(Pos) then
					' G2:000000.00:›
					' [02]G1:000000.00:š[03][0D]

					'CharReceived.OutputString=CharReceived.OutputString & " ** TROVATO INIT " & Mstring & vbcrlf
					'Calcola Checksum
					Checksum=0
					For index=2 to Len(Mstring)-3
						Checksum=(Checksum + Asc(Mid(Mstring,Index,1))) AND &HFF
					Next
					' Checksum=Checksum OR &HC0

					If (Checksum=Asc(Mid(Mstring,Len(Mstring)-2,1))) Then
							AppendLog.RichAppendText &HFF00FF,"CHECKSUM OK" & vbcrlf
					Else
							AppendLog.RichAppendText &hFF,"ERRORE CHECKSUM" & vbcrlf
					End if

						index=CInt(Mid(Mstring,3,1))

						if(index And index <= MAX_CELLE) then

							pesi(Index)=CDbl(Mid(Mstring,5,9))
							pesiricevuti(Index)=1

							' CharReceived.OutputString=CharReceived.OutputString & " SINGOLO PESO " & CStr(pesi(Index)) &  " - " & CStr(Index) & vbcrlf

						end if

						'CharReceived.OutputString= CharReceived.OutputString & " SOMMA PESI " & CInt(PesoValido()) & " - - " &  CStr(SommaPesi()) & vbcrlf
						CharReceived.OutputString= StringaPesiSingoli & "  SOMMA PESI =" &  CStr(SommaPesi()) & vbcrlf
						' CharReceived.OutputString= " SOMMA PESI =" &  CStr(SommaPesi()) & vbcrlf
				else
					CharReceived.OutputString="ERROR" & vbcrlf
				end if

		Mstring=""
  	' CharReceived.OutputString=CharReceived.OutputString & " ** AZZERA STRINGA "& Mstring  & vbcrlf

		else
			CharReceived.OutputString=""
	  end if


End Sub




