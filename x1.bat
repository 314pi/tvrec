call cfg.bat
for /f "Tokens=1,2 delims=: " %%a in ('mode con^|findstr "Columns"') do set _%%a=%%b
call "%_lib_fdr%\nchars.bat" _cols _ %_Columns%
echo %_cols%