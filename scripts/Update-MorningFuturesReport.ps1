param(
    [string]$ConfigPath = "",
    [switch]$SendNotifications,
    [switch]$UseSampleData
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\MorningFutures.ps1")

$projectRoot = Get-ProjectRoot
$dataPath = Join-Path $projectRoot "data\latest-report.json"

if ($UseSampleData) {
    $samplePath = Join-Path $projectRoot "data\sample-report.json"
    if (-not (Test-Path -LiteralPath $samplePath)) {
        throw "Sample report file was not found at $samplePath"
    }

    Ensure-Directory -Path (Split-Path -Parent $dataPath)
    Copy-Item -LiteralPath $samplePath -Destination $dataPath -Force
    Write-Host "Copied sample report to $dataPath"
    exit 0
}

$config = Get-MorningFuturesConfig -ConfigPath $ConfigPath
$report = New-MorningFuturesReport -Config $config
$outputPath = Save-MorningFuturesReport -Report $report -OutputPath $dataPath

Write-Host ("Saved Morning Futures report to {0}" -f $outputPath)

if ($SendNotifications) {
    Send-MorningFuturesNotifications -Config $config -Report $report
    Write-Host "Notification dispatch completed."
}

