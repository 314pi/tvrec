@echo off & setlocal ENABLEEXTENSIONS
call :DateToWeek 2017 03 16 yn cw dw
echo/Today (in ISO 8601 Week Date format) is: %yn%-W%cw%-%dw%
pause
goto :EOF



::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 
:DateToWeek %yy% %mm% %dd% yn cw dw
::
:: By:   Ritchie Lawrence, Updated 2002-11-20. Version 1.1
::
:: Func: Returns an ISO 8601 Week date from a calendar date.
::       For NT4/2000/XP/2003.
:: 
:: Args: %1 year component to be converted, 2 or 4 digits (by val)
::       %2 month component to be converted, leading zero ok (by val)
::       %3 day of month to be converted, leading zero ok (by val)
::       %4 var to receive year, 4 digits (by ref)
::       %5 var to receive calendar week, 2 digits, 01 to 53 (by ref)
::       %6 var to receive day of week, 1 digit, 1 to 7 (by ref)
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
setlocal ENABLEEXTENSIONS
set yy=%1&set mm=%2&set dd=%3
if 1%yy% LSS 200 if 1%yy% LSS 170 (set yy=20%yy%) else (set yy=19%yy%)
set /a dd=100%dd%%%100,mm=100%mm%%%100
set /a z=14-mm,z/=12,y=yy+4800-z,m=mm+12*z-3,Jd=153*m+2
set /a Jd=Jd/5+dd+y*365+y/4-y/100+y/400-32045
set /a y=yy+4798,Jp=y*365+y/4-y/100+y/400-31738,t=Jp+3,Jp=t-t%%7
set /a y=yy+4799,Jt=y*365+y/4-y/100+y/400-31738,t=Jt+3,Jt=t-t%%7
set /a y=yy+4800,Jn=y*365+y/4-y/100+y/400-31738,t=Jn+3,Jn=t-t%%7
set /a Jr=%Jp%,yn=yy-1,yn+=Jd/Jt,yn+=Jd/Jn
if %Jd% GEQ %Jn% (set /a Jr=%Jn%) else (if %Jd% GEQ %Jt% set /a Jr=%Jt%)
set /a diff=Jd-Jr,cw=diff/7+1,wd=diff%%7,wd+=1
if %cw% LSS 10 set cw=0%cw%
endlocal&set %4=%yn%&set %5=%cw%&set %6=%wd%&goto :EOF