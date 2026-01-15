@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: MOUSE - Osobni Portable Package Manager
:: =========================================================

:: [KONFIGURACE]
set "REPO_URL=https://raw.githubusercontent.com/ahoj416-cell/Tlauncher-installer/main/"

:: Cesty
set "MOUSE_HOME=%USERPROFILE%\.mouse"
set "MOUSE_BIN=%MOUSE_HOME%\bin"
set "MOUSE_APPS=%MOUSE_HOME%\apps"

:: Rychly skok
if "%1"=="install" goto :INSTALL
if "%1"=="setup" goto :SETUP
if "%1"=="list" goto :LIST
if "%1"=="help" goto :HELP
if "%1"=="" goto :HELP

echo Neznamy prikaz: %1
goto :EOF

:SETUP
echo [MOUSE] Nastavuji prostredi...
if not exist "%MOUSE_BIN%" mkdir "%MOUSE_BIN%"
if not exist "%MOUSE_APPS%" mkdir "%MOUSE_APPS%"

:: Kopie skriptu
if /I not "%~dp0"=="%MOUSE_BIN%\" (
    copy /Y "%~f0" "%MOUSE_BIN%\mouse.bat" >nul
    echo [OK] Mouse zkopirovana do %MOUSE_BIN%
)

:: Pridani do PATH (Jednoradkova verze pro stabilitu)
echo [MOUSE] Pridavam do PATH...
powershell -NoProfile -Command "$p=[Environment]::GetEnvironmentVariable('Path','User'); if ($p -notlike '*%MOUSE_BIN%*') { [Environment]::SetEnvironmentVariable('Path', $p + ';%MOUSE_BIN%', 'User'); Write-Host '[OK] Pridano do PATH.' -Fg Green } else { Write-Host '[INFO] Uz je v PATH.' -Fg Yellow }"

echo.

echo Hotovo! Nyni zavri toto okno, otevri nove a napis 'mouse'.
goto :EOF

:INSTALL
if "%2"=="" (
    echo [CHYBA] Chybi jmeno aplikace. (mouse install neco)
    goto :EOF
)

set "APP_NAME=%2"
echo [MOUSE] Hledam '%APP_NAME%'...

:: PowerShell instalator (stazene na jeden radek pro bezpecnost v BAT)
powershell -NoProfile -Command "$u='%REPO_URL%%APP_NAME%.json'; try { $m=iwr $u -UseBasicParsing | ConvertFrom-Json; Write-Host ('[INFO] Verze: '+$m.version); $dir='%MOUSE_APPS%
%APP_NAME%'; md $dir -Force|Out-Null; $exe=Split-Path $m.url -Leaf; $out=Join-Path $dir $exe; Write-Host '[DOWN] Stahuji...'; iwr $m.url -OutFile $out; $shim='%MOUSE_BIN%
%APP_NAME%.cmd'; sc $shim ('@echo off'+[Environment]::NewLine+'"'+$out+'" %*'); Write-Host ('[OK] Nainstalovano: '+$out) -Fg Green } catch { Write-Error 'Chyba stahovani nebo aplikace neexistuje.' }"

goto :EOF

:LIST
echo [MOUSE] Nainstalovane aplikace:
if exist "%MOUSE_APPS%" (
    dir "%MOUSE_APPS%" /b /ad
) else (
    echo Zadne.
)
goto :EOF

:HELP
echo.

echo  MOUSE PACKAGE MANAGER
echo  =====================
echo  1. Prvni spusteni:  mouse setup
echo  2. Instalace:       mouse install [jmeno]
echo  3. Seznam:          mouse list
echo.
goto :EOF
