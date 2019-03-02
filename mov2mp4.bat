@echo off & cls
setlocal enableextensions enabledelayedexpansion
call cfg.bat
set _dir=I:\Video
rem for /f "tokens=*" %%g in ('dir /b %_dir%^\*.mov') do %_ffmpeg% -i "%_dir%\%%g" -vf scale=840:-2 "%_dir%\%%g.mp4"
for /f "tokens=*" %%g in ('dir /b %_dir%^\*.mov') do (
	%_ffmpeg% -y -i "%_dir%\%%g" -map_metadata 0 -map_metadata:s:v 0:s:v -map_metadata:s:a 0:s:a -vf scale=840:-2 "%_dir%\%%g.mp4"
	timeout /t 10
)