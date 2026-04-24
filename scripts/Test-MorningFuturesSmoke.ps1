Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\MorningFutures.ps1")

$bullish = New-ScoreFromMetrics `
    -Change3hPct 1.9 `
    -Change6hPct 3.8 `
    -Change24hPct 7.2 `
    -TrendWinRate 0.025 `
    -VolumeRatio 1.6 `
    -FundingRatePct -0.015 `
    -VolatilityPct 2.3 `
    -MarketRegimeScore 0.4 `
    -BollingerPosition 0.82 `
    -BollingerBasisSlopePct 0.44 `
    -BollingerWidthRatio 1.28

if ($bullish.LongScore -le $bullish.ShortScore) {
    throw "Bullish fixture did not produce a stronger long score."
}

if ($bullish.BollingerContribution -le 0) {
    throw "Bullish fixture did not produce a positive Bollinger contribution."
}

$bearish = New-ScoreFromMetrics `
    -Change3hPct -1.4 `
    -Change6hPct -3.1 `
    -Change24hPct -6.4 `
    -TrendWinRate -0.022 `
    -VolumeRatio 1.5 `
    -FundingRatePct 0.018 `
    -VolatilityPct 2.1 `
    -MarketRegimeScore -0.35 `
    -BollingerPosition -0.76 `
    -BollingerBasisSlopePct -0.37 `
    -BollingerWidthRatio 1.22

if ($bearish.ShortScore -le $bearish.LongScore) {
    throw "Bearish fixture did not produce a stronger short score."
}

if ($bearish.BollingerContribution -ge 0) {
    throw "Bearish fixture did not produce a negative Bollinger contribution."
}

Write-Host "Smoke tests passed."
