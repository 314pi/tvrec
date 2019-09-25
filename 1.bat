@echo off
set _in=1.mp4
set _out=2.mp4
set _start=00:00:20
set _end=03:39:59
call cfg.bat
::=====================
"%_ffmpeg%" -i "%_in%" -ss %_start% -to %_end% -movflags faststart -fflags +genpts -v error -vcodec copy -acodec copy "%_out%"