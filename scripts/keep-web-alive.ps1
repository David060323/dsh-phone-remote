<#
.SYNOPSIS
  Guardian loop for a `dsh web` host: restart it when it dies, never start a second copy.

.DESCRIPTION
  Intended to be launched by a logon scheduled task (register-web-guardian.ps1).
  It polls the listening port; when nothing serves it, it starts the configured
  command line and waits for it to exit, then retries after RetrySeconds.

  Logs:
    web-host.log       guardian decisions
    web-host.out.log   host stdout
    web-host.err.log   host stderr

.PARAMETER CommandLine
  Command that starts the host. Default: "dsh web --no-open".

.PARAMETER Port
  Port the host is expected to listen on. Default: 3080.

.PARAMETER WorkDir
  Working directory for the host (a DSH workspace). Default: current directory.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File .\keep-web-alive.ps1 -WorkDir D:\work
#>
param(
  [string]$CommandLine = 'dsh web --no-open',
  [int]$Port = 3080,
  [int]$RetrySeconds = 15,
  [string]$WorkDir = (Get-Location).Path
)

$ErrorActionPreference = 'Continue'

$Out = Join-Path $PSScriptRoot 'web-host.log'
$StdOut = Join-Path $PSScriptRoot 'web-host.out.log'
$StdErr = Join-Path $PSScriptRoot 'web-host.err.log'

function Write-Log {
  param([string]$Message)
  $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  Add-Content -Path $Out -Value $line -Encoding utf8
}

Write-Log "guardian started (pid $PID); supervising port $Port with '$CommandLine'"
Set-Location -LiteralPath $WorkDir

while ($true) {
  $listening = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
  if ($listening) {
    Start-Sleep -Seconds 30
    continue
  }

  Write-Log "port $Port is free -> starting host"
  try {
    # cmd.exe resolves dsh.cmd/dsh.exe from PATH and handles arguments; the host
    # process keeps running until it exits (or the machine reboots).
    $proc = Start-Process -FilePath "$env:WINDIR\System32\cmd.exe" `
      -ArgumentList '/c', $CommandLine `
      -NoNewWindow -PassThru -Wait `
      -RedirectStandardOutput $StdOut -RedirectStandardError $StdErr
    Write-Log "host exited with code $($proc.ExitCode)"
  }
  catch {
    Write-Log "launch failed: $($_.Exception.Message)"
  }

  Write-Log "restarting in $RetrySeconds s"
  Start-Sleep -Seconds $RetrySeconds
}
