
'********************************************************************************************
' Script la ricezione dati tipo display remoto LAUMAS
'
' 9600,n,8,1
'
' Mettere come Rx Terminator 04
' Attivare la Connessione
'	Attivare il Check Script
' Premere Start per iniziare il ciclo
'
'
'
' NB: questo script deve essere rinominato o copiato in Script.vbs nella stessa directory di TestSer
'
'********************************************************************************************


Dim Mstring
Dim STRING_ETX
Dim STRING_EOT
Dim STRING_STX

Dim DisplayA
Dim UsciteDisplayA
Dim DisplayB
Dim UsciteDisplayB




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
	 DisplayA=""
	 DisplayB=""
	 UsciteDisplayA=""
	 UsciteDisplayB=""

	 STRING_ETX=CHR(3)
	 STRING_STX=CHR(2)
	 STRING_EOT=CHR(4)

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
		Dim Pos,Index
		Dim Checksum
		Dim MDisplay
		Dim MChar
		Dim MOutput,StatoOut
		Dim RepatCicle


		RepatCicle=True
		Mstring=Mstring+CharReceived.InputString


	While(RepatCicle)

	RepatCicle=False

		Pos=InStr(Mstring,STRING_EOT)


		If(Pos) then

			If(Pos=15) Then

				' AppendLog.RichAppendText &h00,"RICEVUTO EOT " & Pos & vbcrlf

				Pos=InStr(Mstring,STRING_STX)

					If(Pos=1) then
						' STX <A> <XXXXXXXX> <Y> ETX <SS> EOT
						'1AXXXXXXXXYESST
						' AppendLog.RichAppendText &h00,"RICEVUTO STX " & Pos & vbcrlf

						'Calcola Checksum
						Checksum=0

						For index=2 To 11
							' AppendLog.RichAppendText &HFF00FF,"CHECKSUM -- " & Mid(Mstring,Index,1) &" " &   index & vbcrlf
							Checksum=(Checksum XOR Asc(Mid(Mstring,Index,1)))
						Next

						' AppendLog.RichAppendText &HFF00FF,"CHECKSUM" & HEX(Checksum) & " -- " & Mid(Mstring,13,2) & vbcrlf

						If (Checksum=CInt("&H" + Mid(Mstring,13,2) )) Then
								AppendLog.RichAppendText &HFF00FF,"CHECKSUM OK" & vbcrlf

								'Display A o B

								MDisplay=""

								For Index=3 To 10
									MChar=Asc(Mid(Mstring,Index,1))

									If(MChar And 128) Then

										If(MChar=128) Then
											MDisplay=MDisplay+"."
										Else
											MDisplay=MDisplay+Chr(MChar And &H7F)
											MDisplay=MDisplay+"."
										End If

								 Else
										MDisplay=MDisplay+Mid(Mstring,Index,1)
								 End If


								Next


								StatoOut=CInt(Mid(Mstring,11,1))

								If(StatoOut And 1) Then
										MOutput=" OUT1=1 "
								Else
										MOutput=" OUT1=0 "
								End If

								If(StatoOut And 2) Then
										MOutput=MOutput+" OUT2=1 "
								Else
										MOutput=MOutput+" OUT2=0 "
								End If

								If(StatoOut And 4) Then
										MOutput=MOutput+" OUT3=1 "
								Else
										MOutput=MOutput+" OUT3=0 "
								End If


								If(Mid(Mstring,2,1)="A") Then
									DisplayA=String(16-Len(MDisplay)," ") + MDisplay
									UsciteDisplayA=MOutput
								Else
									DisplayB=String(16-Len(MDisplay)," ") + MDisplay
									UsciteDisplayB=MOutput
								End if

								' AppendLog.RichAppendText &h00,"DISPLAY A--|" & DisplayA & "|  " & UsciteDisplayA & vbcrlf & "DISPLAY B--|" & DisplayB & "|  " & UsciteDisplayB & vbcrlf
								FormMain.txtric.visible=false
								FormMain.txtric.Text=""
								AppendLog.RichAppendText &h00,"display A--|"
								FormMain.lblfontsize="24"
								AppendLog.RichAppendText &hFF, DisplayA
								FormMain.lblfontsize="8"
								AppendLog.RichAppendText &h00, "| " & UsciteDisplayA & vbcrlf

								AppendLog.RichAppendText &h00,"display B--|"
								FormMain.lblfontsize="24"
								AppendLog.RichAppendText &hFF, DisplayB
								FormMain.lblfontsize="8"
								AppendLog.RichAppendText &h00, "| " & UsciteDisplayB & vbcrlf


								AppendLog.RichAppendText &h00, vbcrlf & FormMain.CboSend.Text & vbcrlf


								FormMain.txtric.visible=true


								Mstring=Mid(Mstring,16)
								If(Mstring<>"") Then
									RepatCicle=True
								End If

						Else
								AppendLog.RichAppendText &hFF,"ERRORE CHECKSUM" & vbcrlf
						End If

				Else
					CharReceived.OutputString="ERROR" & vbcrlf
				End If

		End If

		If(Not RepatCicle) Then
			FormMain.txtparser.text=Mstring
			Mstring=""
		End if

		Else
			FormMain.txtparser.text=Mstring
			CharReceived.OutputString=""
	  End If

	Wend


End Sub




