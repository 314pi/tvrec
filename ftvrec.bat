	@echo off & cls
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat
	
	set _dur=03:00:00
	
	set "_channel=%1"
	set "_mod=%2"
	if [%1]==[] set "_channel=test"
	title Record and/or Live TV channel [ %_channel% ]

	if not "x_%1"=="x_auto" goto lManualChannel
	rem else _channel = auto ( Auto select channel )
:lAutoChannel
	call :lAutoSelectChannel _channel
	if "%_channel%" == "test" (
		cls & echo [ Record and/or Live TV : Nothing to do now ... ]
		title [ Record and/or Live TV : Nothing to do now ... ]
		timeout /t 120
		goto lAutoChannel )
:lManualChannel
	if %_upd_lnk_fst% equ 0 goto lNoUpdateUrl
	set /a _dow_count=0
:lUpdateUrl
	set /a _dow_count+=1
	echo [ downloading %_tvini% from ftp server ... ]
	"%_wget%" -N "%_tvini_url%"
	if %_dow_count% geq 3 (
		call ftvuplnk.bat %_channel%
		set /a _dow_count=0 )

:lNoUpdateUrl
	for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
	call "%_lib_fdr%\nchars.bat" _cols / %_Columns%
	echo %_cols%
	if "x_%1"=="x_auto" (
		for /f "delims=" %%a in ('%_ini% %_myini% [auto%_channel%]') do %%a
		set _cfg=!_acfg!
		set _out_url=!_alu!
	) else (
		for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%]') do %%a
		set _cfg=!_ccfg!
		set _out_url=!_liveurl! )
	if not "%_cfg%"=="" set "_cfg=%_cfg: =%"
	call :lCfgOrder %_cfg% _order
	call :lSelectChannelCfg %_cfg% %_order% _scfg
	call :lSplitChannelCfg %_scfg% _array
	set _start=%_array[1]%
	set _end=%_array[2]%
	set _ext=%_array[3]%
	call :lgetTime _nows
	call :lTimeSubtract %_nows% %_end% _dur
	if "%_dur%" geq "03:00:00" set _dur=03:00:00
	
	if [%2]==[] (
		set /a _rec_mod=1
		set /a _liv_mod=0
		call :lStrLen _ext_len %_ext%
		if !_ext_len! geq 1 set /a _rec_mod=%_ext:~0,1%
		if !_ext_len! geq 2 set /a _liv_mod=%_ext:~1,1%
		set /a _mod=!_liv_mod!*2 + !_rec_mod!
	)
	if %_mod% lss 1 goto :eof
	if %_mod% gtr 3 set /a _mod=3
	
	for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%]') do %%a
	call :lCountChannelLnk %_channel% _max_lnk_n
	set /a _max_lnk_n+=1
	
	set /a _lnk_n=1
:lStart
	if %_lnk_n% geq %_max_lnk_n% goto lUpdateUrl
	call set "_in_url=%%_lnk[%_lnk_n%]%%"
	if not "%_in_url%"=="" (
		set "_in_url=%_in_url: =%"
		if "%_in_url%"=="" (
			set /a "_lnk_n+=1" & goto lStart
		)
	) else ( set /a "_lnk_n+=1" & goto lStart )
	
	set _rec_name=%_channel%_%date:~0,2%%date:~3,2%_%time:~0,2%%time:~3,2%%time:~6,2%.mp4
	set _rec_name=%_rec_name: =%
	set _rec_opt=--hls-segment-threads 10 --hls-duration %_dur%
	rem set _ffmpeg_opt= ( cfg.bat )
	
	if %_mod% equ 1 (
		title Record [%_channel%] - URL[%_lnk_n%] - [start %time:~0,-6% ] + [ %_dur:~0,-3% ] = [stop %_end%] - [ param: %1 %2 %3 ]
		%_streamlink% %_rec_opt% "%_in_url%" "%_qual%" --stdout | "%_ffmpeg%" -i pipe:0 %_scale% %_ffmpeg_opt% "%_video_fdr%\%_rec_name%" )
	
	if %_mod% equ 2 (
		title Live [%_channel%] - URL[%_lnk_n%] - [start %time:~0,-6% ] + [ %_dur:~0,-3% ] = [stop %_end%] - [ param: %1 %2 %3 ]
		%_streamlink% %_rec_opt% "%_in_url%" "%_qual%" --stdout | "%_ffmpeg%" -i pipe:0 %_scale% %_ffmpeg_opt% "%_out_url%" )
	
	if %_mod% equ 3 (
		title Record+Live [%_channel%] - URL[%_lnk_n%] - [start %time:~0,-6% ] + [ %_dur:~0,-3% ] = [stop %_end%] - [ param: %1 %2 %3 ]
		%_streamlink% %_rec_opt% "%_in_url%" "%_qual%" --stdout | "%_ffmpeg%" -i pipe:0 %_ffmpeg_opt% - | "%_ffmpeg%" -f flv -i - -c copy -f flv "%_out_url%" %_scale% -f flv "%_video_fdr%\%_rec_name%" )
	
	call :lgetTime _nowe
	if "%_nowe%" lss "%_end%" (
		set /a "_lnk_n+=1"
		goto lStart )
	goto :eof
