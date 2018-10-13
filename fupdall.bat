@echo off
setlocal & cls
call cfg.bat

set _to_update_lst[1]=thvl1
set _to_update_lst[2]=vtv1
set _to_update_lst[3]=vtv3
set _to_update_lst[4]=htv2
set _to_update_lst[5]=htv7
set _to_update_lst[6]=htv9
set _to_update_lst[7]=qpvn

for /f "tokens=2 delims==" %%x in ( 'set _to_update_lst[ ' ) do call ftvuplnk.bat %%x

endlocal
goto :eof
