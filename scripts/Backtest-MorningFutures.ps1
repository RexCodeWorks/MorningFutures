param(
    [string]$ConfigPath = "",
    [int]$Days = 30,
    [int]$ScoreThreshold = 0,
    [int]$LongScoreThreshold = 75,
    [int]$ShortScoreThreshold = 78,
    [int]$LongEdgeThreshold = 12,
    [int]$ShortEdgeThreshold = 14,
    [double]$MaxShortMarketRegimeScore = 0.10,
    [int]$Leverage = 10,
    [int]$HoldHours = 6,
    [double]$RoundTripFeePct = 0.10,
    [double]$RoundTripSlippagePct = 0.06,
    [string[]]$Symbols = @(),
    [int]$MaxSymbols = 8,
    [int]$MaxEntriesPerDirection = 0,
    [switch]$AllowOverlappingSignals,
    [string]$OutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\MorningFutures.ps1")

if ($ScoreThreshold -gt 0) {
    $LongScoreThreshold = $ScoreThreshold
    $ShortScoreThreshold = $ScoreThreshold
}

function Get-OkxHistoricalCandles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstId,
        [Parameter(Mandatory = $true)]
        [int]$Hours
    )

    $encodedInstId = [System.Uri]::EscapeDataString($InstId)
    $all = @()
    $after = ""
    $targetCount = $Hours + 80
    $pageLimit = 100
    $seen = @{}

    while ($all.Count -lt $targetCount) {
        $uri = "https://www.okx.com/api/v5/market/history-candles?instId=$encodedInstId&bar=1H&limit=$pageLimit"
        if ($after) {
            $uri += "&after=$after"
        }

        $response = Invoke-ApiJson -Uri $uri
        $rows = @($response.data)
        if ($rows.Count -eq 0) {
            break
        }

        foreach ($row in $rows) {
            $key = [string]$row[0]
            if (-not $seen.ContainsKey($key)) {
                $all += ,$row
                $seen[$key] = $true
            }
        }

        $oldest = ($rows | Sort-Object { [int64]$_[0] } | Select-Object -First 1)
        $nextAfter = [string]$oldest[0]
        if ($nextAfter -eq $after) {
            break
        }
        $after = $nextAfter
        Start-Sleep -Milliseconds 120
    }

    return @(ConvertTo-KlineObjects -Klines $all | Select-Object -Last $Hours)
}

function Get-ChangeFromWindow {
    param(
        [object[]]$Candles,
        [int]$Hours
    )

    $items = @($Candles)
    if ($items.Count -le $Hours) {
        return 0
    }

    return Get-PercentChange -BaseValue ([double]$items[$items.Count - $Hours - 1].Close) -CurrentValue ([double]$items[-1].Close)
}

function Get-BacktestMarketRegimeScore {
    param(
        [hashtable]$WindowsBySymbol
    )

    $changes = @()
    foreach ($key in $WindowsBySymbol.Keys) {
        $window = @($WindowsBySymbol[$key])
        if ($window.Count -gt 25) {
            $changes += Get-ChangeFromWindow -Candles $window -Hours 24
        }
    }

    if ($changes.Count -eq 0) {
        return 0
    }

    $btcChange = if ($WindowsBySymbol.ContainsKey("BTC-USDT-SWAP")) {
        Get-ChangeFromWindow -Candles @($WindowsBySymbol["BTC-USDT-SWAP"]) -Hours 24
    }
    else {
        0
    }
    $ethChange = if ($WindowsBySymbol.ContainsKey("ETH-USDT-SWAP")) {
        Get-ChangeFromWindow -Candles @($WindowsBySymbol["ETH-USDT-SWAP"]) -Hours 24
    }
    else {
        0
    }
    $positiveCount = @($changes | Where-Object { $_ -gt 0 }).Count
    $breadthPct = ($positiveCount / [double]$changes.Count) * 100

    $btcScore = Normalize-Number -Value $btcChange -Scale 8
    $ethScore = Normalize-Number -Value $ethChange -Scale 10
    $breadthScore = Normalize-Number -Value ($breadthPct - 50) -Scale 20

    return (0.35 * $btcScore) + (0.25 * $ethScore) + (0.25 * $breadthScore)
}