rem ///////////////////////////////////////////////////////////////////////////////
rem lgetTime
rem This routine returns the current (or passed as argument) time
rem in the form hh:mm:ss,cc in 24h format, with two digits in each
rem of the segments, 0 prefixed where needed.
:lgetTime returnVar [time]
	setlocal enableextensions disabledelayedexpansion
	rem Retrieve parameters if present. Else take current time
	if "%~2"=="" ( set "t=%time%" ) else ( set "t=%~2" )
	rem Test if time contains "correct" (usual) data. Else try something else
	echo(%t%|findstr /i /r /x /c:"[0-9:,.apm -]*" >nul || (
		set "t="
		for /f "tokens=2" %%a in ('2^>nul robocopy "|" . /njh') do (
			if not defined t set "t=%%a,00"
		)
		rem If we do not have a valid time string, leave
		if not defined t exit /b
	)
	rem Check if 24h time adjust is needed
	if not "%t:pm=%"=="%t%" (set "p=12" ) else (set "p=0")
	rem Separate the elements of the time string
	for /f "tokens=1-5 delims=:.,-PpAaMm " %%a in ("%t%") do (
		set "h=%%a" & set "m=00%%b" & set "s=00%%c" & set "c=00%%d"
	)
	rem Adjust the hour part of the time string
	set /a "h=100%h%+%p%"
	rem Clean up and return the new time string
	endlocal & if not "%~1"=="" set "%~1=%h:~-2%:%m:~-2%:%s:~-2%" & exit /b
	
:lStrLen len str
	setlocal enabledelayedexpansion
	set "token=#%~2" & set "len=0"
	for /L %%A in (12,-1,0) do (
		set/A "len|=1<<%%A"
		for %%B in (!len!) do if "!token:~%%B,1!"=="" set/A "len&=~1<<%%A"
	)
	endlocal & if not "%~1"=="" set %~1=%len% & exit /b

rem call :lTimeSubtract 10:10:10 09:09:09 _sub
:lTimeSubtract _time1 _time2 _sub
	setlocal
	set "_time2=%~2"
	set /a h=100%_time2:~0,2% %% 100
	if %h% lss 10 set h=0%h%
	set /a _end=(1%h%-100)*3600 + (1%_time2:~3,2%-100)*60 + (1%_time2:~6,2%-100)
	set "_time1=%~1"
	set /a h=100%_time1:~0,2% %% 100
	if %h% lss 10 set h=0%h%
	set /a _start=(1%h%-100)*3600 + (1%_time1:~3,2%-100)*60 + (1%_time1:~6,2%-100)
	if %_start% geq %_end% (
		set /a num=%_start% - %_end% ) else (
		set /a num=%_end% - %_start% )
	set /a _hr=%num% / 3600
	set /a _min=( %num% - %_hr%*3600 ) / 60
	set /a _sec=( %num% - %_hr%*3600 - %_min%*60 )
	if %_hr% geq 24 set /a _hr=%_hr%-24
	if %_hr% lss 10 set _hr=0%_hr%
	if %_min% lss 10 set _min=0%_min%
	if %_sec% lss 10 set _sec=0%_sec%
	endlocal & if not "%~3"=="" set "%~3=%_hr%:%_min%:%_sec%" & exit /b
	
:lSelectChannelCfg _ccfg _order _scfg
	@echo off
	setlocal
	set "_ccfg=%~1"
	for /f "tokens=%2 delims=va" %%a in ("%_ccfg%") do set _sel_cfg=%%a
	endlocal & if not "%~3"=="" set "%~3=%_sel_cfg%" & exit /b
	
:lSplitChannelCfg _scfg _array
	@echo off
	setlocal
	set "_scfg=%~1"
	for /f "tokens=1-4 delims=x" %%a in ("%_scfg%") do (
		set _start=%%a
		set _end=%%b
		set _ext=%%c
		set _sched=%%d
	)
	endlocal & set "%~2[1]=%_start%" & set "%~2[2]=%_end%" & set "%~2[3]=%_ext%" & set "%~2[4]=%_sched%" & exit /b

:lCfgOrder _cfg _order
	@echo off
	setlocal enableextensions enabledelayedexpansion
	set "_cfg=%~1"
	set /a _order=0
	for /l %%i in (1,1,10) do (
		call :lSelectChannelCfg !_cfg! %%i _scfg
		call :lSplitChannelCfg !_scfg! _array
		set _start=!_array[1]!
		set _end=!_array[2]!
		set _ext=!_array[3]!
		call :lgetTime _now
		if !_now! lss !_end! (
			set /a _order=%%i
			goto lFoundOrder )
	)
	:lFoundOrder
	echo [ %_order% : %_start% - %_end% - %_ext% ]
	endlocal & if not "%~2"=="" set /a "%~2=%_order%" & exit /b
	
:lAutoSelectChannel _channel
	@echo off
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat
	set _channel=test
	for /f "tokens=2 delims==" %%x in ( 'set _autochannel[' ) do (
		for /f "delims=" %%a in ('%_ini% %_myini% [auto%%x] _acfg') do %%a
		if not "!_acfg!"=="" set "_acfg=!_acfg: =!"
		set /a _count=0
		call :lCountParts !_acfg! _count
		set _scfg=
		for /l %%i in (1,1,!_count!) do (
			call :lSelectChannelCfg !_acfg! %%i _scfg
			call :lSplitChannelCfg !_scfg! _array
			set _start=!_array[1]!
			set _end=!_array[2]!
			set _sched=!_array[4]!
			echo "!_sched!" | findstr "%dayofweek%" > NUL && (
				call :lgetTime _now
				if !_now! gtr !_start! (
					if !_now! lss !_end! (
						set _channel=%%x
						goto lFoundChannel ) ) )
		) )
	:lFoundChannel
	echo [ Auto select channel : %_channel% ]
	timeout /t 3
	endlocal & set "%~1=%_channel%" & exit /b

:lCountParts _str _count
	@echo off
	setlocal enableextensions enabledelayedexpansion
	set /a _count=0
	set _str=%~1
	:lPlus
		set "_old_str=%_str%"
		set "_str=%_str:*va=%"
		set /a _count+=1
		if not "%_str%" == "%_old_str%" goto lPlus
	endlocal & if not "%~2"=="" set /a "%~2=%_count%" & exit /b

:lBestPing _best_url
	@echo off
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat

	set /a _min=9999
	set _best_url=
	echo ///////////////////////////////////////////////////////////////////////////////
	rem echo website %TAB% ^| %TAB% ping %TAB% ^| %TAB% min ping
	for /f "tokens=2 delims==" %%i in ( 'set _tvsrc[' ) do (
		for /f "tokens=4 delims==" %%a in ( 'ping %%i ^| findstr "Average"' ) do (
			set _str=%%a
			set /a _cmin=!_str:~0,-2!
			echo %%i !_cmin! !_min!
			if !_cmin! lss !_min! (
				set /a _min=!_cmin!
				set _best_url=%%i )
		) )
	echo %_best_url%
	echo ///////////////////////////////////////////////////////////////////////////////
	timeout /t 3 > NUL
	endlocal & if not "%~1"=="" set "%~1=%_best_url%" & exit /b

:lCountChannelLnk _in_channel _o_count
	@echo off
	setlocal
	call cfg.bat
	
	set /a _o_count=0
	set _in_channel=%~1
	
	for /f "delims=" %%a in ('%_ini% %_tvini% [%_in_channel%]') do ( %%a )
	for /f "tokens=2 delims==" %%x in ( 'set _lnk[' ) do set /a _o_count+=1
	
	endlocal & if not "%~2"=="" set "%~2=%_o_count%" & exit /b
