param(
    [ValidateSet("Quick", "Standard", "Full")]
    [string]$Mode = "Standard",
    [string]$ConfigPath = "",
    [string]$OutputRoot = "",
    [double]$MinProfitFactor = 1.5,
    [double]$MaxDrawdownPct = 35,
    [int]$MinTrades = 20,
    [double]$MinWinRatePct = 45,
    [double]$MinSignalsPerDay = 0.3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\MorningFutures.ps1")

if ($Mode -eq "Quick" -and -not $PSBoundParameters.ContainsKey("MinTrades")) {
    $MinTrades = 1
}

function New-HarnessRunConfig {
    param(
        [int]$Days,
        [int]$MaxSymbols,
        [int]$Leverage,
        [int]$HoldHours
    )

    return [pscustomobject]@{
        days = $Days
        maxSymbols = $MaxSymbols
        leverage = $Leverage
        holdHours = $HoldHours
    }
}

function Get-HarnessRunConfigs {
    param(
        [string]$Mode
    )

    if ($Mode -eq "Quick") {
        return @(
            New-HarnessRunConfig -Days 3 -MaxSymbols 3 -Leverage 10 -HoldHours 6
        )
    }

    if ($Mode -eq "Full") {
        return @(
            New-HarnessRunConfig -Days 30 -MaxSymbols 5 -Leverage 10 -HoldHours 6
            New-HarnessRunConfig -Days 30 -MaxSymbols 8 -Leverage 10 -HoldHours 6
            New-HarnessRunConfig -Days 60 -MaxSymbols 5 -Leverage 10 -HoldHours 6
            New-HarnessRunConfig -Days 60 -MaxSymbols 8 -Leverage 10 -HoldHours 6
            New-HarnessRunConfig -Days 90 -MaxSymbols 5 -Leverage 10 -HoldHours 6
        )
    }

    return @(
        New-HarnessRunConfig -Days 30 -MaxSymbols 5 -Leverage 10 -HoldHours 6
        New-HarnessRunConfig -Days 30 -MaxSymbols 8 -Leverage 10 -HoldHours 6
        New-HarnessRunConfig -Days 60 -MaxSymbols 5 -Leverage 10 -HoldHours 6
    )
}

function Test-HarnessPass {
    param(
        [pscustomobject]$Summary,
        [int]$Days,
        [double]$MinProfitFactor,
        [double]$MaxDrawdownPct,
        [int]$MinTrades,
        [double]$MinWinRatePct,
        [double]$MinSignalsPerDay
    )

    $signalsPerDay = if ($Days -gt 0) { [double]$Summary.trades / [double]$Days } else { 0 }
    $failures = New-Object System.Collections.Generic.List[string]

    if ([int]$Summary.trades -lt $MinTrades) {
        $failures.Add("trades < $MinTrades")
    }
    if ([double]$Summary.winRatePct -lt $MinWinRatePct) {
        $failures.Add("winRate < $MinWinRatePct")
    }
    if ([double]$Summary.profitFactor -lt $MinProfitFactor) {
        $failures.Add("profitFactor < $MinProfitFactor")
    }
    if ([double]$Summary.maxDrawdownPct -gt $MaxDrawdownPct) {
        $failures.Add("maxDrawdown > $MaxDrawdownPct")
    }
    if ($signalsPerDay -lt $MinSignalsPerDay) {
        $failures.Add("signalsPerDay < $MinSignalsPerDay")
    }

    return [pscustomobject]@{
        passed = ($failures.Count -eq 0)
        failures = @($failures)
        signalsPerDay = [Math]::Round($signalsPerDay, 3)
    }
}

$projectRoot = Get-ProjectRoot
if (-not $OutputRoot) {
    $OutputRoot = Join-Path $projectRoot "data\harness"
}
$runRoot = Join-Path $OutputRoot "runs"
Ensure-Directory -Path $runRoot
Ensure-Directory -Path $OutputRoot

$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$backtestScript = Join-Path $PSScriptRoot "Backtest-MorningFutures.ps1"
$runConfigs = @(Get-HarnessRunConfigs -Mode $Mode)
$rows = New-Object System.Collections.Generic.List[object]

Write-Host ("Morning Futures harness mode: {0}" -f $Mode)
Write-Host ("Runs: {0}" -f $runConfigs.Count)
Write-Host ("Pass criteria: PF >= {0}, MDD <= {1}%, trades >= {2}, winRate >= {3}%, signals/day >= {4}" -f $MinProfitFactor, $MaxDrawdownPct, $MinTrades, $MinWinRatePct, $MinSignalsPerDay)

for ($index = 0; $index -lt $runConfigs.Count; $index++) {
    $config = $runConfigs[$index]
    $name = "run-{0}-{1:D2}-d{2}-s{3}-l{4}-h{5}" -f $runId, ($index + 1), $config.days, $config.maxSymbols, $config.leverage, $config.holdHours
    $outputPath = Join-Path $runRoot "$name.json"

    Write-Host ""
    Write-Host ("[{0}/{1}] Days={2}, MaxSymbols={3}, Leverage={4}, HoldHours={5}" -f ($index + 1), $runConfigs.Count, $config.days, $config.maxSymbols, $config.leverage, $config.holdHours)

    try {
        $arguments = @{
            Days = $config.days
            MaxSymbols = $config.maxSymbols
            Leverage = $config.leverage
            HoldHours = $config.holdHours
            OutputPath = $outputPath
        }
        if ($ConfigPath) {
            $arguments.ConfigPath = $ConfigPath
        }

        & $backtestScript @arguments
        $result = Get-Content -Raw -Path $outputPath | ConvertFrom-Json
        $pass = Test-HarnessPass `
            -Summary $result.summary `
            -Days $config.days `
            -MinProfitFactor $MinProfitFactor `
            -MaxDrawdownPct $MaxDrawdownPct `
            -MinTrades $MinTrades `
            -MinWinRatePct $MinWinRatePct `
            -MinSignalsPerDay $MinSignalsPerDay

        $rows.Add([pscustomobject]@{
            runId = $runId
            mode = $Mode
            status = if ($pass.passed) { "PASS" } else { "FAIL" }
            failures = (@($pass.failures) -join "; ")
            days = $config.days
            maxSymbols = $config.maxSymbols
            leverage = $config.leverage
            holdHours = $config.holdHours
            trades = [int]$result.summary.trades
            signalsPerDay = $pass.signalsPerDay
            winRatePct = [double]$result.summary.winRatePct
            averageReturnPct = [double]$result.summary.averageReturnPct
            totalReturnPct = [double]$result.summary.totalReturnPct
            profitFactor = [double]$result.summary.profitFactor
            maxDrawdownPct = [double]$result.summary.maxDrawdownPct
            liquiditySweepTrades = [int]$result.liquiditySweep.trades
            liquiditySweepWinRatePct = [double]$result.liquiditySweep.winRatePct
            liquiditySweepProfitFactor = [double]$result.liquiditySweep.profitFactor
            liquidityAlignedTrades = [int]$result.liquidityAligned.trades
            liquidityAlignedWinRatePct = [double]$result.liquidityAligned.winRatePct
            liquidityAlignedProfitFactor = [double]$result.liquidityAligned.profitFactor
            jsonPath = $outputPath
            csvPath = [System.IO.Path]::ChangeExtension($outputPath, ".csv")
        })
    }
    catch {
        $rows.Add([pscustomobject]@{
            runId = $runId
            mode = $Mode
            status = "ERROR"
            failures = $_.Exception.Message
            days = $config.days
            maxSymbols = $config.maxSymbols
            leverage = $config.leverage
            holdHours = $config.holdHours
            trades = 0
            signalsPerDay = 0
            winRatePct = 0
            averageReturnPct = 0
            totalReturnPct = 0
            profitFactor = 0
            maxDrawdownPct = 0
            liquiditySweepTrades = 0
            liquiditySweepWinRatePct = 0
            liquiditySweepProfitFactor = 0
            liquidityAlignedTrades = 0
            liquidityAlignedWinRatePct = 0
            liquidityAlignedProfitFactor = 0
            jsonPath = $outputPath
            csvPath = [System.IO.Path]::ChangeExtension($outputPath, ".csv")
        })
        Write-Warning ("Harness run failed: {0}" -f $_.Exception.Message)
    }
}

$rowItems = @($rows.ToArray())
$summary = [pscustomobject]@{
    generatedAt = (Get-Date).ToString("o")
    runId = $runId
    mode = $Mode
    passCriteria = [pscustomobject]@{
        minProfitFactor = $MinProfitFactor
        maxDrawdownPct = $MaxDrawdownPct
        minTrades = $MinTrades
        minWinRatePct = $MinWinRatePct
        minSignalsPerDay = $MinSignalsPerDay
    }
    totalRuns = $rowItems.Count
    passedRuns = @($rowItems | Where-Object { $_.status -eq "PASS" }).Count
    failedRuns = @($rowItems | Where-Object { $_.status -eq "FAIL" }).Count
    errorRuns = @($rowItems | Where-Object { $_.status -eq "ERROR" }).Count
    runs = $rowItems
}

$latestJsonPath = Join-Path $OutputRoot "latest-summary.json"
$latestCsvPath = Join-Path $OutputRoot "latest-summary.csv"
$timestampedJsonPath = Join-Path $OutputRoot "summary-$runId.json"
$timestampedCsvPath = Join-Path $OutputRoot "summary-$runId.csv"

$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $latestJsonPath -Encoding UTF8
$summary | ConvertTo-Json -Depth 8 | Set-Content -Path $timestampedJsonPath -Encoding UTF8
$rowItems | Export-Csv -Path $latestCsvPath -NoTypeInformation -Encoding UTF8
$rowItems | Export-Csv -Path $timestampedCsvPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Harness summary"
Write-Host ("  Passed: {0}/{1}" -f $summary.passedRuns, $summary.totalRuns)
Write-Host ("  Failed: {0}" -f $summary.failedRuns)
Write-Host ("  Errors: {0}" -f $summary.errorRuns)
Write-Host ("Saved JSON: {0}" -f $latestJsonPath)
Write-Host ("Saved CSV: {0}" -f $latestCsvPath)