function New-BacktestSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Symbol,
        [Parameter(Mandatory = $true)]
        [object[]]$Candles,
        [double]$MarketRegimeScore
    )

    $candles = @($Candles)
    if ($candles.Count -lt [int]$script:RiskFilter.MinimumHistoryCandles) {
        return $null
    }

    $lastPrice = [double]$candles[-1].Close
    $change3hPct = Get-ChangeFromWindow -Candles $candles -Hours 3
    $change6hPct = Get-ChangeFromWindow -Candles $candles -Hours 6
    $change24hPct = Get-ChangeFromWindow -Candles $candles -Hours 24
    $lookbackChangePct = Get-PercentChange -BaseValue ([double]$candles[0].Close) -CurrentValue $lastPrice

    $recentCandles = Get-LastItems -Items $candles -Count 6
    $recent6Closes = @($recentCandles | ForEach-Object { $_.Close })
    $prior6Candles = Get-WindowBeforeTail -Items $candles -TailCount 6 -WindowSize 6
    $prior6Closes = @($prior6Candles | ForEach-Object { $_.Close })
    $recent6Avg = Get-Average -Values $recent6Closes
    $prior6Avg = Get-Average -Values $prior6Closes
    if ($prior6Avg -eq 0) {
        $prior6Avg = 1
    }
    $trendWinRate = Clamp-Number -Value (($recent6Avg - $prior6Avg) / [Math]::Abs($prior6Avg)) -Minimum -1 -Maximum 1

    $baselineCandles = Get-WindowBeforeTail -Items $candles -TailCount 6 -WindowSize 30
    $recentVolume = Get-Average -Values @($recentCandles | ForEach-Object { $_.QuoteVolume })
    $baselineVolume = Get-Average -Values @($baselineCandles | ForEach-Object { $_.QuoteVolume })
    $volumeRatio = if ($baselineVolume -gt 0) { $recentVolume / $baselineVolume } else { 1 }

    $rangeWindow = Get-LastItems -Items $candles -Count 12
    $rangePct = @(
        $rangeWindow | ForEach-Object {
            if ([double]$_.Open -eq 0) {
                0
            }
            else {
                (([double]$_.High - [double]$_.Low) / [double]$_.Open) * 100
            }
        }
    )
    $volatilityPct = Get-Average -Values $rangePct

    $bollingerSeries = Get-BollingerSeries -Candles $candles -Period 20
    if ($bollingerSeries.Count -lt 24) {
        return $null
    }

    $currentBollinger = $bollingerSeries[-1]
    $priorBollingerWidths = Get-WindowBeforeTail -Items $bollingerSeries -TailCount 1 -WindowSize 10
    $averagePriorBandWidthPct = Get-Average -Values @($priorBollingerWidths | ForEach-Object { $_.widthPct })
    $bandWidthRatio = if ($averagePriorBandWidthPct -gt 0) { [double]$currentBollinger.widthPct / $averagePriorBandWidthPct } else { 1 }
    $basisSlopePct = if ($bollingerSeries.Count -ge 6) {
        Get-PercentChange -BaseValue ([double]$bollingerSeries[$bollingerSeries.Count - 6].basis) -CurrentValue ([double]$currentBollinger.basis)
    }
    else {
        0
    }

    $halfBand = (([double]$currentBollinger.upper - [double]$currentBollinger.lower) / 2)
    $bollingerPosition = if ($halfBand -gt 0) {
        Clamp-Number -Value (($lastPrice - [double]$currentBollinger.basis) / $halfBand) -Minimum -1 -Maximum 1
    }
    else {
        0
    }

    $riskProfile = New-RiskProfile `
        -Candles $candles `
        -Change6hPct $change6hPct `
        -Change24hPct $change24hPct `
        -LookbackChangePct $lookbackChangePct `
        -VolatilityPct $volatilityPct `
        -BollingerPosition $bollingerPosition `
        -BandWidthRatio $bandWidthRatio
    $liquiditySignal = New-LiquiditySignal -Candles $candles -Lookback 24

    $scores = New-ScoreFromMetrics `
        -Change3hPct $change3hPct `
        -Change6hPct $change6hPct `
        -Change24hPct $change24hPct `
        -TrendWinRate $trendWinRate `
        -VolumeRatio $volumeRatio `
        -FundingRatePct 0 `
        -VolatilityPct $volatilityPct `
        -MarketRegimeScore $MarketRegimeScore `
        -BollingerPosition $bollingerPosition `
        -BollingerBasisSlopePct $basisSlopePct `
        -BollingerWidthRatio $bandWidthRatio

    return [pscustomobject]@{
        symbol = $Symbol
        lastPrice = [Math]::Round($lastPrice, 6)
        move6hPct = [Math]::Round($change6hPct, 2)
        move24hPct = [Math]::Round($change24hPct, 2)
        lookbackMovePct = [Math]::Round($lookbackChangePct, 2)
        volumeRatio = [Math]::Round($volumeRatio, 2)
        fundingRatePct = 0
        volatilityPct = [Math]::Round($volatilityPct, 2)
        longScore = $scores.LongScore
        shortScore = $scores.ShortScore
        longEdge = $scores.LongEdge
        shortEdge = $scores.ShortEdge
        riskFlags = @($riskProfile.riskFlags)
        riskBlocks = $riskProfile.riskBlocks
        liquiditySignal = $liquiditySignal
    }
}

