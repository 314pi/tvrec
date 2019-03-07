@echo off
setlocal & cls
call cfg.bat

rem set _to_update_lst[1]=thvl1
set _to_update_lst[2]=vtv1
set _to_update_lst[3]=vtv3
rem set _to_update_lst[4]=htv2
rem set _to_update_lst[5]=htv7
rem set _to_update_lst[6]=htv9
rem set _to_update_lst[7]=qpvn

for /f "tokens=2 delims==" %%x in ( 'set _to_update_lst[ ' ) do call fupdlnk.bat %%x

endlocal
goto :eof
