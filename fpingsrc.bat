	@echo off
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat
	
	%_ini% %_tvini% [pingsrc] /remove
	
	for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
	call "%_lib_fdr%\nchars.bat" _cols / %_Columns%
	echo %_cols%
	
	echo checking and sort tv url(s) by ping time ...
	echo ping time ^| url
	for /f "tokens=2 delims==" %%i in ( 'set _tvsrc[' ) do (
		for /f "tokens=4 delims==" %%a in ( 'ping %%i ^| findstr "Average"' ) do ( 
			set _str=%%a
			set /a _pingtime=!_str:~0,-2!
			call :lCheck !_pingtime! %%i
		) )
	
	for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
	call "%_lib_fdr%\nchars.bat" _cols / %_Columns%
	echo %_cols%
	
	goto :eof
	endlocal
	
:lCheck _pingtime _src
	@echo off
	setlocal
	call cfg.bat
	
	set /a _pingtime=%~1
	set _src=%~2
	:lMakeDiff
		set _echoping=%_pingtime%                    ///////////
		echo %_echoping:~0,9% ^| %_src%
		set _index=000000000%_pingtime%
		set _index=%_index:~-10%
		for /f "delims=" %%a in ('%_ini% %_tvini% [pingsrc]') do ( %%a )
		if not defined _pingsrc[%_index%] (
			%_ini% %_tvini% [pingsrc] _pingsrc[%_index%]=%_src% ) else (
			set /a _pingtime+=1
			goto lMakeDiff )
	endlocal