function Test-TradeOutcome {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Signal,
        [Parameter(Mandatory = $true)]
        [object[]]$FutureCandles,
        [int]$Leverage,
        [double]$CostPct
    )

    $entry = [double]$Signal.entryPrice
    $stop = [double]$Signal.stopLossPrice
    $tp1 = [double]$Signal.takeProfit1Price
    $tp2 = [double]$Signal.takeProfit2Price
    $direction = [string]$Signal.direction
    $exitPrice = [double]$FutureCandles[-1].Close
    $exitReason = "time"
    $barsHeld = @($FutureCandles).Count

    for ($index = 0; $index -lt @($FutureCandles).Count; $index++) {
        $candle = $FutureCandles[$index]
        $high = [double]$candle.High
        $low = [double]$candle.Low

        if ($direction -eq "long") {
            if ($low -le $stop) {
                $exitPrice = $stop
                $exitReason = "stop"
                $barsHeld = $index + 1
                break
            }
            if ($high -ge $tp2) {
                $exitPrice = $tp2
                $exitReason = "tp2"
                $barsHeld = $index + 1
                break
            }
            if ($high -ge $tp1) {
                $exitPrice = $tp1
                $exitReason = "tp1"
                $barsHeld = $index + 1
                break
            }
        }
        else {
            if ($high -ge $stop) {
                $exitPrice = $stop
                $exitReason = "stop"
                $barsHeld = $index + 1
                break
            }
            if ($low -le $tp2) {
                $exitPrice = $tp2
                $exitReason = "tp2"
                $barsHeld = $index + 1
                break
            }
            if ($low -le $tp1) {
                $exitPrice = $tp1
                $exitReason = "tp1"
                $barsHeld = $index + 1
                break
            }
        }
    }

    $rawReturnPct = if ($direction -eq "long") {
        (($exitPrice - $entry) / $entry) * 100
    }
    else {
        (($entry - $exitPrice) / $entry) * 100
    }
    $leveragedReturnPct = ($rawReturnPct * $Leverage) - $CostPct

    return [pscustomobject]@{
        exitPrice = [Math]::Round($exitPrice, 6)
        exitReason = $exitReason
        barsHeld = $barsHeld
        rawReturnPct = [Math]::Round($rawReturnPct, 3)
        leveragedReturnPct = [Math]::Round($leveragedReturnPct, 3)
    }
}

