copy RICHTX32.OCX %WINDIR%\system32\RICHTX32.OCX
COPY msscript.ocx %WINDIR%\system32\msscript.ocx
COPY mswinsck.ocx %WINDIR%\system32\mswinsck.ocx

regsvr32.exe %WINDIR%\system32\RICHTX32.OCX
regsvr32.exe %WINDIR%\system32\msscript.ocx
regsvr32.exe %WINDIR%\system32\mswinsck.ocx
REM regsvr32.exe %WINDIR%\system32\RICHTX32.OCX
REM regsvr32.exe %WINDIR%\system32\msscript.ocx
REM regsvr32.exe %WINDIR%\system32\mswinsck.ocx

