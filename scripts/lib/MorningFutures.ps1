Set-StrictMode -Version Latest

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:MorningFuturesHeaders = @{
    "User-Agent" = "MorningFutures/1.0"
    "Accept" = "application/json, text/plain, */*"
}

$script:RiskFilter = @{
    MinimumHistoryCandles = 168
    MaxLongMove6hPct = 2.6
    MaxLongMove24hPct = 3.2
    MaxShortMove6hPct = -2.6
    MaxShortMove24hPct = -3.2
    MaxLookbackMovePct = 25
    MaxAverageHourlyRangePct = 4.5
    ExtendedBandPosition = 0.85
    ExtendedBandMove6hPct = 1.8
    CounterTrendMove6hPct = 1.6
}

function Get-ProjectRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        [void](New-Item -ItemType Directory -Path $Path -Force)
    }
}

function Clamp-Number {
    param(
        [double]$Value,
        [double]$Minimum,
        [double]$Maximum
    )

    return [Math]::Min($Maximum, [Math]::Max($Minimum, $Value))
}

function Normalize-Number {
    param(
        [double]$Value,
        [double]$Scale
    )

    if ($Scale -eq 0) {
        return 0
    }

    return Clamp-Number -Value ($Value / $Scale) -Minimum -1 -Maximum 1
}

function Get-Average {
    param(
        [AllowNull()]
        [object[]]$Values
    )

    $items = @($Values | Where-Object { $null -ne $_ })
    if ($items.Count -eq 0) {
        return 0
    }

    return [double](($items | Measure-Object -Average).Average)
}

function Get-StandardDeviation {
    param(
        [AllowNull()]
        [object[]]$Values
    )

    $items = @($Values | Where-Object { $null -ne $_ } | ForEach-Object { [double]$_ })
    if ($items.Count -eq 0) {
        return 0
    }

    $average = Get-Average -Values $items
    $sumOfSquares = 0.0
    foreach ($item in $items) {
        $sumOfSquares += [Math]::Pow(($item - $average), 2)
    }

    return [Math]::Sqrt($sumOfSquares / [double]$items.Count)
}

function Get-PercentChange {
    param(
        [double]$BaseValue,
        [double]$CurrentValue
    )

    if ($BaseValue -eq 0) {
        return 0
    }

    return (($CurrentValue - $BaseValue) / $BaseValue) * 100
}

function Format-SignedPercent {
    param(
        [double]$Value,
        [int]$Digits = 2
    )

    if ($Value -ge 0) {
        return ("+{0:N$Digits}" -f $Value) + "%"
    }

    return ("{0:N$Digits}" -f $Value) + "%"
}

function Get-PricePrecision {
    param(
        [double]$Price
    )

    if ($Price -ge 1000) {
        return 2
    }
    elseif ($Price -ge 100) {
        return 2
    }
    elseif ($Price -ge 1) {
        return 3
    }
    elseif ($Price -ge 0.1) {
        return 4
    }
    elseif ($Price -ge 0.01) {
        return 5
    }

    return 6
}

function Round-TradePrice {
    param(
        [double]$Price
    )

    return [Math]::Round($Price, (Get-PricePrecision -Price $Price))
}

function Get-LastItems {
    param(
        [object[]]$Items,
        [int]$Count
    )

    $collection = @($Items)
    if ($collection.Count -le $Count) {
        return $collection
    }

    return @($collection[($collection.Count - $Count)..($collection.Count - 1)])
}

function Get-WindowBeforeTail {
    param(
        [object[]]$Items,
        [int]$TailCount,
        [int]$WindowSize
    )

    $collection = @($Items)
    $end = $collection.Count - $TailCount - 1
    if ($end -lt 0) {
        return @()
    }

    $start = [Math]::Max(0, $end - $WindowSize + 1)
    return @($collection[$start..$end])
}

function Get-BollingerSeries {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Candles,
        [int]$Period = 20,
        [double]$StdDevMultiplier = 2
    )

    $series = New-Object System.Collections.Generic.List[object]
    $items = @($Candles)
    if ($items.Count -lt $Period) {
        return @()
    }

    for ($index = ($Period - 1); $index -lt $items.Count; $index++) {
        $window = @($items[($index - $Period + 1)..$index])
        $closes = @($window | ForEach-Object { [double]$_.Close })
        $basis = Get-Average -Values $closes
        $stdDev = Get-StandardDeviation -Values $closes
        $upper = $basis + ($StdDevMultiplier * $stdDev)
        $lower = $basis - ($StdDevMultiplier * $stdDev)
        $widthPct = if ($basis -ne 0) { (($upper - $lower) / $basis) * 100 } else { 0 }
        $candle = $items[$index]

        $series.Add([pscustomobject]@{
            openTime = $candle.OpenTime.ToString("o")
            open = [Math]::Round([double]$candle.Open, 6)
            high = [Math]::Round([double]$candle.High, 6)
            low = [Math]::Round([double]$candle.Low, 6)
            close = [Math]::Round([double]$candle.Close, 6)
            basis = [Math]::Round($basis, 6)
            upper = [Math]::Round($upper, 6)
            lower = [Math]::Round($lower, 6)
            widthPct = [Math]::Round($widthPct, 2)
        })
    }

    return @($series.ToArray())
}

function New-DefaultConfig {
    return [pscustomobject]@{
        UniverseSize = 15
        TopPicks = 3
        MinQuoteVolumeUsd = 30000000
        KlineLookbackHours = 240
        PreferredSymbols = @(
            "BTC-USDT-SWAP",
            "ETH-USDT-SWAP",
            "SOL-USDT-SWAP",
            "BNB-USDT-SWAP",
            "XRP-USDT-SWAP",
            "DOGE-USDT-SWAP",
            "ADA-USDT-SWAP",
            "SUI-USDT-SWAP",
            "AVAX-USDT-SWAP",
            "LINK-USDT-SWAP",
            "LTC-USDT-SWAP",
            "TRX-USDT-SWAP",
            "DOT-USDT-SWAP",
            "BCH-USDT-SWAP",
            "TON-USDT-SWAP"
        )
        NewsSources = @(
            [pscustomobject]@{
                Name = "CoinDesk"
                RssUrl = "https://www.coindesk.com/arc/outboundfeeds/rss/"
            },
            [pscustomobject]@{
                Name = "Cointelegraph"
                RssUrl = "https://cointelegraph.com/rss"
            }
        )
        Telegram = [pscustomobject]@{
            Enabled = $false
            BotToken = ""
            ChatId = ""
        }
        Discord = [pscustomobject]@{
            Enabled = $false
            WebhookUrl = ""
        }
    }
}

function Merge-ConfigObject {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Base,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Override
    )

    foreach ($property in $Override.PSObject.Properties) {
        $existing = $Base.PSObject.Properties[$property.Name]
        if ($existing -and $existing.Value -is [pscustomobject] -and $property.Value -is [pscustomobject]) {
            Merge-ConfigObject -Base $existing.Value -Override $property.Value | Out-Null
            continue
        }

        if ($existing) {
            $existing.Value = $property.Value
        }
        else {
            $Base | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
        }
    }

    return $Base
}

