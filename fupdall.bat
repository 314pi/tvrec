@echo off
setlocal enableextensions enabledelayedexpansion
call cfg.bat
cls

set _channel_lst[0]=thvl1
set _channel_lst[1]=vtv1
set _channel_lst[2]=vtv3
set _channel_lst[3]=htv2
set _channel_lst[4]=htv9
set _channel_lst[5]=htv7
rem set _channel_lst[6]=qpvn

set /a "_x=0"
:lArrayLength
	if defined _channel_lst[%_x%] (
	 set /a "_x+=1"
	 goto lArrayLength )
set /a _len=%_x%-1
for /l %%n in (0,1,%_len%) do ( call ftvuplnk.bat !_channel_lst[%%n]! )

endlocal
goto :eof