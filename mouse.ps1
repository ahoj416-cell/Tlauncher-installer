# Mouse Package Manager
# Usage: mouse install <app_name>

param (
    [string]$Command,
    [string]$App
)

# --- KONFIGURACE ---
# Změň toto na své GitHub repo (URL k raw souborům ve složce bucket)
# Příklad: https://raw.githubusercontent.com/TvojeJmeno/mouse-bucket/main/
$BucketUrl = "https://raw.githubusercontent.com/TvojeJmeno/mouse-bucket/main/"

$InstallDir = "$env:USERPROFILE\.mouse\apps"
$BinDir = "$env:USERPROFILE\.mouse\bin"

# Vytvoření adresářů, pokud neexistují
if (-not (Test-Path $InstallDir)) { New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null }
if (-not (Test-Path $BinDir)) { New-Item -ItemType Directory -Force -Path $BinDir | Out-Null }

# Přidání do PATH (pro aktuální sezení)
if ($env:Path -notlike "*$BinDir*") {
    $env:Path += ";$BinDir"
    Write-Host "Tip: Přidej '$BinDir' do systémové PATH pro trvalé použití." -ForegroundColor Yellow
}

function Install-App {
    param ($appName)
    
    if (-not $appName) { Write-Error "Musíš zadat jméno aplikace!"; return }

    Write-Host "Hledám '$appName' v repozitáři..." -ForegroundColor Cyan
    
    $manifestUrl = "$BucketUrl$appName.json"
    
    try {
        # 1. Stáhnout manifest (JSON)
        $jsonContent = Invoke-RestMethod -Uri $manifestUrl -ErrorAction Stop
        
        Write-Host "Nalezena verze: $($jsonContent.version)"
        Write-Host "Stahuji z: $($jsonContent.url)"
        
        # 2. Stáhnout .exe
        $appDir = Join-Path $InstallDir $appName
        if (-not (Test-Path $appDir)) { New-Item -ItemType Directory -Force -Path $appDir | Out-Null }
        
        $exeName = Split-Path $jsonContent.url -Leaf
        $outFile = Join-Path $appDir $exeName
        
        Invoke-WebRequest -Uri $jsonContent.url -OutFile $outFile
        
        # 3. Vytvořit shim (zástupce) v bin složce
        $shimPath = Join-Path $BinDir "$($appName).ps1"
        # Jednoduchý shim, který spustí exe
        $shimContent = "& '$outFile' `$args"
        Set-Content -Path $shimPath -Value $shimContent
        
        # Volitelně i .cmd pro cmd.exe
        $cmdShimPath = Join-Path $BinDir "$($appName).cmd"
        Set-Content -Path $cmdShimPath -Value "@echo off`n`"$outFile`" %*"

        Write-Host "Úspěšně nainstalováno! Nyní můžeš napsat '$appName' do konzole." -ForegroundColor Green

    } catch {
        Write-Error "Aplikace '$appName' nebyla nalezena nebo došlo k chybě sítě."
        Write-Error $_.Exception.Message
    }
}

# --- HLAVNÍ LOGIKA ---

switch ($Command) {
    "install" { Install-App $App }
    "list" { 
        Write-Host "Nainstalované aplikace:" -ForegroundColor Cyan
        Get-ChildItem $InstallDir | ForEach-Object { Write-Host " - $($_.Name)" }
    }
    "help" {
        Write-Host "Mouse Package Manager v0.1"
        Write-Host "  mouse install <app>  - Nainstaluje aplikaci"
        Write-Host "  mouse list           - Zobrazí nainstalované"
    }
    default {
        Write-Host "Neznámý příkaz. Zkus 'mouse help'." -ForegroundColor Red
    }
}
