@echo off
setlocal enableextensions enabledelayedexpansion
if [%2]==[] goto :eof

call cfg.bat
set "_filename=%1"
set "_url=%2"

rem empty temporatory file
type NUL>"%_spath%tmp\%_filename%"
type NUL>"%_spath%tmp\%_filename%.fni"
type NUL>"%_spath%tmp\%_filename%.lnk"
type NUL>"%_spath%tmp\%_filename%.src"
type NUL>"%_spath%tmp\%_filename%.ifr"

rem download source of html page.
"%_wget%" -qO- %_url%>"%_spath%tmp\%_filename%.src"

rem find all 'http...' link in line that contained "function init"
"%_grep%" -Eo "%_grep_str1%(.*)" "%_spath%tmp\%_filename%.src" >> "%_spath%tmp\%_filename%.fni" && (
	echo [ "%_grep_str1%" found ]
	"%_grep%" -Eo "http[^\,\']+" "%_spath%tmp\%_filename%.fni" >> "%_spath%tmp\%_filename%.lnk" )

rem find all 'http...' link in line that contained "iframe"
"%_grep%" -Eo "%_grep_str2%(.*)" "%_spath%tmp\%_filename%.src" >> "%_spath%tmp\%_filename%.ifr" && (
	echo [ "%_grep_str2%" found ]
	"%_grep%" -Eo "http[^\,\'\"]+^" "%_spath%tmp\%_filename%.ifr" >> "%_spath%tmp\%_filename%" )

rem find all 'http...' link in line that contained "link ="
"%_grep%" -Eo "http[^\,\'\"]+^" "%_spath%tmp\%_filename%.src" >> "%_spath%tmp\%_filename%.lnk"

call "%_lib_fdr%\jsort.bat" "%_spath%tmp\%_filename%.lnk" /u > "%_spath%tmp\%_filename%new.lnk"
@move /y "%_spath%tmp\%_filename%new.lnk" "%_spath%tmp\%_filename%.lnk" > NUL

for /f %%i in (%_spath%tmp\%_filename%.lnk) do (
	echo "%%i" | %_grep% "m3u8" >> "%_spath%tmp\%_filename%" || (
		echo "%%i" | %_grep% "\.php" && (
			"%_wget%" -qO- "%%i" | %_grep% "m3u8" >> "%_spath%tmp\%_filename%" )
	)
)

call "%_lib_fdr%\jsort.bat" "%_spath%tmp\%_filename%" /u > "%_spath%tmp\%_filename%new"
@move /y "%_spath%tmp\%_filename%new" "%_spath%tmp\%_filename%" > NUL

endlocal
goto :eof
rem find 'http:\\*.m3u8*' strings ( %_grep% -Eo "(http[^\,\']+m3u8)([^\,\']*)" "%_spath%tmp\%_filename%.php">"%_spath%tmp\%_filename%.2" )
