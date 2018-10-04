	@echo off & cls
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat
	
	set _dur=03:00:00
	set _qual=360p,480p,1200k,540p,720p,best
	
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
	echo ///////////////////////////////////////////////////////////////////////////////
	for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%] _liveurl') do %%a
	for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%] _ccfg') do %%a
	if not "%_ccfg%"=="" set "_ccfg=%_ccfg: =%"
	
	call :lCfgOrder _order %_ccfg%
	call :lSelectChannelCfg _scfg %_ccfg% %_order%
	call :lSplitChannelCfg _start _end _ext %_scfg%
	call :lgetTime _nows
	call :lTimeSubtract _dur %_nows% %_end%
	if "%_dur%" geq "03:00:00" set _dur=03:00:00
	
	if [%2]==[] (
		set /a _rec_mod=1
		set /a _liv_mod=0
		call :lStrLen _ext_len %_ext%
		if !_ext_len! geq 1 set /a _rec_mod=%_ext:~0,1%
		if !_ext_len! geq 2 set /a _liv_mod=%_ext:~1,1%
		set /a _mod=!_liv_mod!*2 + !_rec_mod!
	)
	if %_mod% leq 1 set /a _mod=1
	if %_mod% geq 3 set /a _mod=3
	
	set /a _lnk_n=1
:lStart
	if %_lnk_n% geq 6 goto lUpdateUrl
	for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%] _lnk%_lnk_n%') do %%a
	call set "_rec_url=%%_lnk%_lnk_n%%%"
	if not "%_rec_url%"=="" (
		set "_rec_url=%_rec_url: =%"
		if "%_rec_url%"=="" (
			set /a "_lnk_n+=1" & goto lStart
		)
	) else ( set /a "_lnk_n+=1" & goto lStart )
	
	set _rec_name=%_channel%_%date:~0,2%%date:~3,2%_%time:~0,2%%time:~3,2%%time:~6,2%.mp4
	set _rec_name=%_rec_name: =%
	set _rec_opt=--hls-segment-threads 10 --hls-duration %_dur%
	set _ffmpeg_opt=-acodec libmp3lame -ar 44100 -b:a 96k -pix_fmt yuv420p -profile:v baseline -bufsize 6000k -vb 400k -maxrate 1000k -deinterlace -vcodec libx264 -preset veryfast -g 30 -r 25 -crf 30 -f flv

	if not "x_%1"=="x_auto" (
		for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%] _alu') do %%a
		set _liveurl=%_alu%
	)
	
	if %_mod% equ 1 (
		title Record [%_channel%] - URL[%_lnk_n%] - [start %time:~0,-6% ] + [ %_dur:~0,-3% ] = [stop %_end%] - [ param: %1 %2 %3 ]
		%_streamlink% %_rec_opt% "%_rec_url%" "%_qual%" --stdout | "%_ffmpeg%" -i pipe:0 -s 640x360 %_ffmpeg_opt% "%_video_fdr%\%_rec_name%" )
	
	if %_mod% equ 2 (
		title Live [%_channel%] - URL[%_lnk_n%] - [start %time:~0,-6% ] + [ %_dur:~0,-3% ] = [stop %_end%] - [ param: %1 %2 %3 ]
		%_streamlink% %_rec_opt% "%_rec_url%" "%_qual%" --stdout | "%_ffmpeg%" -i pipe:0 -s 640x360 %_ffmpeg_opt% "%_liveurl%" )
	
	if %_mod% equ 3 (
		title Record+Live [%_channel%] - URL[%_lnk_n%] - [start %time:~0,-6% ] + [ %_dur:~0,-3% ] = [stop %_end%] - [ param: %1 %2 %3 ]
		%_streamlink% %_rec_opt% "%_rec_url%" "%_qual%" --stdout | "%_ffmpeg%" -i pipe:0 %_ffmpeg_opt% - | "%_ffmpeg%" -f flv -i - -c copy -f flv "%_liveurl%" -s 640x360 -f flv "%_video_fdr%\%_rec_name%" )
	
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

rem call :lTimeSubtract sub 10:10:10 09:09:09
:lTimeSubtract sub time1 time2
	setlocal
	if "%~3"=="" ( set "_time2=%time%" ) else ( set "_time2=%~3" )
	set /a h=100%_time2:~0,2% %% 100
	if %h% lss 10 set h=0%h%
	set /a _end=(1%h%-100)*3600 + (1%_time2:~3,2%-100)*60 + (1%_time2:~6,2%-100)
	set "_time1=%~2"
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
	endlocal & if not "%~1"=="" set "%~1=%_hr%:%_min%:%_sec%" & exit /b
	
:lSelectChannelCfg _scfg _ccfg _order
	@echo off
	setlocal
	set "_ccfg=%~2"
	for /f "tokens=%3 delims=va" %%a in ("%_ccfg%") do set _sel_cfg=%%a
	endlocal & if not "%~1"=="" set "%~1=%_sel_cfg%" & exit /b
	
:lSplitChannelCfg _start _end _ext _scfg
	echo off
	setlocal
	set "_scfg=%~4"
	for /f "tokens=1-3 delims=x" %%a in ("%_scfg%") do (
		set _start=%%a
		set _end=%%b
		set _ext=%%c 
	)
	endlocal & set "%~1=%_start%" & set "%~2=%_end%" & set "%~3=%_ext%" & exit /b

:lCfgOrder _order _ccfg
	@echo off
	setlocal enableextensions enabledelayedexpansion
	set "_ccfg=%~2"
	set /a _order=0
	for /l %%i in (1,1,10) do (
		call :lSelectChannelCfg _scfg !_ccfg! %%i
		call :lSplitChannelCfg _start _end _ext !_scfg!
		call :lgetTime _now
		if !_now! lss !_end! (
			set /a _order=%%i
			goto lFoundOrder )
	)
	:lFoundOrder
	echo [ %_order% : %_start% - %_end% - %_ext% ]
	endlocal & if not "%~1"=="" set /a "%~1=%_order%" & exit /b
	
:lAutoSelectChannel _channel
	@echo off
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat
	set _channel=test
	for /l %%n in (0,1,%_chan_n%) do (
		for /f "delims=" %%a in ('%_ini% %_tvini% [!_chan_lst[%%n]!] _acfg') do %%a
		if not "!_acfg!"=="" set "_acfg=!_acfg: =!"
		set /a _count=0
		call :lCountParts _count !_acfg!
		set _scfg=
		for /l %%i in (1,1,!_count!) do (
			call :lSelectChannelCfg _scfg !_acfg! %%i
			call :lSplitChannelCfg _start _end _ext !_scfg!
			call :lgetTime _now
			if !_now! gtr !_start! (
				if !_now! lss !_end! (
					set _channel=!_chan_lst[%%n]!
					goto lFoundChannel ) )
		)
	)
	:lFoundChannel
	echo [ Auto select channel : %_channel% ]
	timeout /t 3
	endlocal & set "%~1=%_channel%" & exit /b
	
:lCountParts _count _str
	@echo off
	setlocal enableextensions enabledelayedexpansion
	set /a _count=0
	set _str=%~2
	:lPlus
		set "_old_str=%_str%"
		set "_str=%_str:*va=%"
		set /a _count+=1
		if not "%_str%" == "%_old_str%" goto lPlus
	endlocal & if not "%~1"=="" set /a "%~1=%_count%" & exit /b