function Get-MorningFuturesConfig {
    param(
        [string]$ConfigPath = ""
    )

    $projectRoot = Get-ProjectRoot
    $defaults = New-DefaultConfig

    $candidatePaths = @()
    if ($ConfigPath) {
        $candidatePaths += $ConfigPath
    }
    else {
        $candidatePaths += (Join-Path $projectRoot "config.json")
        $candidatePaths += (Join-Path $projectRoot "config.sample.json")
    }

    $resolvedPath = $null
    foreach ($path in $candidatePaths) {
        if (Test-Path -LiteralPath $path) {
            $resolvedPath = (Resolve-Path -LiteralPath $path).Path
            break
        }
    }

    if (-not $resolvedPath) {
        return $defaults
    }

    $loaded = Get-Content -LiteralPath $resolvedPath -Raw | ConvertFrom-Json
    $config = Merge-ConfigObject -Base $defaults -Override $loaded
    $config | Add-Member -NotePropertyName ResolvedConfigPath -NotePropertyValue $resolvedPath -Force
    return $config
}

function Invoke-ApiJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    return Invoke-RestMethod -Method Get -Uri $Uri -Headers $script:MorningFuturesHeaders -TimeoutSec 25
}

function Invoke-ApiText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    $response = Invoke-WebRequest -Method Get -Uri $Uri -Headers $script:MorningFuturesHeaders -TimeoutSec 25 -UseBasicParsing
    return $response.Content
}

function ConvertTo-KlineObjects {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Klines
    )

    $candles = @()
    foreach ($item in $Klines) {
        $openTime = [DateTimeOffset]::FromUnixTimeMilliseconds([int64]$item[0]).LocalDateTime
        $candles += [pscustomobject]@{
            OpenTime = $openTime
            Open = [double]$item[1]
            High = [double]$item[2]
            Low = [double]$item[3]
            Close = [double]$item[4]
            Volume = [double]$item[6]
            CloseTime = $openTime.AddHours(1)
            QuoteVolume = [double]$item[7]
        }
    }

    return @($candles | Sort-Object OpenTime)
}

function Get-HeadlineSentiment {
    param(
        [string]$Title
    )

    $positiveTokens = @(
        "rally", "surge", "jump", "approval", "approved", "inflow", "launch",
        "adoption", "partnership", "breakout", "record", "bull", "recovery"
    )
    $negativeTokens = @(
        "hack", "exploit", "lawsuit", "outflow", "liquidation", "crackdown",
        "delay", "selloff", "ban", "fraud", "dump", "bear", "drop"
    )

    $score = 0
    $lowered = ([string]$Title).ToLowerInvariant()

    foreach ($token in $positiveTokens) {
        if ($lowered -match [regex]::Escape($token)) {
            $score += 1
        }
    }

    foreach ($token in $negativeTokens) {
        if ($lowered -match [regex]::Escape($token)) {
            $score -= 1
        }
    }

    $normalized = Clamp-Number -Value ($score / 3) -Minimum -1 -Maximum 1
    $label = "Neutral"
    if ($normalized -ge 0.34) {
        $label = "Bullish"
    }
    elseif ($normalized -le -0.34) {
        $label = "Bearish"
    }

    return [pscustomobject]@{
        Score = $normalized
        Label = $label
    }
}

function Get-NewsItems {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Config
    )

    $items = @()
    foreach ($source in @($Config.NewsSources)) {
        try {
            $content = Invoke-ApiText -Uri $source.RssUrl
            [xml]$feed = $content

            if ($feed.rss.channel.item) {
                foreach ($entry in @($feed.rss.channel.item | Select-Object -First 4)) {
                    $title = [string]$entry.title
                    $sentiment = Get-HeadlineSentiment -Title $title
                    $published = $null
                    $rawPublished = [string]$entry.pubDate
                    if ($rawPublished) {
                        try {
                            $published = [DateTimeOffset]::Parse($rawPublished)
                        }
                        catch {
                            $published = $null
                        }
                    }

                    $items += [pscustomobject]@{
                        source = [string]$source.Name
                        title = $title
                        link = [string]$entry.link
                        published = if ($published) { $published.ToString("o") } else { "" }
                        publishedLocal = if ($published) { $published.LocalDateTime.ToString("o") } else { "" }
                        sentimentScore = $sentiment.Score
                        sentimentLabel = $sentiment.Label
                    }
                }
            }
            elseif ($feed.feed.entry) {
                foreach ($entry in @($feed.feed.entry | Select-Object -First 4)) {
                    $title = [string]$entry.title
                    $sentiment = Get-HeadlineSentiment -Title $title
                    $published = $null
                    $rawPublished = [string]$entry.updated
                    if ($rawPublished) {
                        try {
                            $published = [DateTimeOffset]::Parse($rawPublished)
                        }
                        catch {
                            $published = $null
                        }
                    }

                    $link = ""
                    if ($entry.link -and $entry.link.href) {
                        $link = [string]$entry.link.href
                    }

                    $items += [pscustomobject]@{
                        source = [string]$source.Name
                        title = $title
                        link = $link
                        published = if ($published) { $published.ToString("o") } else { "" }
                        publishedLocal = if ($published) { $published.LocalDateTime.ToString("o") } else { "" }
                        sentimentScore = $sentiment.Score
                        sentimentLabel = $sentiment.Label
                    }
                }
            }
        }
        catch {
            continue
        }
    }

    return @($items | Sort-Object {
        if ($_.published) {
            [DateTimeOffset]::Parse($_.published)
        }
        else {
            [DateTimeOffset]::MinValue
        }
    } -Descending | Select-Object -First 6)
}

function ConvertTo-OkxInstId {
    param(
        [string]$Symbol
    )

    $normalized = ([string]$Symbol).Trim().ToUpperInvariant()
    if ($normalized -match "^[A-Z0-9]+-USDT-SWAP$") {
        return $normalized
    }

    if ($normalized -match "^[A-Z0-9]+USDT$") {
        return ("{0}-USDT-SWAP" -f $normalized.Substring(0, $normalized.Length - 4))
    }

    return $normalized
}

function Get-Okx24hChangePct {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Ticker
    )

    return Get-PercentChange -BaseValue ([double]$Ticker.open24h) -CurrentValue ([double]$Ticker.last)
}

function Get-OkxNotionalVolumeUsd {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Ticker
    )

    return [double]$Ticker.last * [double]$Ticker.volCcy24h
}

function Get-FundingMap {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$InstIds
    )

    $map = @{}
    foreach ($instId in $InstIds) {
        try {
            $encodedInstId = [System.Uri]::EscapeDataString($instId)
            $response = Invoke-ApiJson -Uri ("https://www.okx.com/api/v5/public/funding-rate?instId={0}" -f $encodedInstId)
            if ($response.data -and $response.data[0]) {
                $map[$instId] = $response.data[0]
            }
        }
        catch {
            continue
        }
    }

    return $map
}

function Get-SymbolUniverse {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Tickers,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Config
    )

    $eligible = @(
        $Tickers |
        Where-Object {
            $_.instId -match "^[A-Z0-9]+-USDT-SWAP$" -and
            (Get-OkxNotionalVolumeUsd -Ticker $_) -ge [double]$Config.MinQuoteVolumeUsd
        } |
        Sort-Object { Get-OkxNotionalVolumeUsd -Ticker $_ } -Descending
    )

    $selected = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($preferred in @($Config.PreferredSymbols)) {
        $normalizedPreferred = ConvertTo-OkxInstId -Symbol $preferred
        $match = $eligible | Where-Object { $_.instId -eq $normalizedPreferred } | Select-Object -First 1
        if ($match -and -not $seen.ContainsKey($match.instId)) {
            $selected.Add($match)
            $seen[$match.instId] = $true
        }
    }

    if ($selected.Count -gt 0) {
        return @($selected | Select-Object -First ([int]$Config.UniverseSize))
    }

    foreach ($ticker in $eligible) {
        if (-not $seen.ContainsKey($ticker.instId)) {
            $selected.Add($ticker)
            $seen[$ticker.instId] = $true
        }
    }

    return @($selected | Select-Object -First ([int]$Config.UniverseSize))
}

