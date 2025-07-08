
'********************************************************************************************
' Script per simulare un LCS cella digitale
'
'
'
'********************************************************************************************


Dim Mstring
Dim STRING_TERM
Dim STRING_DLE
Dim STRING_INIT
Dim STRING_OK

Dim peso1
Dim peso2
Dim sommavalida

Const  MAX_CELLE = 2

Dim pesi()
Dim pesiricevuti()
Dim CodiceCella
Dim UltimoPesoUtile
Dim StringaPesiSingoli
Dim StartPesi
Dim EndPesi
Dim CiclaPesi
Dim Volte
Dim Diminuisci




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

	 Randomize

	 TimerTask.Interval=0
	 Mstring=""


	 ReDim pesi(MAX_CELLE)
	 ReDim pesiricevuti(MAX_CELLE)

	' Set WshShell = CreateObject("WScript.Shell")
	' Set WshNetwork = CreateObject("WScript.Network")
	' WshShell.Run"C:\WINXPPRO\system32\calc.exe"

	 AzzeraPesiRicevuti()

	 'StartPesi=300000000
	 'EndPesi=-300000000
	 StartPesi=10000000
	 EndPesi=-10000000
	 CiclaPesi=StartPesi
	 Volte=0
	 Diminuisci=1

	 STRING_TERM=CHR(3)
	 STRING_DLE=CHR(&H10)
	 STRING_INIT=CHR(2)
	 STRING_OK=CHR(6)

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
		'StringToSend.OutputString=STRING_OK

		' 2-1-1-6C-4D-B8-3-98-3-
		' 2-1-1-6C-4D-B8-128- 98-3-




		Dim PesoSend
		Dim MSend
		Dim MSendMask
		Dim CSum
		Dim Index
		Dim MByte


'		Volte=Volte+1

'		if(Volte>5) then
'			Volte=0
'			CiclaPesi=CiclaPesi-Diminuisci

'		end if


'	 if(CiclaPesi<EndPesi) then
'	 	CiclaPesi=StartPesi
'	 end if


'		PesoSend=CiclaPesi

'		AppendLog.RichAppendText &HFF00FF,"              ---- PESO INVIATO =" & CStr(PesoSend) & vbcrlf


		'PesoSend=Int((30000000 * Rnd) + 1)


		'PesoSend=300000000
		PesoSend=210000000


	AppendLog.RichAppendText &HFF00FF,"              ---- PESO INVIATO =" & CStr(PesoSend) & vbcrlf


		MSend=CHR(2) & CHR(1)

		'StringToSend.OutputString="PIPPO ## " & PesoSend & " ## " & ( (PesoSend / &H1000000) AND &HFF) & " ## " & ( (PesoSend / &H0010000)  AND &HFF ) & " ## " & ( (PesoSend / &H0000100) AND &HFF ) & " ## " & ((PesoSend AND &HFF))
		'	& ((PesoSend AND &HFF000000) / &H1000000) & " ## " &  ( (PesoSend AND &HFF0000) / &H10000) & " ## " & ((PesoSend AND &HFF00) / &H100) & " ## " & ((PesoSend AND &HFF))



		' ( (PesoSend / &H0010000)  AND &HFF ) & " ## " & ( (PesoSend / &H0000100) AND &HFF ) & " ## " & ((PesoSend AND &HFF))
'		MSend=MSend + Chr(( (PesoSend / &H1000000) AND &HFF))
'		MSend=MSend + Chr(( (PesoSend / &H0010000)  AND &HFF ))
'		MSend=MSend + Chr(( (PesoSend / &H0000100) AND &HFF ))
'		MSend=MSend + Chr(( (PesoSend AND &HFF)))

		'MByte=Int(( PesoSend AND &HFF000000) / &H1000000 )

		MByte=( Int(PesoSend/&H1000000) AND &HFF )
		MSend=MSend + Chr(MByte)

