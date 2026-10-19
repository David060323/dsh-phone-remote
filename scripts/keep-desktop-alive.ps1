<#
.SYNOPSIS
  Keep the DeepSeek Harness desktop app running so the phone remote entry stays online.

.DESCRIPTION
  Runs from a scheduled task (see register-desktop-watchdog.ps1). When the app is
  already running (including hidden to the system tray) this script exits silently.
  When it is missing it starts the app again; the remote-access plugin reconnects its
  tunnel on boot, so the phone keeps the same URL and pairing.

.NOTES
  Log: keep-alive.log next to this script (only written when the app is actually started).
#>
param(
  [string]$ExePath = "$env:LOCALAPPDATA\Programs\DeepSeek Harness\DeepSeek Harness.exe",
  [string]$ProcessName = 'DeepSeek Harness'
)

$ErrorActionPreference = 'SilentlyContinue'
$Log = Join-Path $PSScriptRoot 'keep-alive.log'

function Write-Log {
  param([string]$Message)
  $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  Add-Content -Path $Log -Value $line -Encoding utf8
}

if (-not (Test-Path -LiteralPath $ExePath)) {
  Write-Log "FATAL: executable not found: $ExePath"
  exit 1
}

# The Electron app spawns several processes; any of them means the app is up.
$running = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
if ($running.Count -gt 0) { exit 0 }

Write-Log 'desktop app not running -> starting it'
try {
  Start-Process -FilePath $ExePath
  exit 0
}
catch {
  Write-Log "start failed: $($_.Exception.Message)"
  exit 1
}
