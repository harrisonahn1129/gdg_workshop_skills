# Checks for, installs, or opens the Antigravity 2.0 desktop app on Windows.
# The 2.0 desktop app is NOT the separate "Antigravity IDE"; only the former counts as installed.
#
# Usage: powershell -ExecutionPolicy Bypass -File antigravity.ps1 check|install|open
# Output: INSTALLED=yes|no, APP_PATH=..., VERSION=..., PLATFORM=..., STATUS=...
param([ValidateSet('check', 'install', 'open')][string]$Mode = 'check')
$ErrorActionPreference = 'Stop'

$DownloadPage = 'https://antigravity.google/download'
# Fallback if the download page can't be parsed (last verified 2026-10-20).
$FallbackBase = 'https://storage.googleapis.com/antigravity-public/antigravity-hub/2.24.0-5780333019398144'

$arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { 'arm' } else { 'x64' }
$suffix = if ($arch -eq 'arm') { 'windows-arm/Antigravity-arm64.exe' } else { 'windows-x64/Antigravity-x64.exe' }

function Get-InstallerUrl {
    try {
        $html = (Invoke-WebRequest -Uri $DownloadPage -UseBasicParsing).Content
        $pattern = 'https://storage\.googleapis\.com/antigravity-public/antigravity-hub/[0-9][^"''\\ ]*/' + [regex]::Escape($suffix)
        $urls = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Value } | Sort-Object -Unique
        if ($urls) { return ($urls | Select-Object -Last 1) }
    } catch { }
    return "$FallbackBase/$suffix"
}

function Get-AntigravityInstall {
    $keys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match '^(Google )?Antigravity' -and $_.DisplayName -notmatch 'IDE' } |
        Select-Object -First 1
}

function Get-AppExe($entry) {
    $candidates = @()
    if ($entry -and $entry.DisplayIcon) { $candidates += ($entry.DisplayIcon -split ',')[0].Trim('"') }
    if ($entry -and $entry.InstallLocation) { $candidates += (Join-Path $entry.InstallLocation 'Antigravity.exe') }
    $candidates += (Join-Path $env:LOCALAPPDATA 'Programs\Antigravity\Antigravity.exe')
    $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

function Test-Installed {
    $entry = Get-AntigravityInstall
    [bool]($entry -or (Get-AppExe $entry))
}

function Write-Check {
    "PLATFORM=windows-$arch"
    $entry = Get-AntigravityInstall
    $exe = Get-AppExe $entry
    if ($entry -or $exe) {
        'INSTALLED=yes'
        if ($exe) { "APP_PATH=$exe" }
        if ($entry.DisplayVersion) { "VERSION=$($entry.DisplayVersion)" }
    } else {
        'INSTALLED=no'
    }
}

switch ($Mode) {
    'check' { Write-Check }
    'install' {
        if (Test-Installed) { 'STATUS=already_installed'; Write-Check; break }
        $url = Get-InstallerUrl
        "DOWNLOAD_URL=$url"
        $out = Join-Path $env:TEMP (Split-Path $url -Leaf)
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
        # Runs the normal setup wizard; the user clicks through it.
        Start-Process -FilePath $out -Wait
        if (Test-Installed) { 'STATUS=installed'; Write-Check }
        else { 'STATUS=failed'; exit 1 }
    }
    'open' {
        $exe = Get-AppExe (Get-AntigravityInstall)
        if (-not $exe) { 'STATUS=not_installed'; exit 1 }
        Start-Process -FilePath $exe
        'STATUS=opened'
    }
}
