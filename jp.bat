@echo off
setlocal
cls
call cfg.bat

set _out=%date:~0,2%%date:~3,2%_%time:~0,2%%time:~3,2%%time:~6,2%.mp4
set _out=jp_%_out: =%
set _p4j=p4j.txt

echo ffconcat version 1.0>%_p4j%
(for %%i in (p*.mp4) do @echo file %%i)>>%_p4j%
"%_ffmpeg%" -y -i %_p4j% -map 0 -c copy "%_out%"
rem "%_ffmpeg%" -i %_p4j% -c copy -movflags faststart %_out% -hide_banner

endlocal
goto :eof