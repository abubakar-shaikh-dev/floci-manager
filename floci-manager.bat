@echo off
REM ==========================================================
REM  Floci Manager - a one-key menu for Floci (local AWS) on Windows
REM  https://github.com/abubakar-shaikh-dev/floci-manager
REM  License: MIT
REM
REM  Optional: set FLOCI_PORT before running to use another port.
REM ==========================================================

for /f "tokens=2 delims=:." %%c in ('chcp') do set "OLDCP=%%c"
chcp 65001 >nul
setlocal
set "VERSION=1.0.0"
title Floci Manager v%VERSION%

REM ===== Colors (ANSI, needs Windows 10 or newer) =====
for /F "delims=#" %%E in ('"prompt #$E# & for %%E in (1) do rem"') do set "ESC=%%E"
set "R=%ESC%[0m"
set "B=%ESC%[1m"
set "CY=%ESC%[96m"
set "WH=%ESC%[97m"
set "DIM=%ESC%[90m"
set "GN=%ESC%[92m"
set "RD=%ESC%[91m"
set "YL=%ESC%[93m"
set "BG_OK=%ESC%[42;30m"
set "BG_BAD=%ESC%[41;97m"

REM ===== Settings =====
if defined FLOCI_PORT (set "PORT=%FLOCI_PORT%") else (set "PORT=4566")
set "EP=http://localhost:%PORT%"
set "AWS_ACCESS_KEY_ID=test"
set "AWS_SECRET_ACCESS_KEY=test"
set "AWS_DEFAULT_REGION=us-east-1"
set "DATA_DIR=%~dp0data"

REM ===== Is the Floci CLI installed? =====
where floci >nul 2>&1 || (
  cls
  echo.
  echo   %YL%! Floci CLI not found.%R%
  echo.
  echo   %DIM%Open PowerShell, run this, then start this file again:%R%
  echo.
  echo     %WH%iwr https://floci.io/install.ps1 ^| iex%R%
  echo.
  pause
  exit /b 1
)


REM ==========================================================
REM  MAIN MENU
REM ==========================================================
:menu
set "ST=0"
call :is_running && set "ST=1"
cls
echo.
echo   %CY%┌────────────────────────────────────────────────────────┐%R%
echo   %CY%│%R%  %B%%WH%FLOCI%R%                              %DIM%Local AWS Manager%R%  %CY%│%R%
echo   %CY%└────────────────────────────────────────────────────────┘%R%
echo.
if "%ST%"=="1" (
  echo   %BG_OK% RUNNING %R%  %DIM%%EP%%R%
  echo.
  echo   %YL%→%R%  %DIM%Ready. Press%R% %CY%B%R% %DIM%for buckets or%R% %CY%W%R% %DIM%for the web console.%R%
) else (
  echo   %BG_BAD% STOPPED %R%  %DIM%%EP%%R%
  echo.
  echo   %YL%→%R%  %DIM%Press%R% %CY%S%R% %DIM%to start Floci.%R%
)

if "%ST%"=="1" (set "A=0") else (set "A=1")

call :section "FLOCI"
call :row %A%  S "Start"                "fresh, nothing saved"
call :row %A%  K "Start + keep my data" "saved in the data folder"
call :row %ST% X "Stop"                 ""
call :row 1    I "Status"               "container and health"
call :row %ST% L "Logs"                 "last 50 lines"
call :row 1    H "Health check"         "find problems"

call :section "STORAGE (S3)"
call :row %ST% B "My buckets"           "see everything you have"
call :row %ST% N "New bucket"           ""
call :row %ST% F "Files in a bucket"    ""
call :row %ST% U "Upload a file"        "drag and drop works"
call :row %ST% R "Remove a bucket"      "asks you to confirm"

call :section "TOOLS"
call :row %ST% W "Web console"          "opens in your browser"
call :row 1    C "Connection details"   "keys, region, endpoint"
call :row 1    Q "Quit"                 ""

echo.
<nul set /p "=  %DIM%Press a key to choose...%R% "
choice /C SKXILHBNFURWCQ /N >nul
set "k=%errorlevel%"

if "%k%"=="1"  goto start
if "%k%"=="2"  goto start_persistent
if "%k%"=="3"  goto stop
if "%k%"=="4"  goto status
if "%k%"=="5"  goto logs
if "%k%"=="6"  goto doctor
if "%k%"=="7"  goto list_buckets
if "%k%"=="8"  goto create_bucket
if "%k%"=="9"  goto list_files
if "%k%"=="10" goto upload
if "%k%"=="11" goto delete_bucket
if "%k%"=="12" goto console
if "%k%"=="13" goto details
if "%k%"=="14" goto quit
goto menu


