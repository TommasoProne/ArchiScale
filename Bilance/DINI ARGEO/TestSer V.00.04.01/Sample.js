/*******************************************************************************
	Filename		: sample.js
'*******************************************************************************/


var BASETEMPO=1000;		// un secondo

var cosamando=0;
var sendstring=0x00 + 0x47 + 0xFD + 0xBA + 0xEF + 0x00 + 0x13

//'----------------------------------------------------
//'	called at init timer
//'
//'		TimerTask
//'						Interval		ms 0=disabled
//'						SendString(ByVal StringToSend As String)
//'----------------------------------------------------
function InitTask()
{
		TimerTask.Interval=BASETEMPO;		// 1 secondo

		FormMain.txtric.Text+= "SCIPRT ABILITATO - (1 SECONDO)\0xd\0xa";
		
		// FormMain.txtric.Text=FormMain.txtric.Text + "ASSICURARSI DI AVER IMPOSTATO NEL COMMAND IL COMANDO GIUSTO";
		// TERMINATORE SU CRLF

}

//'----------------------------------------------------
//'	called at timer
//'
//'			TimerTask.Interval
//'			TimerTask.SendString(ByVal StringToSend As String)
//'----------------------------------------------------
function Task()
{

	// TimerTask.SendString("RALL");
	// {00}{47}{FD}{BA}{EF}{00}{13}
	
	if(cosamando)
	{
		TimerTask.SendString(sendstring);
		cosamando=0;
	}
	else
	{
		TimerTask.SendString(sendstring);		
	cosamando=1;
	}
	
	
	
}

//'			StringReceived
//' 		StringToSend
//'			CharReceive
//'			TimerTask
//'
//'----------------------------------------------------
//'	Called before send string
//'
//' Object StringToSend
//'								InputString			passed from TestSer
//'								OutputString		returned at TestSer
//'----------------------------------------------------
function SendString()
{
		StringToSend.OutputString=StringToSend.InputString;
}


//'----------------------------------------------------
//'	Called on received string
//'
//' Object StringReceived
//'								InputString			passed from TestSer
//'								OutputString		returned at TestSer
// '----------------------------------------------------
function ReceiveString()
{
		StringReceived.OutputString=StringReceived.InputString;
}

//'----------------------------------------------------
//'	Called on received char
//'
//' Object CharReceive
//'								InputString			passed from TestSer
//'								OutputString		returned at TestSer
//'----------------------------------------------------
function ReceiveChar()
{
		CharReceived.OutputString=CharReceived.inputString;
}

