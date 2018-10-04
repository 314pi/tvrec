@echo off
setlocal enableextensions enabledelayedexpansion
call cfg.bat
set "_filename=%1"
set "_url=%2"

rem empty temporatory file
type NUL>"%_spath%tmp\%_filename%"
type NUL>"%_spath%tmp\%_filename%.fni"
type NUL>"%_spath%tmp\%_filename%.lnk"
type NUL>"%_spath%tmp\%_filename%.src"
type NUL>"%_spath%tmp\%_filename%.ifr"

rem  download source of html page.
"%_wget%" -qO- %_url%>"%_spath%tmp\%_filename%.src"

rem find all 'http...' link in line that contained "function init"
"%_grep%" -Eo "function init(.*)" "%_spath%tmp\%_filename%.src">>"%_spath%tmp\%_filename%.fni" && (
    echo [ "function init" found ]
    "%_grep%" -Eo "http[^\,\']+" "%_spath%tmp\%_filename%.fni">>"%_spath%tmp\%_filename%.lnk" 
)

rem find all 'http...' link in line that contained "iframe"
"%_grep%" -Eo "iframe(.*)" "%_spath%tmp\%_filename%.src">>"%_spath%tmp\%_filename%.ifr" && (
    echo [ "iframe" found ]
    "%_grep%" -Eo "http[^\,\'\"]+^" "%_spath%tmp\%_filename%.ifr">>"%_spath%tmp\%_filename%"
)

for /f %%i in (%_spath%tmp\%_filename%.lnk) do (
    echo "%%i" | findstr "m3u8">>"%_spath%tmp\%_filename%" || (
        "%_wget%" -qO- "%%i" | findstr "m3u8">>"%_spath%tmp\%_filename%" )
)

endlocal
goto :eof
rem  find 'http:\\*.m3u8*' strings ( %_grep% -Eo "(http[^\,\']+m3u8)([^\,\']*)" "%_spath%tmp\%_filename%.php">"%_spath%tmp\%_filename%.2" )
