	@echo off & cls
	setlocal enableextensions enabledelayedexpansion
	call cfg.bat

	set /a _lnk_n=1
	set /a _found=0
	set /a _src_n=1
	set /a _count=1
	set "_channel=%1"
	if [%1]==[] set "_channel=test"
	title update tv link [ %_channel% ]
	
	if not exist "%_tvini%" "%_wget%" "%_tvini_url%"
	rem empty value of 4/5 ( except 5 th) link keys in the channel
	for /l %%i in (1,1,4) do %_ini% %_tvini% [%_channel%] _lnk[%%i]==
	
	if exist "%_tmp_fdr%\%_channel%.*" del "%_tmp_fdr%\%_channel%.*"
	call fpingsrc.bat
	for /f "delims=" %%a in ('%_ini% %_tvini% [pingsrc]') do ( %%a )
	
	for /f "tokens=2 delims==" %%x in ( 'set _pingsrc[' ) do (
		for /f "delims=" %%a in ('%_ini% %_tvini% [%%x] _%_channel%' ) do %%a
		call set _src="%%_%_channel%%%"
		for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
		call "%_lib_fdr%\nchars.bat" _cols / !_Columns!
		echo !_cols!
		echo source [ !_src_n! : !_src! ]
		rem xu ly ky tu dac biet bao gom: & / - bang escape ^
		call ftvm3u8.bat %_channel% "!_src!"
		for /f %%i in (%_tmp_fdr%\%_channel%) do (
			set _clink=%%i
			set _clink=!_clink:"=!
			title update [ %_channel% ] - [ src: !_src_n! - !_src! ] - [ lnk no. !_lnk_n! ]
			rem echo ===============================================================================
			for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
			call "%_lib_fdr%\nchars.bat" _cols _ !_Columns!
			echo !_cols!
			echo [ !_count! ] Source [ !_src_n! ] checking no. !_lnk_n! : & echo !_clink!
			%_streamlink% -Q "!_clink!" | findstr /i /C:"%_stream_avai%" && (
				set /a _already_=0
				for /l %%k in (1,1,!_lnk_n!) do (
					for /f "delims=" %%a in ('%_ini% %_tvini% [%_channel%] _lnk[%%k]' ) do %%a
					set _already_lnk=!_lnk[%%k]!
					echo "!_already_lnk!" | findstr /c:"!_clink!">NUL && (
					set /a _already_=1
					echo [ ////////// already added ////////// ] )
				)
				if !_already_! equ 0 (
					%_ini% %_tvini% [%_channel%] _lnk[!_lnk_n!]=!_clink!
					%_ini% %_tvini% [%_channel%] _frm[!_lnk_n!]=!_src!
					if !_lnk_n! leq 1 echo %_streamlink% "--player=%_vlc%" "!_clink!" worst>"%_logs_fdr%\%_channel%.bat"
					set /a _lnk_n+=1 ) ) || echo [ is not a stream link for record or stream ]
			set /a _count+=1
			if !_lnk_n! geq %_min_lnk_num% goto lDone
		)
		set /a _src_n+=1 )

:lDone
	set /a _found=%_lnk_n%-1
	for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
	call "%_lib_fdr%\nchars.bat" _cols / %_Columns%
	echo %_cols%
	echo //
	echo // [ %_channel% ] [ atleast %_found% link(s) found ]
	echo //
	echo %_cols%
	rem upload ini file to ftp server
	if exist %_ftp% %_winscp% /script="%_ftp%"
	
	endlocal
	goto :eof