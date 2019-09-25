@echo off
setlocal & cls
call cfg.bat
set _s1=00:15:24
rem ---------------- QC I
set _e1=00:18:17
set _s2=00:18:17
rem ---------------- QC II
set _e2=00:18:17
set _s3=00:18:17
rem ---------------- END
set _e3=00:43:06
set _long=00:59:59
set _name=%_spath%nvgm27
set _name=%_name%.mp4
set _in=%_spath%2.mp4
rem //////////////////////////////////////
call :lTimeToNumber _s1 %_s1%
call :lTimeToNumber _e1 %_e1%
call :lTimeToNumber _s2 %_s2%
call :lTimeToNumber _e2 %_e2%
call :lTimeToNumber _s3 %_s3%
call :lTimeToNumber _e3 %_e3%
rem //////////////////////////////////////
set _s4j=s4j.txt
echo %time:~0,-3% : separating sengments ...
"%_ffmpeg%" -y -v error -i %_in% -map 0 -c copy -segment_times %_s1%,%_s1%,%_s1%,%_s1%,%_s1%,%_e3% -f segment -fflags +genpts -reset_timestamps 1 "seg%%d.mp4"
del seg0.mp4 seg2.mp4 seg4.mp4 seg6.mp4
rem //////////////////////////////////////
set _jname=join_%date:~0,2%%date:~3,2%_%time:~0,2%%time:~3,2%%time:~6,2%.mp4
set _jname=%_jname: =%
echo ffconcat version 1.0>%_s4j%
(for %%i in (seg*.mp4) do @echo file %%i)>>%_s4j%
echo %time:~0,-3% : joining segs ...
"%_ffmpeg%" -y -v error -i %_s4j% -map 0 -c copy "%_jname%"
timeout /t 3 /nobreak>NUL
"%_ffmpeg%" -v error -i "%_jname%" -ss 00:00:00 -to %_long% -movflags faststart -fflags +genpts -vcodec copy -acodec copy "%_name%"
rem ////////////////////////////////////// Upload to FTP server
call :lUpFTP %_name%

del %_s4j% %_jname% seg1.mp4 seg3.mp4 seg5.mp4
endlocal
goto :eof

:lUpFTP _name
	@echo off
	setlocal
	call cfg.bat
	set _name=%~1
	set _f4up=up.ftp
	echo open ftp://nhchue5r:FUm9ZEilLF3r9IlNkdEZ@ftp.chuyendungath.vn/>%_f4up%
	echo cd "/public_html/images/videos/up">>%_f4up%
	echo put -transfer=binary "%_name%">>%_f4up%
	echo exit>>%_f4up%
	echo ///////////////////////////////////////////////////////////////////////////////
	echo %time:~0,-3% : uplooading to ftp server ...
	%_winscp% /script="%_f4up%"
	timeout /t 5
	rundll32 user32.dll,MessageBeep
	del %_f4up%
	endlocal & exit /b
:lTimeToNumber _num _time
	@echo off
	setlocal
	if "%~2"=="" ( set "yy=%time%" ) else ( set "yy=%~2" )
	set /a h=100%yy:~0,2% %% 100
	if %h% lss 10 set h=0%h%
	set /a _num=(1%h%-100)*3600 + (1%yy:~3,2%-100)*60 + (1%yy:~6,2%-100)
	endlocal & if not "%~1"=="" set /a "%~1=%_num%" & exit /b