'		MByte=Int((PesoSend AND &HFF0000) / &H10000   )

		MByte=( Int(PesoSend/&H10000) AND &HFF )
		MSend=MSend + Chr(MByte)


		'MByte=Int( (PesoSend AND &HFF00) / &H100   )
		MByte=( Int(PesoSend/&H100) AND &HFF )
		AppendLog.RichAppendText &HFF00FF,"              ---- CCCC =" &  Hex(MByte) & "             " & vbcrlf


		MSend=MSend + Chr(MByte)

		MByte=(PesoSend AND &HFF)
		MSend=MSend + Chr(MByte)


		MSend=MSend + CHR(3)

		For Index=1 to LEN(MSend)

			CSum=CSum XOR ASC(Mid(MSend,Index,1))

		Next


		MSend=MSend+CHR(CSum)

		MSendMask=CHR(2) & CHR(1)

		For Index=3 To LEN(MSend)

			ToSend=Asc(Mid(MSend,Index,1))

			if(ToSend = &H10 Or ToSend = &H02 Or ToSend = &H03 Or ToSend = &H06) then
				MSendMask=MSendMask + CHR(&H10) + CHR(ToSend+128)
			else
				MSendMask=MSendMask+CHR(ToSend)
			end if

		Next

		MSendMask=MSendMask + CHR(3)

		StringToSend.OutputString=MSendMask

		' 02 01 10 80 4B 8C C4 10 83 10 80 03

		'StringToSend.OutputString=chr(&H2) & chr(&H1) & chr(&H1) & chr(&H6C) & chr(&H4D) & chr(&HB8) & STRING_DLE & chr(&H3 + 128) & chr(&H98) & chr(&H3)

		'StringToSend.OutputString=chr(&H2) & chr(&H1) & chr(&H1) & chr(&H6C) & chr(&H4D) & chr(&HB8) & STRING_DLE & chr(&H3 + 128) & chr(&H98) & chr(&H3)

		' 2-1-0-0-0-0-3-0-3-

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
'		Dim Pos,Index
'		Dim StringFiltered
'		Dim Peso,ValByte
'
'		Mstring=Mstring+CharReceived.InputString
'		Pos=InStr(Mstring,STRING_TERM)
'
'		if(Pos) then
'
'				Pos=InStr(Mstring,STRING_INIT)
'
'				'CharReceived.OutputString=" ** TROVATO TERM " & vbcrlf
'
'
'				if(Pos) then
'					' 02 01 00 00 00 00 05 10 86 03
'
'					CharReceived.OutputString=""
'
'					'elimino i caratteri DLE eventuali
'					FOR Index=1 to Len(MString)
'
'						if(Mid(Mstring,Index,1)<>STRING_DLE) then
'							StringFiltered=StringFiltered+Mid(Mstring,Index,1)
'						else
'							index=Index+1
'							StringFiltered=StringFiltered+CHR(Asc(Mid(Mstring,Index,1)) AND  &H7F)
'						end if
'
'					NEXT
'
'
'					'giro il dato di peso
'					'FOR Index=4 to 1 step -1
'					FOR Index=3 to 4
'
'						ValByte=Asc(Mid(StringFiltered,2+Index,1))
'
'						CharReceived.OutputString=CharReceived.OutputString & Hex(Asc(Mid(StringFiltered,Index,1))) & "-"
'
'						Peso=(Peso * 256 ) +ValByte
'
'					NEXT
'
'					CharReceived.OutputString =CharReceived.OutputString & vbcrlf
'					CharReceived.OutputString= CharReceived.OutputString & " PESO X 1000 =" &  Peso & vbcrlf
'
'					CharReceived.OutputString= CharReceived.OutputString & " PESO        =" &  (Peso/1000) & vbcrlf
'
'					'CharReceived.OutputString=CharReceived.OutputString & StringFiltered & vbcrlf
'
'					'giro il dato di peso
'					FOR Index=1 to len(StringFiltered)
'
'						CharReceived.OutputString= CharReceived.OutputString + Hex(Asc(Mid(StringFiltered,Index,1))) & "-"
'
'					NEXT
'
'					CharReceived.OutputString= CharReceived.OutputString & vbcrlf
'
'
'
'							' CharReceived.OutputString=CharReceived.OutputString & " SINGOLO PESO " & CStr(pesi(Index)) &  " - " & CStr(Index) & vbcrlf
'
'					end if
'
'						'CharReceived.OutputString= CharReceived.OutputString & " SOMMA PESI " & CInt(PesoValido()) & " - - " &  CStr(SommaPesi()) & vbcrlf
''						CharReceived.OutputString= StringaPesiSingoli & "  SOMMA PESI =" &  CStr(SommaPesi()) & vbcrlf
'						' CharReceived.OutputString= " SOMMA PESI =" &  CStr(SommaPesi()) & vbcrlf
''				else
''					CharReceived.OutputString="ERROR" & vbcrlf
''				end if
'
'		Mstring=""
'  	' CharReceived.OutputString=CharReceived.OutputString & " ** AZZERA STRINGA "& Mstring  & vbcrlf
'
'		else
'			CharReceived.OutputString=""
'	  end if

CharReceived.OutputString=CharReceived.InputString

End Sub




