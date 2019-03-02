@echo off & cls
setlocal enableextensions enabledelayedexpansion
call cfg.bat
call :lFindM3U8 "vtv1" "http://api.tivi12h.net/next.php?id=vtv3&token=OiCtCliyJefLtSSXfz5lUg&e=1551535429"

endlocal
goto :eof

:lFindM3U8 _ofile _url
	@echo off
	setlocal enableextensions enabledelayedexpansion

	call cfg.bat
	set _ofile=%~1
	set _url=%2
	echo %_ofile% %_url%
	"%_wget%" -T 30 -qO- %_url%
	endlocal & exit /b