function Get-BacktestSummary {
    param(
        [object[]]$Trades
    )

    $items = @($Trades)
    if ($items.Count -eq 0) {
        return [pscustomobject]@{
            trades = 0
            winRatePct = 0
            averageReturnPct = 0
            totalReturnPct = 0
            profitFactor = 0
            maxDrawdownPct = 0
        }
    }

    $wins = @($items | Where-Object { [double]$_.leveragedReturnPct -gt 0 })
    $grossProfit = if ($wins.Count -gt 0) { [double](($wins | Measure-Object -Property leveragedReturnPct -Sum).Sum) } else { 0.0 }
    $losses = @($items | Where-Object { [double]$_.leveragedReturnPct -lt 0 })
    $grossLoss = if ($losses.Count -gt 0) { [Math]::Abs([double](($losses | Measure-Object -Property leveragedReturnPct -Sum).Sum)) } else { 0.0 }
    $profitFactor = if ($grossLoss -gt 0) { $grossProfit / $grossLoss } else { 0 }

    $equity = 100.0
    $peak = $equity
    $maxDrawdown = 0.0
    foreach ($trade in $items) {
        $equity = $equity * (1 + ([double]$trade.leveragedReturnPct / 100))
        if ($equity -gt $peak) {
            $peak = $equity
        }
        $drawdown = if ($peak -gt 0) { (($peak - $equity) / $peak) * 100 } else { 0 }
        if ($drawdown -gt $maxDrawdown) {
            $maxDrawdown = $drawdown
        }
    }

    return [pscustomobject]@{
        trades = $items.Count
        winRatePct = [Math]::Round(($wins.Count / [double]$items.Count) * 100, 2)
        averageReturnPct = [Math]::Round([double](($items | Measure-Object -Property leveragedReturnPct -Average).Average), 3)
        totalReturnPct = [Math]::Round((($equity / 100) - 1) * 100, 2)
        profitFactor = [Math]::Round($profitFactor, 3)
        maxDrawdownPct = [Math]::Round($maxDrawdown, 2)
    }
}

$projectRoot = Get-ProjectRoot
$config = Get-MorningFuturesConfig -ConfigPath $ConfigPath
if ($MaxEntriesPerDirection -le 0) {
    $MaxEntriesPerDirection = [int]$config.TopPicks
}
$warmupHours = [Math]::Max([int]$config.KlineLookbackHours, [int]$script:RiskFilter.MinimumHistoryCandles)
$requiredHours = $warmupHours + ($Days * 24) + $HoldHours + 4
$symbolsToTest = if ($Symbols.Count -gt 0) {
    @($Symbols | ForEach-Object { ConvertTo-OkxInstId -Symbol $_ })
}
else {
    @($config.PreferredSymbols | Select-Object -First $MaxSymbols | ForEach-Object { ConvertTo-OkxInstId -Symbol $_ })
}

if (-not ($symbolsToTest -contains "BTC-USDT-SWAP")) {
    $symbolsToTest = @("BTC-USDT-SWAP") + $symbolsToTest
}
if (-not ($symbolsToTest -contains "ETH-USDT-SWAP")) {
    $symbolsToTest = @("ETH-USDT-SWAP") + $symbolsToTest
}
$symbolsToTest = @($symbolsToTest | Select-Object -Unique)

Write-Host ("Fetching {0} hourly candles for {1} symbols..." -f $requiredHours, $symbolsToTest.Count)
$candlesBySymbol = @{}
foreach ($symbol in $symbolsToTest) {
    Write-Host ("  {0}" -f $symbol)
    $candles = @(Get-OkxHistoricalCandles -InstId $symbol -Hours $requiredHours)
    if ($candles.Count -lt ($warmupHours + $HoldHours + 2)) {
        Write-Warning ("Skipping {0}: only {1} candles returned." -f $symbol, $candles.Count)
        continue
    }
    $candlesBySymbol[$symbol] = $candles
}

$testSymbols = @($candlesBySymbol.Keys | Where-Object { $_ -ne "BTC-USDT-SWAP" -and $_ -ne "ETH-USDT-SWAP" })
if ($candlesBySymbol.ContainsKey("BTC-USDT-SWAP")) {
    $testSymbols = @("BTC-USDT-SWAP") + $testSymbols
}
if ($candlesBySymbol.ContainsKey("ETH-USDT-SWAP")) {
    $testSymbols = @("ETH-USDT-SWAP") + @($testSymbols | Where-Object { $_ -ne "ETH-USDT-SWAP" })
}

$trades = New-Object System.Collections.Generic.List[object]
$activeUntilByKey = @{}
$startOffset = $warmupHours
$endOffset = ($candlesBySymbol.Values | ForEach-Object { @($_).Count } | Measure-Object -Minimum).Minimum - $HoldHours - 2

