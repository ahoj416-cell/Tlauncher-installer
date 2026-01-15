@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: MOUSE - Osobni Portable Package Manager
:: =========================================================

:: [KONFIGURACE] Zmen na svoje GitHub URL (musi koncit lomitkem /)
set "REPO_URL=https://raw.githubusercontent.com/ahoj416-cell/Tlauncher-installer/main/"

:: Cesty (vse v uzivatelskem profilu = bez admin prav)
set "MOUSE_HOME=%USERPROFILE%\.mouse"
set "MOUSE_BIN=%MOUSE_HOME%\bin"
set "MOUSE_APPS=%MOUSE_HOME%\apps"

:: Rychly skok na prikazy
if "%1"=="install" goto :INSTALL
if "%1"=="setup" goto :SETUP
if "%1"=="list" goto :LIST
if "%1"=="help" goto :HELP
if "%1"=="" goto :HELP

:: Pokud prikaz neni znamy
echo Neznamy prikaz: %1
goto :EOF

:SETUP
echo [MOUSE] Nastavuji prostredi...
if not exist "%MOUSE_BIN%" mkdir "%MOUSE_BIN%"
if not exist "%MOUSE_APPS%" mkdir "%MOUSE_APPS%"

:: Zkopirovat tento skript do bin slozky, pokud tam neni
if /I not "%~dp0"=="%MOUSE_BIN%\" (
    copy /Y "%~f0" "%MOUSE_BIN%\mouse.bat" >nul
    echo [OK] Mouse zkopirovana do %MOUSE_BIN%
)

:: Pridani do PATH (bez admin prav, pomoci PowerShellu pro bezpecnost)
echo [MOUSE] Pridavam do PATH (trvale)...
powershell -NoProfile -Command \
    "$path = [Environment]::GetEnvironmentVariable('Path', 'User'); " \
    "$bin = '%MOUSE_BIN%'; " \
    "if ($path -notlike \"*$bin*\") { " \
    "    [Environment]::SetEnvironmentVariable('Path', $path + ';' + $bin, 'User'); " \
    "    Write-Host '[OK] Pridano do PATH. Restartuj konzoli.' -ForegroundColor Green; " \
    "} else { " \
    "    Write-Host '[INFO] Uz je v PATH.' -ForegroundColor Yellow; " \
    "}"

echo.
echo Hotovo! Nyni restartuj prikazovou radku a napis 'mouse'.
goto :EOF

:INSTALL
if "%2"=="" (
    echo [CHYBA] Chybi jmeno aplikace. (mouse install neco)
    goto :EOF
)

set "APP_NAME=%2"
echo [MOUSE] Hledam '%APP_NAME%'...

:: PowerShell magie pro stazeni JSONu a instalaci
powershell -NoProfile -Command \
    "$repo = '%REPO_URL%'; " \
    "$app = '%APP_NAME%'; " \
    "$appsDir = '%MOUSE_APPS%'; " \
    "$binDir = '%MOUSE_BIN%'; " \
    "try { " \
    "    $url = $repo + $app + '.json'; " \
    "    $m = Invoke-RestMethod -Uri $url; " \
    "    Write-Host ('[INFO] Verze: ' + $m.version); " \
    "     " \
    "    $exeName = Split-Path $m.url -Leaf; " \
    "    $installPath = Join-Path $appsDir $app; " \
    "    if (-not (Test-Path $installPath)) { New-Item -ItemType Directory -Path $installPath | Out-Null }; " \
    "    $outFile = Join-Path $installPath $exeName; " \
    "     " \
    "    Write-Host ('[DOWN] Stahuji: ' + $m.url); " \
    "    Invoke-WebRequest -Uri $m.url -OutFile $outFile; " \
    "     " \
    "    $shim = Join-Path $binDir ($app + '.cmd'); " \
    "    $cmd = '@echo off' + [Environment]::NewLine + '"' + $outFile + '" %*'; " \
    "    Set-Content -Path $shim -Value $cmd; " \
    "    Write-Host ('[OK] Nainstalovano! Spust prikazem: ' + $app) -ForegroundColor Green; " \
    "} catch { " \
    "    Write-Error ('[CHYBA] ' + $_.Exception.Message); " \
    "}"
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