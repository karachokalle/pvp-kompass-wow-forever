# PvP-Kompass companion updater. Windows PowerShell 5.1+; no Python needed.
$ErrorActionPreference = 'Stop'
$configDirectory = Join-Path ([Environment]::GetFolderPath('ApplicationData')) 'PvPKompass'
$configPath = Join-Path $configDirectory 'updater_config.json'
$portablePath = Join-Path $PSScriptRoot 'updater_config.json'
$config = @{ addon_dir = ''; saved_variables = ''; manifest_url = 'https://raw.githubusercontent.com/karachokalle/pvp-kompass-wow-forever/main/update-manifest.json' }
foreach ($path in @($configPath, $portablePath)) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        try {
            $saved = [IO.File]::ReadAllText($path) | ConvertFrom-Json
            foreach ($key in @('addon_dir','saved_variables','manifest_url')) { if ($saved.$key) { $config[$key] = [string]$saved.$key } }
            break
        } catch { Write-Warning "Einstellungen konnten nicht gelesen werden: $path" }
    }
}
function Save-Settings {
    New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null
    [IO.File]::WriteAllText($configPath, ($config | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
}
function Ask-Path([string]$label, [string]$current) {
    Write-Host "$label [$current]" -ForegroundColor Cyan
    $answer = Read-Host 'Pfad eingeben; leer = behalten'
    if ([string]::IsNullOrWhiteSpace($answer)) { return $current }
    return $answer.Trim().Trim('"')
}
function Configure {
    $config.addon_dir = Ask-Path 'Addon-Ordner (enthaelt PvPKompass.toc)' $config.addon_dir
    $config.saved_variables = Ask-Path 'WTF\Account\ACCOUNT\SavedVariables\PvPKompass.lua (optional)' $config.saved_variables
    Save-Settings
}
function Is-WowRunning {
    return [bool](Get-Process -Name 'Wow','WowClassic','WowB','WowT' -ErrorAction SilentlyContinue)
}
function Update-Addon {
    $addonPath = [IO.Path]::GetFullPath($config.addon_dir)
    if (-not (Test-Path -LiteralPath (Join-Path $addonPath 'PvPKompass.toc') -PathType Leaf)) { throw 'PvPKompass.toc fehlt. Bitte unter Menuepunkt 1 den Addon-Ordner waehlen.' }
    $wowPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $addonPath))
    $arguments = @{ ManifestUrl = $config.manifest_url; WowRoot = $wowPath; AddonDirectory = $addonPath; Force = $true }
    if ($config.saved_variables) { $arguments.SavedVariablesPath = $config.saved_variables }
    & (Join-Path $PSScriptRoot 'Update-PvPKompass.ps1') @arguments
}
function Has-Request {
    if (-not $config.saved_variables -or -not (Test-Path -LiteralPath $config.saved_variables -PathType Leaf)) { return $false }
    return [IO.File]::ReadAllText($config.saved_variables) -match '(?m)^\s*PvPKompass_UpdateRequested\s*=\s*true\b'
}
function Watch-Request {
    if (-not $config.saved_variables) { throw 'Bitte unter Menuepunkt 1 die SavedVariables-Datei eintragen.' }
    Write-Host 'Ueberwachung aktiv. Ingame Daten aktualisieren klicken und WoW vollstaendig beenden.' -ForegroundColor Green
    Write-Host 'M = zurueck zum Menue. Ohne Tastaturkonsole: Strg+C.'
    $lastAttempt = ''
    $waiting = $false
    while ($true) {
        if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected -and [Console]::KeyAvailable) {
            if ([Console]::ReadKey($true).Key -eq [ConsoleKey]::M) { return }
        }
        if (Has-Request) {
            if (Is-WowRunning) {
                if (-not $waiting) { Write-Host 'Anforderung erkannt; warte, bis WoW beendet wurde.'; $waiting = $true }
            } else {
                $waiting = $false
                $stamp = (Get-Item -LiteralPath $config.saved_variables).LastWriteTimeUtc.Ticks.ToString()
                if ($stamp -ne $lastAttempt) {
                    $lastAttempt = $stamp
                    try { Update-Addon } catch { Write-Host "Update fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red; Write-Host 'Zum erneuten Versuch Menuepunkt 2 verwenden oder neue Ingame-Anforderung speichern.' }
                }
            }
        }
        Start-Sleep -Seconds 3
    }
}
Write-Host 'PvP-Kompass - Client-Updater 0.6.0' -ForegroundColor Cyan
Write-Host "Pfade werden dauerhaft gespeichert: $configPath"
if (-not $config.addon_dir) { Configure }
while ($true) {
    Write-Host ''
    Write-Host "Addon: $($config.addon_dir)"
    Write-Host "SavedVariables: $($config.saved_variables)"
    Write-Host '1 = Pfade aendern | 2 = Jetzt aktualisieren | 3 = Ingame-Button ueberwachen | 4 = Beenden'
    $choice = Read-Host 'Auswahl'
    try {
        switch ($choice) {
            '1' { Configure }
            '2' { Update-Addon }
            '3' { Watch-Request }
            '4' { Save-Settings; return }
            default { Write-Host 'Bitte 1, 2, 3 oder 4 eingeben.' }
        }
    } catch { Write-Host "FEHLER: $($_.Exception.Message)" -ForegroundColor Red }
}