for ($offset = $startOffset; $offset -le $endOffset; $offset++) {
    $windowsBySymbol = @{}
    foreach ($symbol in $candlesBySymbol.Keys) {
        $candles = @($candlesBySymbol[$symbol])
        $windowsBySymbol[$symbol] = @($candles[($offset - $warmupHours)..($offset - 1)])
    }

    $marketRegimeScore = Get-BacktestMarketRegimeScore -WindowsBySymbol $windowsBySymbol

    $snapshotsForOffset = @()
    foreach ($symbol in $testSymbols) {
        $window = @($windowsBySymbol[$symbol])
        $snapshot = New-BacktestSnapshot -Symbol $symbol -Candles $window -MarketRegimeScore $marketRegimeScore
        if ($null -eq $snapshot) {
            continue
        }
        $snapshotsForOffset += $snapshot
    }

    $signalsForOffset = @()
    foreach ($direction in @("long", "short")) {
        $directionSignals = @(
            foreach ($snapshot in $snapshotsForOffset) {
                $symbol = [string]$snapshot.symbol
                $score = if ($direction -eq "long") { [double]$snapshot.longScore } else { [double]$snapshot.shortScore }
                $edge = if ($direction -eq "long") { [double]$snapshot.longEdge } else { [double]$snapshot.shortEdge }
                $scoreThresholdForDirection = if ($direction -eq "long") { $LongScoreThreshold } else { $ShortScoreThreshold }
                $edgeThresholdForDirection = if ($direction -eq "long") { $LongEdgeThreshold } else { $ShortEdgeThreshold }
                $blocks = @(if ($direction -eq "long") { $snapshot.riskBlocks.long } else { $snapshot.riskBlocks.short })

                if ($score -lt $scoreThresholdForDirection -or $edge -lt $edgeThresholdForDirection -or @($blocks).Count -gt 0) {
                    continue
                }
                if ($direction -eq "short" -and $marketRegimeScore -gt $MaxShortMarketRegimeScore) {
                    continue
                }

                [pscustomobject]@{
                    symbol = $symbol
                    direction = $direction
                    score = $score
                    edge = $edge
                    snapshot = $snapshot
                }
            }
        )

        if ($direction -eq "long") {
            $signalsForOffset += @(
                $directionSignals |
                Sort-Object @{ Expression = { $_.edge }; Descending = $true }, @{ Expression = { $_.score }; Descending = $true } |
                Select-Object -First $MaxEntriesPerDirection
            )
        }
        else {
            $signalsForOffset += @(
                $directionSignals |
                Sort-Object @{ Expression = { $_.edge }; Descending = $true }, @{ Expression = { $_.score }; Descending = $true } |
                Select-Object -First $MaxEntriesPerDirection
            )
        }
    }

    foreach ($signalCandidate in $signalsForOffset) {
            $symbol = [string]$signalCandidate.symbol
            $direction = [string]$signalCandidate.direction
            $snapshot = $signalCandidate.snapshot
            $candles = @($candlesBySymbol[$symbol])
            $activeKey = "$symbol|$direction"
            if (-not $AllowOverlappingSignals -and $activeUntilByKey.ContainsKey($activeKey) -and $offset -lt [int]$activeUntilByKey[$activeKey]) {
                continue
            }

            $score = [double]$signalCandidate.score
            $edge = [double]$signalCandidate.edge
            $confidence = Clamp-Number -Value (50 + ([Math]::Abs($edge) * 0.7)) -Minimum 50 -Maximum 95
            $plan = New-BeginnerTradePlan -Snapshot $snapshot -Direction $direction -Confidence $confidence
            $futureCandles = @($candles[$offset..($offset + $HoldHours - 1)])
            $signal = [pscustomobject]@{
                direction = $direction
                entryPrice = [double]$futureCandles[0].Open
                stopLossPrice = $plan.stopLossPrice
                takeProfit1Price = $plan.takeProfit1Price
                takeProfit2Price = $plan.takeProfit2Price
            }
            $outcome = Test-TradeOutcome -Signal $signal -FutureCandles $futureCandles -Leverage $Leverage -CostPct ($RoundTripFeePct + $RoundTripSlippagePct)
            if (-not $AllowOverlappingSignals) {
                $activeUntilByKey[$activeKey] = $offset + [int]$outcome.barsHeld
            }

            $trades.Add([pscustomobject]@{
                signalTime = $window[-1].OpenTime.ToString("s")
                entryTime = $futureCandles[0].OpenTime.ToString("s")
                symbol = $symbol
                direction = $direction
                score = [Math]::Round($score, 1)
                edge = [Math]::Round($edge, 1)
                entryPrice = [Math]::Round([double]$signal.entryPrice, 6)
                exitPrice = $outcome.exitPrice
                exitReason = $outcome.exitReason
                barsHeld = $outcome.barsHeld
                rawReturnPct = $outcome.rawReturnPct
                leveragedReturnPct = $outcome.leveragedReturnPct
                move6hPct = $snapshot.move6hPct
                move24hPct = $snapshot.move24hPct
                lookbackMovePct = $snapshot.lookbackMovePct
                volatilityPct = $snapshot.volatilityPct
                marketRegimeScore = [Math]::Round($marketRegimeScore, 3)
                liquiditySignalType = $snapshot.liquiditySignal.type
                liquiditySignalDirection = $snapshot.liquiditySignal.direction
                liquidityAligned = ([string]$snapshot.liquiditySignal.direction -eq $direction)
            })
    }
}