function Get-MarketContext {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$UniverseTickers,
        [Parameter(Mandatory = $true)]
        [object[]]$NewsItems
    )

    $fearValue = $null
    $fearLabel = ""
    try {
        $fearResponse = Invoke-ApiJson -Uri "https://api.alternative.me/fng/?limit=1&format=json"
        if ($fearResponse.data -and $fearResponse.data[0]) {
            $fearValue = [int]$fearResponse.data[0].value
            $fearLabel = [string]$fearResponse.data[0].value_classification
        }
    }
    catch {
        $fearValue = $null
        $fearLabel = ""
    }

    $positiveBreadth = @($UniverseTickers | Where-Object { (Get-Okx24hChangePct -Ticker $_) -gt 0 }).Count
    $breadthPct = 0
    if ($UniverseTickers.Count -gt 0) {
        $breadthPct = ($positiveBreadth / [double]$UniverseTickers.Count) * 100
    }

    $btc = $UniverseTickers | Where-Object { $_.instId -eq "BTC-USDT-SWAP" } | Select-Object -First 1
    $eth = $UniverseTickers | Where-Object { $_.instId -eq "ETH-USDT-SWAP" } | Select-Object -First 1

    $btcChange = if ($btc) { Get-Okx24hChangePct -Ticker $btc } else { 0 }
    $ethChange = if ($eth) { Get-Okx24hChangePct -Ticker $eth } else { 0 }
    $newsScore = Get-Average -Values @($NewsItems | ForEach-Object { $_.sentimentScore })
    $fearScore = if ($null -ne $fearValue) { Normalize-Number -Value ($fearValue - 50) -Scale 20 } else { 0 }
    $breadthScore = Normalize-Number -Value ($breadthPct - 50) -Scale 20
    $btcScore = Normalize-Number -Value $btcChange -Scale 8
    $ethScore = Normalize-Number -Value $ethChange -Scale 10

    $regimeScore = (0.25 * $btcScore) + (0.20 * $ethScore) + (0.20 * $breadthScore) + (0.20 * $fearScore) + (0.15 * $newsScore)

    $regimeLabel = "Mixed / Rotation"
    if ($regimeScore -ge 0.45) {
        $regimeLabel = "Constructive Risk-On"
    }
    elseif ($regimeScore -ge 0.15) {
        $regimeLabel = "Mild Risk-On"
    }
    elseif ($regimeScore -le -0.45) {
        $regimeLabel = "Defensive Risk-Off"
    }
    elseif ($regimeScore -le -0.15) {
        $regimeLabel = "Mild Risk-Off"
    }

    $summary = "The market is mixed."
    if ($regimeScore -ge 0.15) {
        $summary = "BTC and ETH are holding up, breadth is constructive across liquid pairs, and the session leans toward continuation setups rather than broad panic fades."
    }
    elseif ($regimeScore -le -0.15) {
        $summary = "Broad risk appetite is soft enough that downside continuation and failed bounce setups deserve extra attention."
    }
    else {
        $summary = "The tape is balanced enough that relative strength and relative weakness matter more than making an all-market directional call."
    }

    $leaders = @(
        $UniverseTickers |
        Sort-Object { Get-Okx24hChangePct -Ticker $_ } -Descending |
        Select-Object -First 3 |
        ForEach-Object {
            [pscustomobject]@{
                symbol = $_.instId
                change24hPct = [Math]::Round((Get-Okx24hChangePct -Ticker $_), 2)
            }
        }
    )

    $laggards = @(
        $UniverseTickers |
        Sort-Object { Get-Okx24hChangePct -Ticker $_ } |
        Select-Object -First 3 |
        ForEach-Object {
            [pscustomobject]@{
                symbol = $_.instId
                change24hPct = [Math]::Round((Get-Okx24hChangePct -Ticker $_), 2)
            }
        }
    )

    return [pscustomobject]@{
        regimeLabel = $regimeLabel
        regimeScore = [Math]::Round($regimeScore, 3)
        breadthPositivePct = [Math]::Round($breadthPct, 1)
        summary = $summary
        fearGreed = if ($null -ne $fearValue) {
            [pscustomobject]@{
                value = $fearValue
                label = $fearLabel
            }
        }
        else {
            $null
        }
        leaders = $leaders
        laggards = $laggards
    }
}

function New-ScoreFromMetrics {
    param(
        [double]$Change3hPct,
        [double]$Change6hPct,
        [double]$Change24hPct,
        [double]$TrendWinRate,
        [double]$VolumeRatio,
        [double]$FundingRatePct,
        [double]$VolatilityPct,
        [double]$MarketRegimeScore,
        [double]$BollingerPosition = 0,
        [double]$BollingerBasisSlopePct = 0,
        [double]$BollingerWidthRatio = 1
    )

    $momentum = (0.45 * (Normalize-Number -Value $Change6hPct -Scale 4)) +
        (0.35 * (Normalize-Number -Value $Change24hPct -Scale 8)) +
        (0.20 * (Normalize-Number -Value $Change3hPct -Scale 2))
    $trend = Normalize-Number -Value $TrendWinRate -Scale 1
    $volume = Normalize-Number -Value ($VolumeRatio - 1) -Scale 1.25
    $volatility = Normalize-Number -Value $VolatilityPct -Scale 3.5
    $longCrowdingRelief = Normalize-Number -Value (-1 * $FundingRatePct) -Scale 0.04
    $shortCrowdingRelief = Normalize-Number -Value $FundingRatePct -Scale 0.04
    $overextendedLong = if ($Change6hPct -gt 5) { 0.5 } else { 1.0 }
    $overextendedShort = if ($Change6hPct -lt -5) { 0.5 } else { 1.0 }
    $bollingerPositionScore = if ($BollingerPosition -ge 0) {
        (Clamp-Number -Value $BollingerPosition -Minimum -1 -Maximum 1) * $overextendedLong
    }
    else {
        (Clamp-Number -Value $BollingerPosition -Minimum -1 -Maximum 1) * $overextendedShort
    }
    $bollingerBasisSlope = Normalize-Number -Value $BollingerBasisSlopePct -Scale 1.2
    $bollingerExpansion = Normalize-Number -Value ($BollingerWidthRatio - 1) -Scale 0.6

    $momentumTrendContribution = (22 * $momentum) + (11 * $trend)
    $marketRegimeContribution = 7 * $MarketRegimeScore
    $bollingerContribution = (6 * $bollingerPositionScore) + (4 * $bollingerBasisSlope)
    $sharedOpportunity = (10 * [Math]::Max(0, $volume)) + (6 * $volatility) + (3 * [Math]::Max(0, $bollingerExpansion))
    $longFundingContribution = 6 * $longCrowdingRelief
    $shortFundingContribution = 6 * $shortCrowdingRelief
    $directional = $momentumTrendContribution + $marketRegimeContribution + $bollingerContribution

    $longScore = Clamp-Number -Value (50 + $directional + $sharedOpportunity + $longFundingContribution) -Minimum 0 -Maximum 100
    $shortScore = Clamp-Number -Value (50 - $directional + $sharedOpportunity + $shortFundingContribution) -Minimum 0 -Maximum 100

    return [pscustomobject]@{
        LongScore = [Math]::Round($longScore, 1)
        ShortScore = [Math]::Round($shortScore, 1)
        LongEdge = [Math]::Round($longScore - $shortScore, 1)
        ShortEdge = [Math]::Round($shortScore - $longScore, 1)
        MomentumScore = [Math]::Round($momentum, 3)
        TrendScore = [Math]::Round($trend, 3)
        VolumeScore = [Math]::Round($volume, 3)
        BollingerPositionScore = [Math]::Round($bollingerPositionScore, 3)
        BollingerExpansionScore = [Math]::Round($bollingerExpansion, 3)
        MomentumTrendContribution = [Math]::Round($momentumTrendContribution, 1)
        MarketRegimeContribution = [Math]::Round($marketRegimeContribution, 1)
        BollingerContribution = [Math]::Round($bollingerContribution, 1)
        OpportunityContribution = [Math]::Round($sharedOpportunity, 1)
        LongFundingContribution = [Math]::Round($longFundingContribution, 1)
        ShortFundingContribution = [Math]::Round($shortFundingContribution, 1)
    }
}