REM ==========================================================
REM  FLOCI
REM ==========================================================
:start
call :screen "Start Floci"
call :need_docker || goto back
call :is_running && (
  echo   %YL%Floci is already running.%R%
  echo   %DIM%To switch mode, stop it first with X.%R%
  goto back
)
floci start --port %PORT%
set "rc=%errorlevel%"
call :result "Floci is running at %EP%" "Press H on the menu to find out why."
goto back

:start_persistent
call :screen "Start Floci and keep my data"
call :need_docker || goto back
call :is_running && (
  echo   %YL%Floci is already running.%R%
  echo   %DIM%To switch mode, stop it first with X.%R%
  goto back
)
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
echo   %DIM%Saving data to %DATA_DIR%%R%
echo.
floci start --port %PORT% --persist "%DATA_DIR%"
set "rc=%errorlevel%"
call :result "Floci is running. Your data is saved between restarts." "Press H on the menu to find out why."
goto back

:stop
call :screen "Stop Floci"
call :is_running || (
  echo   %YL%Floci is already stopped.%R%
  goto back
)
floci stop
timeout /t 1 /nobreak >nul
call :is_running || (
  set "rc=0"
  call :result "Floci stopped." ""
  goto back
)
echo.
echo   %YL%Still running. Stopping whatever is using port %PORT%...%R%
echo.
for /f %%i in ('docker ps -q --filter "publish=%PORT%"') do docker stop %%i
timeout /t 1 /nobreak >nul
set "rc=1"
call :is_running || set "rc=0"
call :result "Floci stopped." "Something else is using port %PORT%. Press H to diagnose."
goto back

:status
call :screen "Status"
floci status
goto back

:logs
call :screen "Logs  (last 50 lines)"
call :need_docker || goto back
floci logs --tail 50
goto back

:doctor
call :screen "Health check"
floci doctor
goto back


REM ==========================================================
REM  STORAGE
REM ==========================================================
:list_buckets
call :screen "My buckets"
call :need_ready || goto back
call :show_buckets
goto back

:create_bucket
call :screen "New bucket"
call :need_ready || goto back
set "bucket="
echo   %DIM%Lowercase letters, numbers, dots and hyphens. 3 to 63 characters.%R%
echo   %DIM%Press Enter with no name to cancel.%R%
echo.
set /p "bucket=  %CY%?%R% Bucket name %CY%›%R% "
if not defined bucket goto menu
echo.
aws s3 mb "s3://%bucket%" --endpoint-url "%EP%" --no-cli-pager
set "rc=%errorlevel%"
call :result "Bucket created: s3://%bucket%" "Check the name rules above. The name may already exist."
goto back

:list_files
call :screen "Files in a bucket"
call :need_ready || goto back
call :pick_bucket
if errorlevel 2 goto menu
if errorlevel 1 goto back
echo.
aws s3 ls "s3://%bucket%" --recursive --human-readable --summarize --endpoint-url "%EP%" --no-cli-pager
set "rc=%errorlevel%"
call :result "That is everything in s3://%bucket%" "Check that the bucket name is right."
goto back

:upload
call :screen "Upload a file"
call :need_ready || goto back
call :pick_bucket
if errorlevel 2 goto menu
if errorlevel 1 goto back
echo.
set "file="
set /p "file=  %CY%?%R% File path %DIM%(drag and drop works)%R% %CY%›%R% "
if not defined file goto menu
set "file=%file:"=%"
if not exist "%file%" (
  echo.
  echo   %RD%✗ File not found.%R%
  goto back
)
for %%f in ("%file%") do set "fname=%%~nxf"
echo.
aws s3 cp "%file%" "s3://%bucket%/" --endpoint-url "%EP%" --no-cli-pager
set "rc=%errorlevel%"
call :result "Uploaded to s3://%bucket%/%fname%" "Check the bucket name and the file path."
goto back

:delete_bucket
call :screen "Remove a bucket"
call :need_ready || goto back
call :pick_bucket
if errorlevel 2 goto menu
if errorlevel 1 goto back
echo.
echo   %RD%Danger:%R% this permanently deletes %WH%%bucket%%R% and every file inside it.
echo.
set "confirm="
set /p "confirm=  Type the bucket name to confirm, or press Enter to cancel %CY%›%R% "
if /i not "%confirm%"=="%bucket%" (
  echo.
  echo   %DIM%Cancelled. Nothing was deleted.%R%
  goto back
)
echo.
aws s3 rb "s3://%bucket%" --force --endpoint-url "%EP%" --no-cli-pager
set "rc=%errorlevel%"
call :result "Bucket removed: s3://%bucket%" "Check that the bucket name is right."
goto back


REM ==========================================================
REM  TOOLS
REM ==========================================================
:console
call :screen "Web console"
call :is_running || (
  echo   %YL%! Floci is stopped.%R%
  echo   %DIM%Go back and press S ^(or K^) to start it.%R%
  goto back
)
echo   %DIM%Opening in your browser...%R%
echo   %DIM%The first time can take a minute while it downloads.%R%
start "" "%EP%/_floci/ui"
echo.
echo   %WH%%EP%/_floci/ui%R%
goto back

