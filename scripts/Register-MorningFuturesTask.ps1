param(
    [string]$RunAt = "08:30",
    [string]$TaskName = "Morning Futures Daily Briefing",
    [string]$ConfigPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\MorningFutures.ps1")

$projectRoot = Get-ProjectRoot
$scriptPath = Join-Path $PSScriptRoot "Update-MorningFuturesReport.ps1"
$resolvedConfig = $ConfigPath
if (-not $resolvedConfig) {
    $resolvedConfig = Join-Path $projectRoot "config.json"
}

$arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -ConfigPath "{1}" -SendNotifications' -f $scriptPath, $resolvedConfig
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments
$trigger = New-ScheduledTaskTrigger -Daily -At ([DateTime]::ParseExact($RunAt, "HH:mm", $null))
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description "Generate the Morning Futures crypto watchlist briefing each morning." -Force | Out-Null

Write-Host ("Registered task '{0}' for {1} local time." -f $TaskName, $RunAt)

