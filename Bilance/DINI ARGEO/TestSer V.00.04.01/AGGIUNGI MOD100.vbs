
Dim Mstring

' stringa standard
' ST,  250,00,kg,ST,   00,00,kg,ST,   00,00,kg,ST,   00,00,kg



Dim Risposta

Dim MyShell


Public Sub WaitMs(ms)
	Dim mtimeinit
	Dim timediff
	
	mtimeinit = Cdbl(Timer())

	do
	  timediff = Cdbl(Timer()) - mtimeinit
	loop while timediff < Cdbl(ms)
	
End Sub
'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()

    
		FormMain.Check2.Value = 1
		FormMain.Combo3.ListIndex = 1   ' 1 carattere di terminazione

		FormMain.Option3(2)= 1          ' Nessun Terminatore
		FormMain.Option4(3)= 1          ' Terminatore a caratteri
		FormMain.Check1.Value = 0       ' Nessuna Attesa risposta


		' TimerTask.Interval=250
		TimerTask.Interval=10

		'TERMINATORE SU CRLF

		
		FormMain.cbosend.text = "M/THIS IS MY SCROLLING MESSAGE/"

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
    Dim mpacket
    
    ' AppendLog.RichAppendText &hFF,"STRINGA IN INGRESSO " &  StringToSend.InputString  &vbcrlf

    
    ' AppendLog.RichAppendText &hFF,"STRINGA CONV " &  FormatNumber(12,0) & vbcrlf
    
    ' AppendLog.RichAppendText &hFF,"PASSATO" &  StringToSend.InputString  &vbcrlf

		' esempio messaggio da inviare (mmmm) ENQ STX mmmmm CC ETX
		' mmmm=    M/THIS IS MY SCROLLING MESSAGE/
    
    ' mpacket="5/1/1000.00/PAYMNT DESCR/1.000000/CREDIT/"
    ' "5/1/1000.00/PAYMNT DESCR/1.000000/CREDIT/"



'    TimerTask.SendString Chr(5)
'    WaitMs(1)
    

'    mpacket =  Chr(2)    ' STX
'    mpacket = mpacket + StringToSend.InputString + LTrim(FormatNumber(CheckSumMod100(StringToSend.InputString),0))
'    mpacket = mpacket + Chr(3)    ' ETX
    
'    TimerTask.SendString mpacket
    
' 		WaitMs(1)

    
'    TimerTask.SendString Chr(6)

'		WaitMs(1)
		
		'' Se e' un comando lo lascio passare altrimenti gli accodo i caratteri

		if(len(StringToSend.InputString)>1) then

				' mpacket = Chr(24)    ' CAN
		
    		' mpacket = mpacket + Chr(5)    ' ENQ
    		'mpacket = mpacket + Chr(2)    ' STX
    		mpacket =  Chr(2)    ' STX
    
    		mpacket = mpacket + StringToSend.InputString + LTrim(FormatNumber(CheckSumMod100(StringToSend.InputString),0))
    		mpacket = mpacket + Chr(3)    ' ETX
    
    		' mpacket = mpacket + Chr(6)    ' ACK
    
    		StringToSend.InputString   = mpacket

		else
		
		  mpacket = StringToSend.InputString
		
		
		end if
		
		StringToSend.OutputString = mpacket

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
			CharReceived.OutputString=CharReceived.InputString
End Sub


'----------------------------------------------------
'
'----------------------------------------------------
Public function CheckSumMod100(Frame)
	Dim Ret
	Dim SumValue
	Dim i

	SumValue = 0

	NumBytes = len(Frame)

	For i = 1 To NumBytes
			SumValue = (SumValue + Asc(mid(Frame,i,1))) And &HFF
	Next

	Ret = SumValue Mod 100

	CheckSumMod100=Ret
end function