:details
call :screen "Connection details"
echo   %DIM%Endpoint     %WH%%EP%%R%
echo   %DIM%Console      %WH%%EP%/_floci/ui%R%
echo   %DIM%Access key   %WH%test%R%
echo   %DIM%Secret key   %WH%test%R%
echo   %DIM%Region       %WH%us-east-1%R%
echo   %DIM%Data folder  %WH%%DATA_DIR%%R%
call :section "YOUR TERMINAL"
echo   %WH%set AWS_ENDPOINT_URL=%EP%%R%
echo   %WH%set AWS_ACCESS_KEY_ID=test%R%
echo   %WH%set AWS_SECRET_ACCESS_KEY=test%R%
echo   %WH%set AWS_DEFAULT_REGION=us-east-1%R%
echo.
echo   %DIM%In your code, turn on path-style S3 addressing.%R%
goto back

:quit
echo.
call :is_running && echo   %DIM%Floci is still running in the background.%R%
echo.
if defined OLDCP chcp %OLDCP% >nul
exit /b 0


REM ==========================================================
REM  HELPERS
REM ==========================================================

:back
echo.
echo   %DIM%Press any key to go back...%R%
pause >nul
goto menu

:screen
cls
echo.
echo   %CY%◆%R%  %B%%WH%%~1%R%
echo   %DIM%──────────────────────────────────────────────────────────%R%
echo.
exit /b 0

:section
setlocal EnableDelayedExpansion
set "t=%~1                    "
set "t=!t:~0,14!"
echo.
echo   %CY%!t!%R%%DIM%────────────────────────────────────────────%R%
endlocal
exit /b 0

:row
setlocal EnableDelayedExpansion
set "kc=%DIM%"
set "lc=%DIM%"
if "%~1"=="1" set "kc=%CY%" & set "lc=%WH%"
set "lbl=%~3                              "
set "lbl=!lbl:~0,24!"
echo   !kc![%~2]%R%  !lc!!lbl!%R%  %DIM%%~4%R%
endlocal
exit /b 0

:result
echo.
if "%rc%"=="0" (
  echo   %GN%✓ %~1%R%
) else (
  echo   %RD%✗ That did not work ^(error %rc%^)%R%
  echo   %DIM%%~2%R%
)
exit /b 0

:is_running
REM Asks Floci directly on its port. Works with any container name.
curl -s -o nul --max-time 2 "%EP%" >nul 2>&1
if errorlevel 1 (exit /b 1) else (exit /b 0)

:need_docker
docker info >nul 2>&1 && exit /b 0
echo   %YL%! Docker is not running.%R%
echo   %DIM%Open Docker Desktop, wait until it says running, then try again.%R%
exit /b 1

:need_ready
where aws >nul 2>&1 || (
  echo   %YL%! AWS CLI not found.%R%
  echo   %DIM%Install it from aws.amazon.com/cli and try again.%R%
  exit /b 1
)
call :is_running || (
  echo   %YL%! Floci is stopped.%R%
  echo   %DIM%Go back and press S ^(or K^) to start it.%R%
  exit /b 1
)
exit /b 0

:show_buckets
setlocal EnableDelayedExpansion
set "n=0"
for /f "tokens=1,2,3" %%a in ('aws s3 ls --endpoint-url "%EP%"') do (
  set /a n+=1
  echo   %CY%●%R%  %%c   %DIM%created %%a %%b%R%
)
if !n! equ 0 (
  echo   %DIM%No buckets yet. Press N on the menu to create one.%R%
) else (
  echo.
  echo   %DIM%!n! total%R%
)
endlocal
exit /b 0

REM Lets the user pick a bucket by number or by typing its name.
REM Sets %bucket%.  Returns 0 = picked, 1 = no buckets, 2 = cancelled.
:pick_bucket
set "bucket="
setlocal EnableDelayedExpansion
set "n=0"
echo   %DIM%Your buckets%R%
echo.
for /f "tokens=3" %%b in ('aws s3 ls --endpoint-url "%EP%"') do (
  set /a n+=1
  set "b!n!=%%b"
  echo     %CY%!n!%R%   %%b
)
if !n! equ 0 (
  echo     %DIM%No buckets yet. Press N on the menu to create one.%R%
  endlocal
  exit /b 1
)
echo.
set "ans="
set /p "ans=  %CY%?%R% Number or name %DIM%(Enter to cancel)%R% %CY%›%R% "
if not defined ans (
  endlocal
  exit /b 2
)
set "pick=!ans!"
set "idx="
set ans | findstr /r /c:"^ans=[0-9][0-9]*$" >nul && set /a idx=!ans! 2>nul
if defined idx if !idx! geq 1 if !idx! leq !n! for %%i in (!idx!) do set "pick=!b%%i!"
endlocal & set "bucket=%pick%"
exit /b 0
