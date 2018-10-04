	@echo off & cls
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat

	set /a _lnk_n=1
	set /a _found=0
	set /a _src_n=1
	set "_channel=%1"
	if [%1]==[] set "_channel=test"
	title Update TV link [ %_channel% ]
	
	if not exist "%_tvini%" "%_wget%" "%_tvini_url%"
	rem empty value of 4/5 ( except 5 th) link keys in the channel
	for /l %%i in (1,1,4) do %_ini% %_tvini% [%_channel%] _lnk%%i==
	
:lUpdateLink
	if %_src_n% geq 11 ( goto lDone )

	if exist "%_tmp_fdr%\%_channel%.*" del "%_tmp_fdr%\%_channel%.*"

	for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%] _src%_src_n%' ) do %%a
	call set _src="%%_src%_src_n%%%"
	if not %_src%=="" set _src=%_src: =%
	if %_src%=="" (
		set /a _src_n+=1
		goto lUpdateLink
	)
	echo ///////////////////////////////////////////////////////////////////////////////
	echo Source [%_src_n%]: %_src%
	call ftvm3u8.bat %_channel% "%_src%"
	
	set /a _count=1
	for /f %%i in (%_tmp_fdr%\%_channel%) do (
		set _clink=%%i
		set _clink=!_clink:"=!
		title Update TV link [ !_channel! ] [ Source no. : !_src_n! ] [ link no. : !_lnk_n! ]
		echo ===============================================================================
		echo [!_lnk_n!] Source [!_src_n!] link No. !_count! : & echo !_clink!
		!_streamlink! -Q "!_clink!" | findstr /i /C:"Available streams" && (
			set /a _already_=0
			for /l %%x in (1,1,!_lnk_n!) do (
				for /f "delims=" %%a in ('!_ini! !_tvini! [!_channel!] _lnk%%x' ) do %%a
				set _already_lnk=!_lnk%%x!
				echo "!_already_lnk!" | findstr /c:"!_clink!">NUL && (
				set /a _already_=1
				echo [ ////////// already added ////////// ] )
			)
			if !_already_! equ 0 (
				!_ini! !_tvini! [!_channel!] _lnk!_lnk_n!=!_clink!
				if !_lnk_n! leq 1 echo !_streamlink! "--player=!_vlc!" "!_clink!" worst>"!_logs_fdr!\!_channel!.bat"
				set /a _lnk_n+=1 ) ) || echo [ is not a stream link for record or stream ]
		if !_lnk_n! geq 5 goto lDone
	)
	if %_lnk_n% leq 3 (
		set /a _src_n+=1
		goto lUpdateLink )

:lDone
	set /a _found=%_lnk_n%-1
	echo ///////////////////////////////////////////////////////////////////////////////
	echo //                                                                           //
	echo // [ %_channel% ] [ atleast %_found% link(s) found ]
	echo //                                                                           //
	echo ///////////////////////////////////////////////////////////////////////////////
	rem upload ini file to ftp server
	if exist ath.ftp ftp -s:ath.ftp
	
	endlocal
	goto :eof