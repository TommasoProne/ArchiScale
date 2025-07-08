
'********************************************************************************************
' Script invio dato ogni XX secondi
'
'
'********************************************************************************************


Dim ContaSecondi
Dim Max_Secondi
Dim Terminatore
Dim StringaInvio
Dim StringaBuona
Dim StringaSporco

Dim PrimoInvio

Dim Timer_Secondi

'----------------------------------------------------
'	called at init timer
'
'		TimerTask
'						Interval		ms 0=disabled
'						SendString(ByVal StringToSend As String)
'----------------------------------------------------
Public Sub InitTask()
	 
	 ' modificare Max_Secondi per alterare l'invio

	'StringaInvio = &h00 + &h47 + &hFD + &hBA + &hEF + &h00 + &h13
	
	StringaInvio = chr(&h00) + chr(&h47) + chr(&hFD) + chr(&hBA) + chr(&hEF)
	
	'StringaBuona=  chr(&h00) + chr(&h13)
	
	StringaSporco=  chr(&h00) + chr(&h47) + chr(&hFD) + chr(&hBA) + chr(&hEF) + chr(&h00) + chr(&h13)
	' StringaBuona=  chr(&h00) + chr(&h13) + chr(&h00) + chr(&h47) + chr(&hFD) + chr(&hBA) + chr(&hEF)
	
	StringaBuona=  chr(&h00) + chr(&h13) + chr(&h00) + chr(&h47) + chr(&hFD) + chr(&hBA) + chr(&hEF)
	
	Timer_Secondi=Timer
	
	PrimoInvio=0
	 
	 Max_Secondi=50						' conteggio secondi
	 TimerTask.Interval=120' base 1000 msec

	 Max_Secondi=1000 / TimerTask.Interval 						' conteggio secondi
	 
	 Terminatore= VbCrLf
	 
	 ContaSecondi=0

	FormMain.txtric.Text= FormMain.txtric.Text & "SCRIPT ABILITATO -" & vbcrlf
	FormMain.txtric.Text= FormMain.txtric.Text & "BASE millisecondi :" & TimerTask.Interval & vbcrlf
	FormMain.txtric.Text= FormMain.txtric.Text & "BASE CONTEGGIO    :" & Max_Secondi & vbcrlf
  FormMain.txtric.Text= FormMain.txtric.Text & "INVIO STRINGA OGNI:" & ((TimerTask.Interval * Max_Secondi) /1000) & " SECONDI" & vbcrlf	

	FormMain.txtric.Text= FormMain.txtric.Text & "INVIO -" & StringaInvio & vbcrlf

	 if(Not FormMain.Frame1.Enabled) then			 
		AppendLog.RichAppendText &hFF,"SERIALE CONNESSA" & vbcrlf
	 else
	 	FormMain.txtric.Text= FormMain.txtric.Text & "***************************************" & vbcrlf
	 	FormMain.txtric.Text= FormMain.txtric.Text & "CONNETTERE LA SERIALE" & vbcrlf
	 	FormMain.txtric.Text= FormMain.txtric.Text & "***************************************" & vbcrlf
	 end if	 

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

		if(abs(Timer_Secondi - Timer)>1) then


			select case PrimoInvio

					case 0,3,4,7,8:
								AppendLog.RichAppendText &h00,"TESTA " & Pos & vbcrlf
								TimerTask.SendString StringaInvio														
								PrimoInvio=PrimoInvio+1				
					
					case 1,2,5,6,9:
								AppendLog.RichAppendText &h00,"CODA " & Pos & vbcrlf
								TimerTask.SendString StringaSporco
								
								Timer_Secondi=Timer
								PrimoInvio=PrimoInvio+1	
								
					case else:
								AppendLog.RichAppendText &hFF,"BUONA " & Pos & vbcrlf
					
								TimerTask.SendString StringaBuona
								Timer_Secondi=Timer
								PrimoInvio=0
								ContaSecondi=0												
					
			end select
								
'			exit sub
			
			
'			if (PrimoInvio=0) then
'				TimerTask.SendString StringaInvio
'				PrimoInvio=1
'			else																	
'				TimerTask.SendString StringaBuona
				
'				if(PrimoInvio>1) then
'					PrimoInvio=0
'					ContaSecondi=0
	
					' TimerTask.SendString StringaSporco								
'				end if
				
'				PrimoInvio=PrimoInvio+1
					
'				Timer_Secondi=Timer
'			end if			
		
		end if
		
		
		

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




