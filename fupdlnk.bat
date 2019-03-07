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
		type NUL>"%_tmp_fdr%\%_channel%"
		call :lFindM3U8 %_channel% 1 "!_src!"
		for /f %%i in (%_tmp_fdr%\%_channel%) do (
			set _clink=%%i
			set _clink=!_clink:"=!
			title update [ %_channel% ] - [ src: !_src_n! - !_src! ] - [ lnk no. !_lnk_n! ]
			rem echo ===============================================================================
			for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
			call "%_lib_fdr%\nchars.bat" _cols _ !_Columns!
			echo !_cols!
			echo [ found !_count! in ] Source [ !_src_n! ] checking no. !_lnk_n! : & echo !_clink!
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

:lFindM3U8 _ofile _level _url
	@echo off
	setlocal enableextensions enabledelayedexpansion

	call cfg.bat
	set _ofile=%~1
	set _level=%~2
	set _url=%3
	set _filename=%_ofile%_%_level%
	set /a _lines=0
	
	type NUL>"%_tmp_fdr%\%_filename%.src"
	type NUL>"%_tmp_fdr%\%_filename%.fni"
	type NUL>"%_tmp_fdr%\%_filename%.lst"
	type NUL>"%_tmp_fdr%\%_filename%.ifr"
	
	"%_wget%" -T 30 -qO- %_url%>"%_tmp_fdr%\%_filename%.src"
	rem count lines of files
	for /f %%i in ('type "%_tmp_fdr%\%_filename%.src" ^| find /c /v ""') do set /a _lines=%%i
	if %_lines% equ 1 (
		echo [level !_level!]: !_url!
		more "%_tmp_fdr%\%_filename%.src"
		"%_grep%" "m3u8" "%_tmp_fdr%\%_filename%.src" >> "%_tmp_fdr%\%_ofile%"
		endlocal & exit /b )
	
	rem find all 'http...' link in line that contained "function init"
	"%_grep%" -Eo "%_grep_str1%(.*)" "%_tmp_fdr%\%_filename%.src" >> "%_tmp_fdr%\%_filename%.fni" && (
		echo [ "%_grep_str1%" found ]
		"%_grep%" -Eo "http[^\,\']+" "%_tmp_fdr%\%_filename%.fni" >> "%_tmp_fdr%\%_filename%.lst" )
	
	rem find all 'http...' link in line that contained "iframe"
	"%_grep%" -Eo "%_grep_str2%(.*)" "%_tmp_fdr%\%_filename%.src" >> "%_tmp_fdr%\%_filename%.ifr" && (
		echo [ "%_grep_str2%" found ]
		"%_grep%" -Eo "http[^\,\'\"]+^" "%_tmp_fdr%\%_filename%.ifr" >> "%_tmp_fdr%\%_filename%.lst" )
	
	rem find all 'http...' link in line that contained "link ="
	rem "%_grep%" -Eo "http[^\,\'\"]+^" "%_tmp_fdr%\%_filename%.src" >> "%_tmp_fdr%\%_filename%.lst"

	call "%_lib_fdr%\jsort.bat" "%_tmp_fdr%\%_filename%.lst" /u > "%_tmp_fdr%\%_filename%new.lst"
	@move /y "%_tmp_fdr%\%_filename%new.lst" "%_tmp_fdr%\%_filename%.lst" > NUL
	
	for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
	call "%_lib_fdr%\nchars.bat" _cols / !_Columns!
	echo !_cols!
	
	for /f %%i in (%_tmp_fdr%\%_filename%.lst) do (
		echo "%%i" | %_grep% "m3u8" >> "%_tmp_fdr%\%_ofile%" || (
			set /a _new_level=!_level!+1
			set _new_url="%%i"
			call :lFindM3U8 "!_ofile!" "!_new_level!" !_new_url! 
		)
	)

	endlocal & exit /b