function New-RiskProfile {
    param(
        [object[]]$Candles,
        [double]$Change6hPct,
        [double]$Change24hPct,
        [double]$LookbackChangePct,
        [double]$VolatilityPct,
        [double]$BollingerPosition,
        [double]$BandWidthRatio
    )

    $riskFlags = New-Object System.Collections.Generic.List[string]
    $longBlocks = New-Object System.Collections.Generic.List[string]
    $shortBlocks = New-Object System.Collections.Generic.List[string]
    $historyDays = @($Candles).Count / 24

    if ($historyDays -lt 10) {
        $riskFlags.Add(("{0:N1}d candle history" -f $historyDays))
    }

    if ($VolatilityPct -ge 3.2) {
        $riskFlags.Add(("High average hourly range ({0:N2}%)" -f $VolatilityPct))
    }

    if ([Math]::Abs($LookbackChangePct) -ge 25) {
        $riskFlags.Add(("10d move is already {0}" -f (Format-SignedPercent -Value $LookbackChangePct -Digits 1)))
    }

    if ($BandWidthRatio -ge 1.45) {
        $riskFlags.Add(("Bollinger bands expanded {0:N2}x" -f $BandWidthRatio))
    }

    if ($VolatilityPct -ge [double]$script:RiskFilter.MaxAverageHourlyRangePct) {
        $longBlocks.Add(("Skipped long: average hourly range is {0:N2}%." -f $VolatilityPct))
        $shortBlocks.Add(("Skipped short: average hourly range is {0:N2}%." -f $VolatilityPct))
    }

    if ($Change6hPct -ge [double]$script:RiskFilter.MaxLongMove6hPct -or $Change24hPct -ge [double]$script:RiskFilter.MaxLongMove24hPct) {
        $longBlocks.Add(("Skipped long: move is extended ({0} 6h, {1} 24h)." -f (Format-SignedPercent -Value $Change6hPct), (Format-SignedPercent -Value $Change24hPct)))
    }

    if ($Change6hPct -le [double]$script:RiskFilter.MaxShortMove6hPct -or $Change24hPct -le [double]$script:RiskFilter.MaxShortMove24hPct) {
        $shortBlocks.Add(("Skipped short: selloff is extended ({0} 6h, {1} 24h)." -f (Format-SignedPercent -Value $Change6hPct), (Format-SignedPercent -Value $Change24hPct)))
    }

    if ($Change24hPct -lt 0 -and $Change6hPct -ge [double]$script:RiskFilter.CounterTrendMove6hPct) {
        $longBlocks.Add(("Skipped long: 6h rebound is fighting a negative 24h tape ({0})." -f (Format-SignedPercent -Value $Change24hPct)))
    }

    if ($Change24hPct -gt 0 -and $Change6hPct -le (-1 * [double]$script:RiskFilter.CounterTrendMove6hPct)) {
        $shortBlocks.Add(("Skipped short: 6h drop is fighting a positive 24h tape ({0})." -f (Format-SignedPercent -Value $Change24hPct)))
    }

    if ($LookbackChangePct -ge [double]$script:RiskFilter.MaxLookbackMovePct) {
        $longBlocks.Add(("Skipped long: 10d move is already {0}." -f (Format-SignedPercent -Value $LookbackChangePct -Digits 1)))
    }

    if ($LookbackChangePct -le (-1 * [double]$script:RiskFilter.MaxLookbackMovePct)) {
        $shortBlocks.Add(("Skipped short: 10d move is already {0}." -f (Format-SignedPercent -Value $LookbackChangePct -Digits 1)))
    }

    if ($BollingerPosition -ge [double]$script:RiskFilter.ExtendedBandPosition -and $Change6hPct -ge [double]$script:RiskFilter.ExtendedBandMove6hPct) {
        $longBlocks.Add("Skipped long: price is chasing the upper Bollinger extreme.")
    }

    if ($BollingerPosition -le (-1 * [double]$script:RiskFilter.ExtendedBandPosition) -and $Change6hPct -le (-1 * [double]$script:RiskFilter.ExtendedBandMove6hPct)) {
        $shortBlocks.Add("Skipped short: price is chasing the lower Bollinger extreme.")
    }

    return [pscustomobject]@{
        riskFlags = @($riskFlags)
        riskBlocks = [pscustomobject]@{
            long = @($longBlocks)
            short = @($shortBlocks)
        }
    }
}

function Get-TechnicalChartNotes {
    param(
        [double]$BollingerPosition,
        [double]$BandWidthRatio,
        [double]$BasisSlopePct,
        [double]$SupportPrice,
        [double]$ResistancePrice
    )

    $notes = New-Object System.Collections.Generic.List[string]

    if ($BollingerPosition -ge 0.7 -and $BandWidthRatio -ge 1.05) {
        $notes.Add("Price is pressing the upper Bollinger band while the bands expand, which supports bullish continuation if the basis holds.")
    }
    elseif ($BollingerPosition -ge 0.25) {
        $notes.Add("Price is holding above the Bollinger basis and leaning toward the upper band.")
    }
    elseif ($BollingerPosition -le -0.7 -and $BandWidthRatio -ge 1.05) {
        $notes.Add("Price is pressing the lower Bollinger band while the bands expand, which keeps downside continuation in play.")
    }
    elseif ($BollingerPosition -le -0.25) {
        $notes.Add("Price is holding below the Bollinger basis and leaning toward the lower band.")
    }
    else {
        $notes.Add("Price is hovering near the Bollinger basis, so the chart still looks balanced rather than impulsive.")
    }

    if ($BasisSlopePct -ge 0.18) {
        $notes.Add(("The Bollinger basis is sloping up by {0}, which keeps short-term trend control with buyers." -f (Format-SignedPercent -Value $BasisSlopePct -Digits 2)))
    }
    elseif ($BasisSlopePct -le -0.18) {
        $notes.Add(("The Bollinger basis is sloping down by {0}, which keeps short-term trend control with sellers." -f (Format-SignedPercent -Value $BasisSlopePct -Digits 2)))
    }
    else {
        $notes.Add("The Bollinger basis is mostly flat, so the chart is still close to balance instead of a clean one-way trend.")
    }

    if ($BandWidthRatio -le 0.85) {
        $notes.Add("Band width is tighter than its recent average, so a fresh volatility expansion could still be ahead.")
    }
    elseif ($BandWidthRatio -ge 1.15) {
        $notes.Add("Band width is wider than its recent average, which confirms that the current move is active instead of sleepy.")
    }
    else {
        $notes.Add("Band width is close to its recent average, so the move looks active but not unusually stretched.")
    }

    $notes.Add(("Recent 24h range support is near {0} and resistance is near {1}." -f (Round-TradePrice -Price $SupportPrice), (Round-TradePrice -Price $ResistancePrice)))
    return @($notes.ToArray())
}