$tradeItems = @($trades.ToArray())
$summary = Get-BacktestSummary -Trades $tradeItems
$byDirection = @(
    foreach ($direction in @("long", "short")) {
        $directionTrades = @($tradeItems | Where-Object { $_.direction -eq $direction })
        $directionSummary = Get-BacktestSummary -Trades $directionTrades
        $directionSummary | Add-Member -NotePropertyName direction -NotePropertyValue $direction -PassThru
    }
)
$byScoreBand = @(
    foreach ($band in @(
        @{ Label = "70-75"; Min = 70; Max = 75 },
        @{ Label = "75-80"; Min = 75; Max = 80 },
        @{ Label = "80+"; Min = 80; Max = 101 }
    )) {
        $bandTrades = @($tradeItems | Where-Object { [double]$_.score -ge $band.Min -and [double]$_.score -lt $band.Max })
        $bandSummary = Get-BacktestSummary -Trades $bandTrades
        $bandSummary | Add-Member -NotePropertyName scoreBand -NotePropertyValue $band.Label -PassThru
    }
)
$liquidityAlignedTrades = @($tradeItems | Where-Object { $_.liquidityAligned -eq $true })
$liquidityAlignedSummary = Get-BacktestSummary -Trades $liquidityAlignedTrades
$liquiditySweepTrades = @($tradeItems | Where-Object { $_.liquiditySignalType -ne "none" })
$liquiditySweepSummary = Get-BacktestSummary -Trades $liquiditySweepTrades

if (-not $OutputPath) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $OutputPath = Join-Path $projectRoot "data\backtest-$stamp.json"
}
Ensure-Directory -Path (Split-Path -Parent $OutputPath)

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToString("o")
    parameters = [pscustomobject]@{
        days = $Days
        scoreThreshold = if ($ScoreThreshold -gt 0) { $ScoreThreshold } else { $null }
        longScoreThreshold = $LongScoreThreshold
        shortScoreThreshold = $ShortScoreThreshold
        longEdgeThreshold = $LongEdgeThreshold
        shortEdgeThreshold = $ShortEdgeThreshold
        maxShortMarketRegimeScore = $MaxShortMarketRegimeScore
        leverage = $Leverage
        holdHours = $HoldHours
        roundTripFeePct = $RoundTripFeePct
        roundTripSlippagePct = $RoundTripSlippagePct
        maxEntriesPerDirection = $MaxEntriesPerDirection
        allowOverlappingSignals = [bool]$AllowOverlappingSignals
        symbols = $testSymbols
    }
    summary = $summary
    byDirection = $byDirection
    byScoreBand = $byScoreBand
    liquiditySweep = $liquiditySweepSummary
    liquidityAligned = $liquidityAlignedSummary
    trades = $tradeItems
}

$result | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
$csvPath = [System.IO.Path]::ChangeExtension($OutputPath, ".csv")
$tradeItems | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Backtest summary"
Write-Host ("  Trades: {0}" -f $summary.trades)
Write-Host ("  Win rate: {0}%" -f $summary.winRatePct)
Write-Host ("  Avg leveraged return: {0}%" -f $summary.averageReturnPct)
Write-Host ("  Total compounded return: {0}%" -f $summary.totalReturnPct)
Write-Host ("  Profit factor: {0}" -f $summary.profitFactor)
Write-Host ("  Max drawdown: {0}%" -f $summary.maxDrawdownPct)
Write-Host ("Saved JSON: {0}" -f $OutputPath)
Write-Host ("Saved CSV: {0}" -f $csvPath)
