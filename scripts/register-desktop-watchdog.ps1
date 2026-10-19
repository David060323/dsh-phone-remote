<#
.SYNOPSIS
  Register (or remove) the scheduled task that keeps the desktop app available for the phone.

.DESCRIPTION
  Task triggers:
    - at logon
    - every N minutes (default 1) forever
  Action: wscript.exe run-hidden.vbs keep-desktop-alive.ps1 (no console flash).

.PARAMETER TaskName
  Scheduled task name. Default: "DSH Phone Always-On".

.PARAMETER IntervalMinutes
  Self-heal check interval. Default 1 minute.

.PARAMETER Unregister
  Remove the task instead of registering it.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\register-desktop-watchdog.ps1

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\register-desktop-watchdog.ps1 -Unregister
#>
param(
  [string]$TaskName = 'DSH Phone Always-On',
  [int]$IntervalMinutes = 1,
  [switch]$Unregister
)

$ErrorActionPreference = 'Stop'

$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($Unregister) {
  if ($existing) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "Removed scheduled task: $TaskName"
  } else {
    Write-Host "Scheduled task not found: $TaskName"
  }
  return
}

$vbs = Join-Path $PSScriptRoot 'run-hidden.vbs'
$worker = Join-Path $PSScriptRoot 'keep-desktop-alive.ps1'
foreach ($path in @($vbs, $worker)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "missing file: $path" }
}

$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\wscript.exe" -Argument ('"{0}" keep-desktop-alive.ps1' -f $vbs)
$logon = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$repeat = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes($IntervalMinutes)) `
  -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
  -RepetitionDuration (New-TimeSpan -Days 3650)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
$settings.DisallowStartIfOnBatteries = $false
$settings.StopIfGoingOnBatteries = $false

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger @($logon, $repeat) -Settings $settings `
  -User "$env:USERDOMAIN\$env:USERNAME" -RunLevel Limited `
  -Description 'Keeps the DeepSeek Harness desktop app running so the phone remote entry stays online.' -Force | Out-Null

$task = Get-ScheduledTask -TaskName $TaskName
Write-Host "Registered scheduled task: $($task.TaskName)  state=$($task.State)  interval=${IntervalMinutes}m"
Write-Host "Check now:  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "Remove:     .\register-desktop-watchdog.ps1 -Unregister"