function Get-SymbolSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Ticker,
        [Parameter(Mandatory = $true)]
        [hashtable]$FundingMap,
        [int]$KlineLookbackHours,
        [double]$MarketRegimeScore
    )

    $symbol = [string]$Ticker.instId
    $encodedInstId = [System.Uri]::EscapeDataString($symbol)
    $klineResponse = Invoke-ApiJson -Uri ("https://www.okx.com/api/v5/market/candles?instId={0}&bar=1H&limit={1}" -f $encodedInstId, $KlineLookbackHours)
    $candles = ConvertTo-KlineObjects -Klines @($klineResponse.data)

    if ($candles.Count -lt [int]$script:RiskFilter.MinimumHistoryCandles) {
        throw "Only $($candles.Count) hourly candles returned for $symbol; skipping short-history listing risk."
    }

    $lastPrice = [double]$candles[-1].Close
    $change3hPct = Get-PercentChange -BaseValue ([double]$candles[$candles.Count - 4].Close) -CurrentValue $lastPrice
    $change6hPct = Get-PercentChange -BaseValue ([double]$candles[$candles.Count - 7].Close) -CurrentValue $lastPrice
    $change24hPct = Get-PercentChange -BaseValue ([double]$candles[$candles.Count - 25].Close) -CurrentValue $lastPrice
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

    $fundingRatePct = 0
    if ($FundingMap.ContainsKey($symbol)) {
        $fundingRatePct = [double]$FundingMap[$symbol].fundingRate * 100
    }

    $bollingerSeries = Get-BollingerSeries -Candles $candles -Period 20
    if ($bollingerSeries.Count -eq 0) {
        throw "Not enough candles returned to build Bollinger bands for $symbol."
    }

    $currentBollinger = $bollingerSeries[-1]
    $priorBollingerWidths = Get-WindowBeforeTail -Items $bollingerSeries -TailCount 1 -WindowSize 10
    $averagePriorBandWidthPct = Get-Average -Values @($priorBollingerWidths | ForEach-Object { $_.widthPct })
    $bandWidthRatio = if ($averagePriorBandWidthPct -gt 0) { [double]$currentBollinger.widthPct / $averagePriorBandWidthPct } else { 1 }
    $basisSlopePct = 0
    if ($bollingerSeries.Count -ge 6) {
        $basisSlopePct = Get-PercentChange -BaseValue ([double]$bollingerSeries[$bollingerSeries.Count - 6].basis) -CurrentValue ([double]$currentBollinger.basis)
    }

    $halfBand = (([double]$currentBollinger.upper - [double]$currentBollinger.lower) / 2)
    $bollingerPosition = if ($halfBand -gt 0) {
        Clamp-Number -Value (($lastPrice - [double]$currentBollinger.basis) / $halfBand) -Minimum -1 -Maximum 1
    }
    else {
        0
    }

    $chartPoints = Get-LastItems -Items $bollingerSeries -Count 24
    $recentSupport = [double](($chartPoints | Measure-Object -Property low -Minimum).Minimum)
    $recentResistance = [double](($chartPoints | Measure-Object -Property high -Maximum).Maximum)
    $technicalNotes = Get-TechnicalChartNotes `
        -BollingerPosition $bollingerPosition `
        -BandWidthRatio $bandWidthRatio `
        -BasisSlopePct $basisSlopePct `
        -SupportPrice $recentSupport `
        -ResistancePrice $recentResistance
    $riskProfile = New-RiskProfile `
        -Candles $candles `
        -Change6hPct $change6hPct `
        -Change24hPct $change24hPct `
        -LookbackChangePct $lookbackChangePct `
        -VolatilityPct $volatilityPct `
        -BollingerPosition $bollingerPosition `
        -BandWidthRatio $bandWidthRatio

    $scores = New-ScoreFromMetrics `
        -Change3hPct $change3hPct `
        -Change6hPct $change6hPct `
        -Change24hPct $change24hPct `
        -TrendWinRate $trendWinRate `
        -VolumeRatio $volumeRatio `
        -FundingRatePct $fundingRatePct `
        -VolatilityPct $volatilityPct `
        -MarketRegimeScore $MarketRegimeScore `
        -BollingerPosition $bollingerPosition `
        -BollingerBasisSlopePct $basisSlopePct `
        -BollingerWidthRatio $bandWidthRatio

    $longReasons = New-Object System.Collections.Generic.List[string]
    if ($change6hPct -gt 1.5) {
        $longReasons.Add(("6h momentum is running {0}" -f (Format-SignedPercent -Value $change6hPct -Digits 2)))
    }
    if ($change24hPct -gt 3) {
        $longReasons.Add(("24h trend remains positive at {0}" -f (Format-SignedPercent -Value $change24hPct -Digits 2)))
    }
    if ($volumeRatio -ge 1.25) {
        $longReasons.Add(("quote volume is {0:N2}x above its recent baseline" -f $volumeRatio))
    }
    if ($trendWinRate -ge 0.01) {
        $longReasons.Add(("recent 6h average price is {0} versus the prior 6h average" -f (Format-SignedPercent -Value ($trendWinRate * 100) -Digits 2)))
    }
    if ($fundingRatePct -le -0.01) {
        $longReasons.Add(("funding at {0} suggests short crowding" -f (Format-SignedPercent -Value $fundingRatePct -Digits 3)))
    }
    if ($bollingerPosition -ge 0.45) {
        $longReasons.Add("price is holding above the Bollinger basis and leaning toward the upper band")
    }
    if ($bandWidthRatio -ge 1.1 -and $bollingerPosition -ge 0.2) {
        $longReasons.Add("Bollinger bands are expanding, which currently supports continuation more than mean reversion")
    }
    if ($longReasons.Count -eq 0) {
        $longReasons.Add("relative strength is better than most tracked liquid futures pairs")
    }

    $shortReasons = New-Object System.Collections.Generic.List[string]
    if ($change6hPct -lt -1.5) {
        $shortReasons.Add(("6h momentum is slipping at {0}" -f (Format-SignedPercent -Value $change6hPct -Digits 2)))
    }
    if ($change24hPct -lt -3) {
        $shortReasons.Add(("24h trend remains weak at {0}" -f (Format-SignedPercent -Value $change24hPct -Digits 2)))
    }
    if ($volumeRatio -ge 1.25) {
        $shortReasons.Add(("selling pressure is active with {0:N2}x baseline volume" -f $volumeRatio))
    }
    if ($trendWinRate -le -0.01) {
        $shortReasons.Add(("recent 6h average price is {0} versus the prior 6h average" -f (Format-SignedPercent -Value ($trendWinRate * 100) -Digits 2)))
    }
    if ($fundingRatePct -ge 0.01) {
        $shortReasons.Add(("funding at {0} hints that longs are still crowded" -f (Format-SignedPercent -Value $fundingRatePct -Digits 3)))
    }
    if ($bollingerPosition -le -0.45) {
        $shortReasons.Add("price is holding below the Bollinger basis and leaning toward the lower band")
    }
    if ($bandWidthRatio -ge 1.1 -and $bollingerPosition -le -0.2) {
        $shortReasons.Add("Bollinger bands are expanding, which currently supports downside continuation more than snap-back risk")
    }
    if ($shortReasons.Count -eq 0) {
        $shortReasons.Add("relative weakness is more persistent than the rest of the tracked basket")
    }

    return [pscustomobject]@{
        symbol = $symbol
        lastPrice = [Math]::Round($lastPrice, 6)
        move3hPct = [Math]::Round($change3hPct, 2)
        move6hPct = [Math]::Round($change6hPct, 2)
        move24hPct = [Math]::Round($change24hPct, 2)
        lookbackMovePct = [Math]::Round($lookbackChangePct, 2)
        trendWinRate = [Math]::Round($trendWinRate, 3)
        volumeRatio = [Math]::Round($volumeRatio, 2)
        fundingRatePct = [Math]::Round($fundingRatePct, 4)
        volatilityPct = [Math]::Round($volatilityPct, 2)
        bollingerBasis = [Math]::Round([double]$currentBollinger.basis, 6)
        bollingerUpper = [Math]::Round([double]$currentBollinger.upper, 6)
        bollingerLower = [Math]::Round([double]$currentBollinger.lower, 6)
        bollingerWidthPct = [Math]::Round([double]$currentBollinger.widthPct, 2)
        bollingerWidthRatio = [Math]::Round($bandWidthRatio, 2)
        bollingerBasisSlopePct = [Math]::Round($basisSlopePct, 2)
        longScore = $scores.LongScore
        shortScore = $scores.ShortScore
        longEdge = $scores.LongEdge
        shortEdge = $scores.ShortEdge
        longReasons = @($longReasons)
        shortReasons = @($shortReasons)
        riskFlags = @($riskProfile.riskFlags)
        riskBlocks = $riskProfile.riskBlocks
        technicalNotes = @($technicalNotes)
        chart = [pscustomobject]@{
            points = @($chartPoints)
            support = Round-TradePrice -Price $recentSupport
            resistance = Round-TradePrice -Price $recentResistance
            bollingerPeriod = 20
            bollingerDeviation = 2
            widthPct = [Math]::Round([double]$currentBollinger.widthPct, 2)
            widthRatio = [Math]::Round($bandWidthRatio, 2)
            basisSlopePct = [Math]::Round($basisSlopePct, 2)
        }
        scoreComponents = [pscustomobject]@{
            momentumTrend = $scores.MomentumTrendContribution
            marketRegime = $scores.MarketRegimeContribution
            bollinger = $scores.BollingerContribution
            opportunity = $scores.OpportunityContribution
            longFunding = $scores.LongFundingContribution
            shortFunding = $scores.ShortFundingContribution
        }
        longThesis = "$symbol is showing enough intraday continuation, participation, and crowding relief to stay on a bullish watchlist if the market regime holds."
        shortThesis = "$symbol is underperforming the broader liquid futures basket and still looks vulnerable to downside continuation if the tape does not recover."
        longInvalidation = "Volume fades, the 6h trend flips negative, or broad market breadth breaks down."
        shortInvalidation = "The symbol reclaims intraday trend support and starts outperforming the rest of the basket."
    }
}

function New-BeginnerTradePlan {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Snapshot,
        [Parameter(Mandatory = $true)]
        [ValidateSet("long", "short")]
        [string]$Direction,
        [double]$Confidence
    )

    $entryPrice = [double]$Snapshot.lastPrice
    $riskPct = Clamp-Number -Value ([Math]::Max(0.8, ([double]$Snapshot.volatilityPct * 0.65))) -Minimum 0.8 -Maximum 2.4

    $takeProfit1Multiple = 1.2
    $takeProfit2Multiple = 1.9
    $holdMinHours = 2
    $holdMaxHours = 6

    if ($Confidence -ge 70) {
        $takeProfit1Multiple = 1.3
        $takeProfit2Multiple = 2.2
        $holdMaxHours = 8
    }
    elseif ($Confidence -lt 58) {
        $takeProfit1Multiple = 1.1
        $takeProfit2Multiple = 1.6
        $holdMaxHours = 4
    }

    if ([Math]::Abs([double]$Snapshot.move6hPct) -ge 3.5) {
        $holdMinHours = 1
        $holdMaxHours = [Math]::Max(($holdMinHours + 2), ($holdMaxHours - 1))
    }

    $takeProfit1Pct = [Math]::Round(($riskPct * $takeProfit1Multiple), 2)
    $takeProfit2Pct = [Math]::Round(($riskPct * $takeProfit2Multiple), 2)
    $stopLossPct = [Math]::Round($riskPct, 2)
    $recommendedLeverage = "1x-3x"
    if ($riskPct -ge 1.7 -or [double]$Snapshot.volatilityPct -ge 2.6) {
        $recommendedLeverage = "1x-2x"
    }
    elseif ($Confidence -ge 72 -and $riskPct -le 1.1) {
        $recommendedLeverage = "2x-3x"
    }

    $scaleOutGuide = "Take 40% at TP1, 40% at TP2, and only leave the last 20% open if momentum still looks healthy."
    if ($Confidence -ge 70) {
        $scaleOutGuide = "Take 30% at TP1, 50% at TP2, and trail the last 20% only if the trend still confirms."
    }
    elseif ($Confidence -lt 58) {
        $scaleOutGuide = "Take 50% at TP1, 30% at TP2, and close the rest by the end of the hold window unless momentum expands."
    }

    $priceLogic = "These levels use recent hourly volatility. The stop is about 1R away, TP1 is near {0:N1}R, and TP2 is near {1:N1}R." -f $takeProfit1Multiple, $takeProfit2Multiple
    $leverageNote = "Conservative in-app heuristic for beginners, not exchange advice."
    $starterNote = "For beginners, do not add to a losing futures position."

    if ($Direction -eq "long") {
        $stopLossPrice = Round-TradePrice -Price ($entryPrice * (1 - ($stopLossPct / 100)))
        $takeProfit1Price = Round-TradePrice -Price ($entryPrice * (1 + ($takeProfit1Pct / 100)))
        $takeProfit2Price = Round-TradePrice -Price ($entryPrice * (1 + ($takeProfit2Pct / 100)))
        $partialExitRule = "If price reaches TP1, consider taking 30-50% off. If it reaches TP2, consider closing most or all of the rest."
        $timingNote = "This is designed for a same-day long. If price is still drifting sideways after the hold window, reduce or close the trade."
    }
    else {
        $stopLossPrice = Round-TradePrice -Price ($entryPrice * (1 + ($stopLossPct / 100)))
        $takeProfit1Price = Round-TradePrice -Price ($entryPrice * (1 - ($takeProfit1Pct / 100)))
        $takeProfit2Price = Round-TradePrice -Price ($entryPrice * (1 - ($takeProfit2Pct / 100)))
        $partialExitRule = "If price reaches TP1 on the way down, consider taking 30-50% off. If it reaches TP2, consider closing most or all of the rest."
        $timingNote = "This is designed for a same-day short. If price stops trending lower after the hold window, reduce or close the trade."
    }

    return [pscustomobject]@{
        style = "same-day intraday"
        entryPrice = Round-TradePrice -Price $entryPrice
        stopLossPrice = $stopLossPrice
        stopLossPct = $stopLossPct
        takeProfit1Price = $takeProfit1Price
        takeProfit1Pct = $takeProfit1Pct
        takeProfit2Price = $takeProfit2Price
        takeProfit2Pct = $takeProfit2Pct
        holdMinHours = $holdMinHours
        holdMaxHours = $holdMaxHours
        holdWindowLabel = "{0}-{1}h" -f $holdMinHours, $holdMaxHours
        partialExitRule = $partialExitRule
        timingNote = $timingNote
        recommendedLeverage = $recommendedLeverage
        scaleOutGuide = $scaleOutGuide
        priceLogic = $priceLogic
        leverageNote = $leverageNote
        starterNote = $starterNote
    }
}

function ConvertTo-Candidate {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Snapshot,
        [Parameter(Mandatory = $true)]
        [ValidateSet("long", "short")]
        [string]$Direction,
        [ValidateSet("actionable", "watch")]
        [string]$SignalStatus = "actionable"
    )

    $score = $Snapshot.longScore
    $edge = $Snapshot.longEdge
    $reasons = $Snapshot.longReasons
    $thesis = $Snapshot.longThesis
    $invalidation = $Snapshot.longInvalidation

    if ($Direction -eq "short") {
        $score = $Snapshot.shortScore
        $edge = $Snapshot.shortEdge
        $reasons = $Snapshot.shortReasons
        $thesis = $Snapshot.shortThesis
        $invalidation = $Snapshot.shortInvalidation
    }

    $confidence = Clamp-Number -Value (50 + ([Math]::Abs($edge) * 0.7)) -Minimum 50 -Maximum 95
    $beginnerPlan = New-BeginnerTradePlan -Snapshot $Snapshot -Direction $Direction -Confidence $confidence
    $momentumTrendPoints = [double]$Snapshot.scoreComponents.momentumTrend
    $marketRegimePoints = [double]$Snapshot.scoreComponents.marketRegime
    $bollingerPoints = [double]$Snapshot.scoreComponents.bollinger
    $fundingPoints = [double]$Snapshot.scoreComponents.longFunding

    if ($Direction -eq "short") {
        $momentumTrendPoints = -1 * $momentumTrendPoints
        $marketRegimePoints = -1 * $marketRegimePoints
        $bollingerPoints = -1 * $bollingerPoints
        $fundingPoints = [double]$Snapshot.scoreComponents.shortFunding
    }

    $scoreBreakdown = @(
        [pscustomobject]@{
            key = "momentumTrend"
            label = "Momentum + trend"
            points = [Math]::Round($momentumTrendPoints, 1)
        },
        [pscustomobject]@{
            key = "bollinger"
            label = "Bollinger alignment"
            points = [Math]::Round($bollingerPoints, 1)
        },
        [pscustomobject]@{
            key = "marketRegime"
            label = "Market regime"
            points = [Math]::Round($marketRegimePoints, 1)
        },
        [pscustomobject]@{
            key = "opportunity"
            label = "Volume + volatility"
            points = [Math]::Round([double]$Snapshot.scoreComponents.opportunity, 1)
        },
        [pscustomobject]@{
            key = "funding"
            label = "Funding crowding"
            points = [Math]::Round($fundingPoints, 1)
        }
    )

    if ($Direction -eq "long") {
        $invalidation = "Reassess if price falls below {0} or the 6h trend flips negative." -f $beginnerPlan.stopLossPrice
    }
    else {
        $invalidation = "Reassess if price rises above {0} or the 6h trend turns back up." -f $beginnerPlan.stopLossPrice
    }

    return [pscustomobject]@{
        symbol = $Snapshot.symbol
        direction = $Direction
        signalStatus = $SignalStatus
        biasScore = [Math]::Round($score, 1)
        edge = [Math]::Round([Math]::Abs($edge), 1)
        confidence = [Math]::Round($confidence, 0)
        lastPrice = $Snapshot.lastPrice
        move6hPct = $Snapshot.move6hPct
        move24hPct = $Snapshot.move24hPct
        lookbackMovePct = $Snapshot.lookbackMovePct
        fundingRatePct = $Snapshot.fundingRatePct
        volumeRatio = $Snapshot.volumeRatio
        volatilityPct = $Snapshot.volatilityPct
        riskFlags = @($Snapshot.riskFlags | Select-Object -First 3)
        reasons = @($reasons | Select-Object -First 3)
        technicalNotes = @($Snapshot.technicalNotes | Select-Object -First 4)
        scoreBreakdown = @($scoreBreakdown)
        thesis = $thesis
        invalidation = $invalidation
        chart = $Snapshot.chart
        beginnerPlan = $beginnerPlan
    }
}

function New-MorningFuturesReport {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Config
    )

    $warnings = New-Object System.Collections.Generic.List[string]
    $tickersResponse = Invoke-ApiJson -Uri "https://www.okx.com/api/v5/market/tickers?instType=SWAP"
    $universe = Get-SymbolUniverse -Tickers @($tickersResponse.data) -Config $Config
    $fundingMap = Get-FundingMap -InstIds @($universe | ForEach-Object { $_.instId })
    $newsItems = Get-NewsItems -Config $Config
    $marketContext = Get-MarketContext -UniverseTickers $universe -NewsItems $newsItems

    $snapshots = @()
    foreach ($ticker in $universe) {
        try {
            $snapshots += Get-SymbolSnapshot `
                -Ticker $ticker `
                -FundingMap $fundingMap `
                -KlineLookbackHours ([int]$Config.KlineLookbackHours) `
                -MarketRegimeScore ([double]$marketContext.regimeScore)
        }
        catch {
            $lineSuffix = if ($_.InvocationInfo -and $_.InvocationInfo.ScriptLineNumber) {
                " (line {0})" -f $_.InvocationInfo.ScriptLineNumber
            }
            else {
                ""
            }

            $warnings.Add(("Skipped {0}: {1}{2}" -f $ticker.instId, $_.Exception.Message, $lineSuffix))
        }
    }

    if ($snapshots.Count -lt 4) {
        $warningSummary = if ($warnings.Count -gt 0) {
            " First errors: " + ((@($warnings | Select-Object -First 3)) -join "; ")
        }
        else {
            ""
        }

        throw "The report could not build enough liquid pair snapshots. Check API connectivity or reduce the universe size.$warningSummary"
    }

    $topPicks = [int]$Config.TopPicks
    $minimumLongBiasScore = 75
    $minimumLongDirectionalEdge = 12
    $minimumShortBiasScore = 78
    $minimumShortDirectionalEdge = 14
    $maximumShortMarketRegimeScore = 0.1
    $minimumLongWatchScore = 70
    $minimumLongWatchEdge = 10
    $minimumShortWatchScore = 72
    $minimumShortWatchEdge = 12
    $maximumShortWatchMarketRegimeScore = 0.2
    $longWatchSnapshots = @(
        $snapshots |
        Sort-Object `
            @{ Expression = { $_.longEdge }; Descending = $true }, `
            @{ Expression = { $_.longScore }; Descending = $true } |
        Where-Object { $_.longEdge -ge $minimumLongWatchEdge -and $_.longScore -ge $minimumLongWatchScore }
    )
    $shortWatchSnapshots = @(
        $snapshots |
        Sort-Object `
            @{ Expression = { $_.shortEdge }; Descending = $true }, `
            @{ Expression = { $_.shortScore }; Descending = $true } |
        Where-Object {
            $_.shortEdge -ge $minimumShortWatchEdge -and
            $_.shortScore -ge $minimumShortWatchScore -and
            [double]$marketContext.regimeScore -le $maximumShortWatchMarketRegimeScore
        }
    )
    $longActionableSnapshots = @(
        $longWatchSnapshots |
        Where-Object {
            $_.longEdge -ge $minimumLongDirectionalEdge -and
            $_.longScore -ge $minimumLongBiasScore -and
            @($_.riskBlocks.long).Count -eq 0
        }
    )
    $shortActionableSnapshots = @(
        $shortWatchSnapshots |
        Where-Object {
            $_.shortEdge -ge $minimumShortDirectionalEdge -and
            $_.shortScore -ge $minimumShortBiasScore -and
            [double]$marketContext.regimeScore -le $maximumShortMarketRegimeScore -and
            @($_.riskBlocks.short).Count -eq 0
        }
    )
    $longSnapshots = @(
        $longActionableSnapshots |
        Select-Object -First $topPicks
    )

    $shortSnapshots = @(
        $shortActionableSnapshots |
        Select-Object -First $topPicks
    )
    $longWatchOnlySnapshots = @(
        $longWatchSnapshots |
        Where-Object { $longSnapshots -notcontains $_ } |
        Select-Object -First ([Math]::Max(0, $topPicks - @($longSnapshots).Count))
    )
    $shortWatchOnlySnapshots = @(
        $shortWatchSnapshots |
        Where-Object { $shortSnapshots -notcontains $_ } |
        Select-Object -First ([Math]::Max(0, $topPicks - @($shortSnapshots).Count))
    )
    $blockedLongCount = @($longWatchSnapshots | Where-Object { @($_.riskBlocks.long).Count -gt 0 }).Count
    $blockedShortCount = @($shortWatchSnapshots | Where-Object { @($_.riskBlocks.short).Count -gt 0 }).Count

    if ($blockedLongCount -gt 0 -or $blockedShortCount -gt 0) {
        $warnings.Add(("Risk filters removed {0} long and {1} short extended setups." -f $blockedLongCount, $blockedShortCount))
    }

    if ($longSnapshots.Count -eq 0) {
        $warnings.Add("No long setups cleared the minimum quality filter in this run.")
    }

    if ($shortSnapshots.Count -eq 0) {
        $warnings.Add("No short setups cleared the minimum quality filter in this run.")
    }

    $report = [pscustomobject]@{
        generatedAt = (Get-Date).ToString("o")
        generatedAtLocal = (Get-Date).ToString("o")
        timezone = (Get-TimeZone).Id
        isSample = $false
        marketContext = $marketContext
        longCandidates = @(
            $longSnapshots | ForEach-Object { ConvertTo-Candidate -Snapshot $_ -Direction "long" -SignalStatus "actionable" }
            $longWatchOnlySnapshots | ForEach-Object { ConvertTo-Candidate -Snapshot $_ -Direction "long" -SignalStatus "watch" }
        )
        shortCandidates = @(
            $shortSnapshots | ForEach-Object { ConvertTo-Candidate -Snapshot $_ -Direction "short" -SignalStatus "actionable" }
            $shortWatchOnlySnapshots | ForEach-Object { ConvertTo-Candidate -Snapshot $_ -Direction "short" -SignalStatus "watch" }
        )
        headlines = @($newsItems | Select-Object source, title, link, published, publishedLocal, sentimentLabel)
        warnings = @($warnings)
        methodology = [pscustomobject]@{
            factors = @(
                "24h and 6h momentum",
                "hourly trend persistence",
                "volume expansion",
                "Bollinger band location and basis slope",
                "funding crowding",
                "BTC and ETH regime strength",
                "liquid-pair breadth",
                "headline sentiment"
            )
        }
        disclaimer = "This report is a probability-weighted watchlist helper for crypto futures sessions. It is not financial advice and should not be used as automatic execution logic."
    }

    return $report
}

function Save-MorningFuturesReport {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Report,
        [string]$OutputPath = ""
    )

    $projectRoot = Get-ProjectRoot
    if (-not $OutputPath) {
        $OutputPath = Join-Path $projectRoot "data\latest-report.json"
    }

    Ensure-Directory -Path (Split-Path -Parent $OutputPath)
    $Report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    return $OutputPath
}

function Format-MorningFuturesNotification {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Report
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Morning Futures Pulse")
    $lines.Add($Report.generatedAtLocal)

    if ($Report.marketContext) {
        $regime = $Report.marketContext.regimeLabel
        $fearText = "N/A"
        if ($Report.marketContext.fearGreed) {
            $fearText = "{0} ({1})" -f $Report.marketContext.fearGreed.value, $Report.marketContext.fearGreed.label
        }
        $lines.Add(("Regime: {0} | Fear & Greed: {1}" -f $regime, $fearText))
    }

    $lines.Add("")
    $lines.Add("Long watchlist")
    $rank = 1
    foreach ($candidate in @($Report.longCandidates)) {
        $status = if ($candidate.signalStatus -eq "watch") { "watch only" } else { "actionable" }
        $lines.Add(("{0}. [{1}] {2} | score {3} | 6h {4} | vol {5}x" -f $rank, $status, $candidate.symbol, [Math]::Round([double]$candidate.biasScore, 0), (Format-SignedPercent -Value ([double]$candidate.move6hPct) -Digits 2), [Math]::Round([double]$candidate.volumeRatio, 2)))
        $rank += 1
    }

    $lines.Add("")
    $lines.Add("Short watchlist")
    $rank = 1
    foreach ($candidate in @($Report.shortCandidates)) {
        $status = if ($candidate.signalStatus -eq "watch") { "watch only" } else { "actionable" }
        $lines.Add(("{0}. [{1}] {2} | score {3} | 6h {4} | vol {5}x" -f $rank, $status, $candidate.symbol, [Math]::Round([double]$candidate.biasScore, 0), (Format-SignedPercent -Value ([double]$candidate.move6hPct) -Digits 2), [Math]::Round([double]$candidate.volumeRatio, 2)))
        $rank += 1
    }

    $lines.Add("")
    $lines.Add("Reminder: probabilistic watchlist only, not financial advice.")
    return ($lines -join [Environment]::NewLine)
}

function Send-TelegramNotification {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Config,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Config.Telegram.Enabled) {
        return
    }

    if (-not $Config.Telegram.BotToken -or -not $Config.Telegram.ChatId) {
        throw "Telegram is enabled but BotToken or ChatId is missing."
    }

    $uri = "https://api.telegram.org/bot{0}/sendMessage" -f $Config.Telegram.BotToken
    $payload = @{
        chat_id = $Config.Telegram.ChatId
        text = $Message
    }

    Invoke-RestMethod -Method Post -Uri $uri -Body $payload -TimeoutSec 25 | Out-Null
}

function Send-DiscordNotification {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Config,
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Config.Discord.Enabled) {
        return
    }

    if (-not $Config.Discord.WebhookUrl) {
        throw "Discord is enabled but WebhookUrl is missing."
    }

    $payload = @{
        content = $Message
    } | ConvertTo-Json

    Invoke-RestMethod -Method Post -Uri $Config.Discord.WebhookUrl -Body $payload -ContentType "application/json" -TimeoutSec 25 | Out-Null
}

function Send-MorningFuturesNotifications {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Config,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Report
    )

    $message = Format-MorningFuturesNotification -Report $Report
    Send-TelegramNotification -Config $Config -Message $message
    Send-DiscordNotification -Config $Config -Message $message
}
