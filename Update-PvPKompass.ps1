[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Uri]$ManifestUrl,

    [Parameter(Mandatory = $true)]
    [string]$WowRoot,

    [string]$AddonDirectory = (Join-Path $WowRoot 'Interface\AddOns\PvPKompass'),

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

if (Get-Process -Name 'Wow' -ErrorAction SilentlyContinue) {
    throw 'Bitte World of Warcraft vollständig schließen, bevor der Updater Dateien und SavedVariables ändert.'
}

$wowRootPath = [IO.Path]::GetFullPath($WowRoot)
$addonPath = [IO.Path]::GetFullPath($AddonDirectory)
$accountSavedVariables = Join-Path $wowRootPath 'WTF\Account'
$requestFiles = @()
if (Test-Path -LiteralPath $accountSavedVariables) {
    $savedVariablePattern = Join-Path $accountSavedVariables '*\SavedVariables\PvPKompass.lua'
    $requestFiles = @(Get-ChildItem -Path $savedVariablePattern -File -ErrorAction SilentlyContinue | Where-Object {
        (Get-Content -LiteralPath $_.FullName -Raw) -match '(?m)^\s*PvPKompass_UpdateRequested\s*=\s*true\b'
    })
}

if ($requestFiles.Count -eq 0 -and -not $Force) {
    Write-Host 'Kein Update vorgemerkt. Klicke im Addon auf „Daten aktualisieren“ oder starte mit -Force.'
    exit 0
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

$dataFile = $manifest.files.'Data.lua'
if (-not $dataFile -or -not $dataFile.url -or -not $dataFile.sha256) {
    throw 'Das Manifest benötigt files.Data.lua.url und files.Data.lua.sha256.'
}
$dataUri = [Uri]$dataFile.url
Assert-HttpsUri -Value $dataUri -Label 'Data.lua URL'
if ($dataFile.sha256 -notmatch '^[a-fA-F0-9]{64}$') {
    throw 'Der SHA-256-Prüfwert für Data.lua ist ungültig.'
}

$downloadPath = Join-Path $addonPath 'Data.lua.download'
$targetPath = Join-Path $addonPath 'Data.lua'
$backupPath = Join-Path $addonPath 'Data.lua.previous'
try {
    Write-Host "Lade Datenpaket v$($manifest.version) herunter …"
    Invoke-WebRequest -Uri $dataUri -OutFile $downloadPath -TimeoutSec 60 -UseBasicParsing
    $downloadInfo = Get-Item -LiteralPath $downloadPath
    if ($downloadInfo.Length -gt 2MB) { throw 'Data.lua ist größer als das erlaubte Limit von 2 MB.' }

    $actualHash = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $expectedHash = ([string]$dataFile.sha256).ToLowerInvariant()
    if ($actualHash -ne $expectedHash) {
        throw "SHA-256 stimmt nicht überein. Erwartet: $expectedHash, erhalten: $actualHash. Die vorhandene Datei bleibt unverändert."
    }

    $downloadText = [IO.File]::ReadAllText($downloadPath)
    if ($downloadText -notmatch '(?m)^\s*PvPKompassData\s*=\s*\{') {
        throw 'Die heruntergeladene Datei enthält keine PvPKompassData-Tabelle.'
    }

    Copy-Item -LiteralPath $targetPath -Destination $backupPath -Force
    Move-Item -LiteralPath $downloadPath -Destination $targetPath -Force

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($requestFile in $requestFiles) {
        $savedText = [IO.File]::ReadAllText($requestFile.FullName)
        $savedText = [regex]::Replace($savedText, '(?m)^(\s*PvPKompass_UpdateRequested\s*=\s*)true\b', '$1false')
        [IO.File]::WriteAllText($requestFile.FullName, $savedText, $utf8NoBom)
    }

    Write-Host "PvP-Kompass-Daten wurden aktualisiert: v$($manifest.version) · Stand $($manifest.updated)"
    Write-Host "Backup: $backupPath"
    Write-Host 'Starte WoW und verwende /reload, damit das Addon die neuen Daten lädt.'
    if ($manifest.wowheadSources) {
        Write-Host 'Verwendete Wowhead-Quellen:'
        foreach ($source in $manifest.wowheadSources) { Write-Host " - $($source.title): $($source.url)" }
    }
}
finally {
    if (Test-Path -LiteralPath $downloadPath) { Remove-Item -LiteralPath $downloadPath -Force }
}
