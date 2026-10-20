[CmdletBinding()]
param(
    [Uri]$ManifestUrl = 'https://raw.githubusercontent.com/karachokalle/pvp-kompass-wow-forever/main/update-manifest.json',

    [Parameter(Mandatory = $true)]
    [string]$WowRoot,

    [string]$AddonDirectory = (Join-Path $WowRoot 'Interface\AddOns\PvPKompass'),

    [string]$SavedVariablesPath,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Assert-HttpsUri {
    param([Uri]$Value, [string]$Label)
    if (-not $Value.IsAbsoluteUri -or $Value.Scheme -ne 'https') {
        throw "$Label muss eine absolute HTTPS-Adresse sein."
    }
}

Assert-HttpsUri -Value $ManifestUrl -Label 'ManifestUrl'

if (Get-Process -Name 'Wow','WowClassic','WowB','WowT' -ErrorAction SilentlyContinue) {
    throw 'Bitte World of Warcraft vollständig schließen, bevor der Updater Dateien und SavedVariables ändert.'
}

$wowRootPath = [IO.Path]::GetFullPath($WowRoot)
$addonPath = [IO.Path]::GetFullPath($AddonDirectory)
$accountSavedVariables = Join-Path $wowRootPath 'WTF\Account'
$requestFiles = @()
if ($SavedVariablesPath) {
    if ([IO.Path]::GetFileName($SavedVariablesPath) -ne 'PvPKompass.lua') { throw 'SavedVariables muss die Datei PvPKompass.lua sein.' }
    if (Test-Path -LiteralPath $SavedVariablesPath -PathType Leaf) {
        $requestFiles = @(Get-Item -LiteralPath $SavedVariablesPath | Where-Object {
            ([IO.File]::ReadAllText($_.FullName)) -match '(?m)^\s*PvPKompass_UpdateRequested\s*=\s*true\b'
        })
    }
} elseif (Test-Path -LiteralPath $accountSavedVariables) {
    $savedVariablePattern = Join-Path $accountSavedVariables '*\SavedVariables\PvPKompass.lua'
    $requestFiles = @(Get-ChildItem -Path $savedVariablePattern -File -ErrorAction SilentlyContinue | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw) -match '(?m)^\s*PvPKompass_UpdateRequested\s*=\s*true\b'
    })
}

if ($requestFiles.Count -eq 0 -and -not $Force) {
    Write-Host 'Kein Update vorgemerkt. Klicke im Addon auf „Daten aktualisieren“ oder starte mit -Force.'
    return
}

if (-not (Test-Path -LiteralPath $addonPath -PathType Container)) {
    throw "Addon-Ordner nicht gefunden: $addonPath. Übergib den Installationspfad mit -AddonDirectory."
}

Write-Host "Lese Update-Manifest: $ManifestUrl"
$manifestResponse = Invoke-WebRequest -Uri $ManifestUrl -TimeoutSec 30 -UseBasicParsing
$manifest = $manifestResponse.Content | ConvertFrom-Json
if ($manifest.addon -ne 'PvPKompass') {
    throw 'Das Manifest gehört nicht zum Addon PvPKompass.'
}

$allowed = @('Data.lua','VendorData.lua','Vendors.lua','PvPKompass.lua','PvPKompass.toc')
if (-not $manifest.files.'Data.lua') { throw 'Das Manifest benötigt files.Data.lua.' }
$entries = @($manifest.files.PSObject.Properties)
foreach ($entry in $entries) {
    if ($entry.Name -cnotin $allowed) { throw "Nicht erlaubte Update-Datei: $($entry.Name)" }
    Assert-HttpsUri -Value ([Uri]$entry.Value.url) -Label $entry.Name
    if ($entry.Value.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw "Ungültige SHA-256-Prüfsumme: $($entry.Name)" }
}
$downloads = @{}
$changed = @()
$written = @()
$existed = @{}
$backupPath = Join-Path $addonPath ('Backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
$lockStream = $null
try {
    $lockStream = [IO.File]::Open((Join-Path $addonPath '.pvpk-update.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::Write, [IO.FileShare]::None)
    Write-Host "Prüfe Addon-Paket v$($manifest.version) ..."
    foreach ($entry in $entries) {
        $name = $entry.Name
        $downloadPath = Join-Path $addonPath ($name + '.download-' + [guid]::NewGuid().ToString('N'))
        $downloads[$name] = $downloadPath
        Invoke-WebRequest -Uri ([Uri]$entry.Value.url) -OutFile $downloadPath -TimeoutSec 60 -UseBasicParsing
        if ((Get-Item -LiteralPath $downloadPath).Length -gt 2MB) { throw "$name überschreitet das Größenlimit von 2 MB." }
        $actualHash = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne ([string]$entry.Value.sha256).ToLowerInvariant()) { throw "SHA-256 stimmt nicht überein: $name. Es wurde keine Datei installiert." }
        if ($name -eq 'Data.lua' -and [IO.File]::ReadAllText($downloadPath) -notmatch '(?m)^\s*PvPKompassData\s*=\s*\{') { throw 'Ungültige Data.lua.' }
        $targetPath = Join-Path $addonPath $name
        $existed[$name] = Test-Path -LiteralPath $targetPath -PathType Leaf
        if (-not $existed[$name] -or (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $actualHash) { $changed += $name }
    }
    if (Get-Process -Name 'Wow','WowClassic','WowB','WowT' -ErrorAction SilentlyContinue) { throw 'WoW wurde während des Downloads gestartet. Bitte schließen und erneut versuchen.' }
    if ($changed.Count) {
        New-Item -ItemType Directory -Path $backupPath | Out-Null
        foreach ($name in $changed) {
            if ($existed[$name]) { Copy-Item -LiteralPath (Join-Path $addonPath $name) -Destination (Join-Path $backupPath $name) }
        }
        try {
            foreach ($name in $changed) {
                $written += $name
                Copy-Item -LiteralPath $downloads[$name] -Destination (Join-Path $addonPath $name) -Force
            }
        } catch {
            $installError = $_
            foreach ($name in $written) {
                $targetPath = Join-Path $addonPath $name
                try {
                    if ($existed[$name]) { Copy-Item -LiteralPath (Join-Path $backupPath $name) -Destination $targetPath -Force }
                    elseif (Test-Path -LiteralPath $targetPath) { Remove-Item -LiteralPath $targetPath -Force }
                } catch { Write-Warning "Wiederherstellen fehlgeschlagen: $name. Sicherung: $backupPath" }
            }
            throw $installError
        }
        Write-Host "$($changed.Count) Addon-Dateien aktualisiert. Sicherung: $backupPath"
    } else {
        Write-Host 'Alle Addon-Dateien sind bereits aktuell.'
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($requestFile in $requestFiles) {
        try {
            $savedText = [IO.File]::ReadAllText($requestFile.FullName)
            $savedText = [regex]::Replace($savedText, '(?m)^(\s*PvPKompass_UpdateRequested\s*=\s*)true\b', '$1false')
            [IO.File]::WriteAllText($requestFile.FullName, $savedText, $utf8NoBom)
        } catch { Write-Warning 'Addon aktualisiert, aber die Update-Anforderung konnte nicht zurückgesetzt werden.' }
    }
    Write-Host "PvP-Kompass v$($manifest.version) · Stand $($manifest.updated). WoW kann jetzt gestartet werden."
}
finally {
    foreach ($path in $downloads.Values) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force } }
    if ($lockStream) { $lockStream.Dispose() }
}
