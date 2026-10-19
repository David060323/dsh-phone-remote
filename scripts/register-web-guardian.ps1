<#
.SYNOPSIS
  Register (or remove) the logon scheduled task that runs the `dsh web` guardian loop.

.DESCRIPTION
  Task triggers: at logon.
  Action: wscript.exe run-hidden.vbs keep-web-alive.ps1 (no console flash).
  The guardian script itself keeps the host alive, so one logon trigger is enough.

.PARAMETER TaskName
  Scheduled task name. Default: "DSH Phone Host".

.PARAMETER WorkDir
  Working directory passed to the guardian (a DSH workspace). Default: current directory.

.PARAMETER Port
  Host port the guardian supervises. Default: 3080.

.PARAMETER Unregister
  Remove the task instead of registering it.
#>
param(
  [string]$TaskName = 'DSH Phone Host',
  [string]$WorkDir = (Get-Location).Path,
  [int]$Port = 3080,
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
$worker = Join-Path $PSScriptRoot 'keep-web-alive.ps1'
foreach ($path in @($vbs, $worker)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "missing file: $path" }
}

$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\wscript.exe" `
  -Argument ('"{0}" keep-web-alive.ps1 -Port {1} -WorkDir "{2}"' -f $vbs, $Port, $WorkDir) `
  -WorkingDirectory $PSScriptRoot
$logon = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero)
$settings.DisallowStartIfOnBatteries = $false
$settings.StopIfGoingOnBatteries = $false

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $logon -Settings $settings `
  -User "$env:USERDOMAIN\$env:USERNAME" -RunLevel Limited `
  -Description 'Starts and keeps the dsh web host alive for phone remote access.' -Force | Out-Null

$task = Get-ScheduledTask -TaskName $TaskName
Write-Host "Registered scheduled task: $($task.TaskName)  state=$($task.State)"
Write-Host "Logs: $PSScriptRoot\web-host.log"
Write-Host "Remove: .\register-web-guardian.ps1 -Unregister"
