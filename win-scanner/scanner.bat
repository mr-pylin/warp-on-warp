chcp 936
cls
@echo off & setlocal enabledelayedexpansion
goto start

:start
    if not exist "warp.exe" echo warp.exe Not Found&pause&exit
    if not exist "..\subnets_v4.txt" echo IPV4 ..\subnets_v4.txt Not Found&pause&exit
    if not exist "..\subnets_v6.txt" echo IPV6 ..\subnets_v6.txt Not Found&pause&exit
goto main

:main
    title CF WARP IP Scanner v23.11.15
    echo Credit: Yonggekkk (github.com/yonggekkk/warp-yg)
    echo. 
    set /a menu=1
    echo 1. WARP-IPv4&echo 2. WARP-IPv6&echo 0. Exit&echo.
    set /p menu=Please enter the option number (default is %menu%):
    if %menu%==0 exit
    if %menu%==1 set filename=..\subnets_v4.txt&goto getv4
    if %menu%==2 set filename=..\subnets_v6.txt&goto getv6
    cls
goto main

:getv4
    for /f "delims=" %%i in ('findstr /v "^#" "%filename%"') do (
        set !random!_%%i=randomsort
    )
    for /f "tokens=2,3,4 delims=_.=" %%i in ('set ^| findstr =randomsort ^| sort /m 10240') do (
        call :randomcidrv4
        if not defined %%i.%%j.%%k.!cidr! set %%i.%%j.%%k.!cidr!=anycastip&set /a n+=1
        if !n! EQU 100 goto getip
    )
goto getv4

:randomcidrv4
    set /a cidr=%random%%%256
    goto :eof

    :getv6
    for /f "delims=" %%i in (%filename%) do (
        set !random!_%%i=randomsort
    )
    for /f "tokens=2,3,4 delims=_:=" %%i in ('set ^| findstr =randomsort ^| sort /m 10240') do (
        call :randomcidrv6
        if not defined [%%i:%%j:%%k::!cidr!] set [%%i:%%j:%%k::!cidr!]=anycastip&set /a n+=1
        if !n! EQU 100 goto getip
    )
goto getv6

:randomcidrv6
    set str=0123456789abcdef
    set /a r=%random%%%16
    set cidr=!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!:!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!:!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!:!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
    set /a r=%random%%%16
    set cidr=!cidr!!str:~%r%,1!
goto :eof

:getip
    del ip.txt > nul 2>&1
    for /f "tokens=1 delims==" %%i in ('set ^| findstr =randomsort') do (
        set %%i=
    )
    for /f "tokens=1 delims==" %%i in ('set ^| findstr =anycastip') do (
        echo %%i>>ip.txt
    )
    for /f "tokens=1 delims==" %%i in ('set ^| findstr =anycastip') do (
        set %%i=
    )
    warp
    del ip.txt > nul 2>&1
    echo The results saved to the result.csv file.
    echo Use warp.sh and the 2nd option to import this result.csv file
    echo Press any key to close the window...
    pause>nul
    exit