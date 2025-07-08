
'********************************************************************************************
' Script che compone un buffer in forma Laumas
' prende il dato in invio di MAX 16 caratteri e lo mette in forma Laumas su due display (A,B)
'
'
' 9600,n,8,1
'
' Mettere come Tx Terminator Manual 00
' Attivare la Connessione
'	Attivare il Check Script
' Premere Start per iniziare il ciclo
' Scrivere nel Combo comandi la stringa che si vuole inviare
'
'
' NB: questo script deve essere rinominato o copiato in Script.vbs nella stessa directory di TestSer
'
'********************************************************************************************



'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

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
			Dim Index,where
			Dim MChar,MDisplayA,MDisplayB
			Dim Mstring,MResult

			MString=UCase(StringToSend.InputString)

			' Altero i punti e i caratteri non consentiti

			MResult=""


			' toglie i caratteri che non si possono visualizzare

			For Index=1 To Len(MString)

				MChar=Asc(Mid(Mstring,Index,1))

				If (MChar=44 Or MChar=46) Then

					If(Index=1) Then

						 MChar= 160

					Else

						 LastChar=Asc(Right(MResult,1)) And 128


						 where=Len(MResult)

						 If(LastChar) Then
						 		MChar= 160
						 Else
						 	MChar=Asc(Mid(MResult,where,1) ) Or 128
						 	MResult=Left(MResult,where-1)
						End If

						 'AppendLog.RichAppendText &h00,"PASSO 3" & vbcrlf

					End If

				Else

					'Conversione dei caratteri che il display non Ha con uno spazio
					If((MChar < &H22 And MChar > &H5A) Or (MChar = &H2F Or MChar = &H3A Or MChar = &H3B Or MChar = &H3B Or MChar = &H4B Or MChar = &H57 Or MChar = &H58)) Then
							MChar=&H20
					End if

				End If

'				AppendLog.RichAppendText &h00,Mid(MString,Index,1) & vbcrlf

				MResult=MResult & CHR(MChar)

			Next

			If(Len(MResult)<16) Then
				MResult=MResult +String(16-Len(mResult),32)
			End If

			MResult=Left(MResult,16)

			MDisplayA="A" + Left(MResult,8)  + "0"
			MDisplayB="B" + Right(MResult,8) + "0"


			ChecksumA=0
			ChecksumB=0
			For index=1 To Len(MDisplayA)
				ChecksumA=(ChecksumA XOR Asc(Mid(MDisplayA,Index,1)))
				ChecksumB=(ChecksumB XOR Asc(Mid(MDisplayB,Index,1)))
			Next

			Check=Hex(ChecksumA)
			if(len(Check)<2)  Then Check="0"+ Check

			MDisplayA=CHR(2)+ MDisplayA +CHR(3)+Check +CHR(4)

			Check=Hex(Checksumb)
			if(len(Check)<2)  Then Check="0"+ Check

			MDisplayB=CHR(2)+ MDisplayB +CHR(3)+Check +CHR(4)



			StringToSend.OutputString=MDisplayA + MDisplayB


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
		CharReceive.OutputString=CharReceive.InputString
End Sub

