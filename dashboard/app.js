window.__MORNING_FUTURES_APP_LOADED__ = true;

(() => {
  const APP_CONFIG = {
    universeSize: 50,
    topPicks: 8,
    minQuoteVolumeUsd: 10_000_000,
    klineLookbackHours: 240,
    okxHosts: [
      "https://www.okx.com",
      "https://app.okx.com",
      "https://my.okx.com",
      "https://us.okx.com"
    ],
    preferredSymbols: [
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
    ]
  };

  const refreshButton = document.getElementById("refresh-button");
  const refreshStatus = document.getElementById("refresh-status");
  const sampleBadge = document.getElementById("sample-badge");
  const warningPanel = document.getElementById("warning-panel");
  const warningTitle = document.getElementById("warning-title");
  const warningPill = document.getElementById("warning-pill");
  const warningCopy = document.getElementById("warning-copy");
  const warningList = document.getElementById("warning-list");
  const languageButtons = [...document.querySelectorAll(".lang-button")];

  const I18N = {
    en: {
      heroTitle: "Morning Futures Pulse",
      heroCopyIdle: "Pull live public OKX market data in the browser and rebuild the watchlist on demand.",
      refreshButton: "Refresh Live Data",
      refreshingButton: "Refreshing...",
      badgeLive: "Live OKX",
      badgeIdle: "Browser Build",
      statusReady: "The dashboard rebuilds the report in your browser from public OKX market data.",
      statusBusy: "Pulling public OKX market data and recalculating the watchlist...",
      statusUpdated: "Live report rebuilt from public OKX market data.",
      statusUpdatedWarnings_one: "Live report rebuilt with 1 warning.",
      statusUpdatedWarnings_many: "Live report rebuilt with {count} warnings.",
      statusNoReport: "No live report is loaded yet. Use the refresh button to build one.",
      statusErrorPrefix: "Refresh failed",
      warningTitle: "Warnings",
      warningPill_one: "1 note",
      warningPill_many: "{count} notes",
      warningCopy_one: "The latest refresh included one note worth reviewing.",
      warningCopy_many: "The latest refresh included {count} notes worth reviewing.",
      marketRegime: "Market Regime",
      coverageLabel: "Tracked Pairs",
      coverageNote: "Pairs above the minimum quote-volume filter.",
      coverageFearNote: "Fear & Greed {value} / 100 ({label})",
      generated: "Generated",
      longTitle: "Long Watchlist",
      shortTitle: "Short Watchlist",
      longPill: "Long Bias",
      shortPill: "Short Bias",
      summaryTitle: "Market Summary",
      summaryPill: "Context",
      viewsTitle: "Market Views",
      viewsPill: "Playbook",
      sourceTitle: "Live Sources",
      sourcePill: "Feeds",
      noLongs: "No long setups cleared the minimum quality filter in this refresh.",
      noShorts: "No short setups cleared the minimum quality filter in this refresh.",
      noSummary: "The dashboard is waiting for a live report.",
      noSources: "Source details will appear after a successful refresh.",
      noViews: "Market views will appear after a live refresh.",
      viewCommon: "Common view",
      viewMyRead: "My read",
      viewRiskTitle: "Risk First",
      viewRiskCommon: "Many futures traders start with leverage, liquidation distance, stop placement, and position size before looking for upside.",
      viewRiskRead: "This dashboard treats risk filters as gates. If the setup is too extended, too volatile, or too new, it should not become actionable just because the score is high.",
      viewMomentumTitle: "Momentum",
      viewMomentumCommon: "Trend-following traders favor relative strength, rising participation, and continuation while the broader tape supports risk.",
      viewMomentumRead: "Momentum is useful here only after overextension checks. Strong 6h/24h moves are monitored, but extreme moves are demoted to watch-only or removed.",
      viewFundingTitle: "Funding / Crowding",
      viewFundingCommon: "Perpetual futures traders watch funding as a crowding signal: expensive longs or shorts can warn that one side is crowded.",
      viewFundingRead: "Funding is a supporting input, not a standalone trigger. It can improve or weaken a candidate, but it should not override price structure.",
      viewLiquidityTitle: "Liquidity",
      viewLiquidityCommon: "Some traders wait for stop runs, failed breakouts, or liquidity sweeps before entering, especially around obvious highs and lows.",
      viewLiquidityRead: "This is promising but not fully integrated yet. Treat liquidity-grab ideas as a separate experiment to validate with the harness before using them in scoring.",
      viewMeanTitle: "Mean Reversion",
      viewMeanCommon: "Countertrend traders look for stretched moves to fade after exhaustion, usually with tight invalidation.",
      viewMeanRead: "This dashboard does not mix mean reversion into actionable trend signals. Stretched moves are filtered first; a separate reversion model would be safer.",
      reportFallback: "The report compares liquid perpetual swaps, measures intraday pressure, and highlights the strongest and weakest names right now.",
      regimeNote: "Regime score {score} with {breadth}% positive breadth.",
      fearUnavailable: "Fear and Greed feed unavailable.",
      generatedMissing: "No live timestamp found.",
      generatedLatest: "Live browser-generated briefing.",
      scoreSuffixLong: "long score",
      scoreSuffixShort: "short score",
      chipPrice: "Price",
      chipMove6h: "6h",
      chipMove24h: "24h",
      chipFunding: "Funding",
      chipVolume: "Volume",
      chipConfidence: "Confidence",
      chipBandWidth: "Band width",
      chipActionable: "Actionable",
      chipWatchOnly: "Watch Only",
      chipBlocked: "High-Risk Watch",
      perspectiveTitle: "Trader Perspectives",
      perspectiveMomentum: "Momentum",
      perspectiveBollinger: "Bollinger",
      perspectiveFunding: "Funding",
      perspectiveLiquidity: "Liquidity",
      perspectiveMeanReversion: "Mean reversion",
      perspectiveStructure: "Structure",
      verdictLong: "Long-friendly",
      verdictShort: "Short-friendly",
      verdictNeutral: "Neutral",
      verdictCaution: "Caution",
      noTradePlan: "No trade plan is shown because this setup has risk blocks. Use it as context only.",
      planTitle: "Simple Plan",
      planCurrentPrice: "Current Price",
      planHoldWindow: "Hold Window",
      planTp1: "Take Profit 1",
      planTp2: "Take Profit 2",
      planStopLoss: "Stop Loss",
      planLeverage: "Leverage",
      planExitStyle: "Exit Style",
      planExitStyleLong: "Scale out",
      planExitStyleShort: "Cover in parts",
      planMoveFromHere: "{value} from here",
      planRiskBudget: "{value} risk budget",
      planScaleOut: "Scale-Out Guide",
      planLogic: "Why these prices",
      planStarter: "Beginner note",
      invalidationLabel: "Invalidate if:",
      reasonsFallback: "No supporting notes were included for this candidate.",
      summaryBreadthTitle: "Breadth and regime",
      summaryBroadTitle: "Broad market breadth",
      summaryBroadBody: "{breadth}% of tracked liquid pairs are green.",
      summaryWeakTitle: "Weakest liquid names",
      summaryWeakBody: "These are lagging across the tracked futures universe.",
      summaryWeakFallback: "Not enough laggard data yet.",
      summaryFearBody: "Fear & Greed {value} / 100 ({label}).",
      chartTitle: "Chart View",
      chartMeta: "Last 24h - Bollinger({period}, {deviation})",
      bandUpper: "Upper Band",
      bandBasis: "Basis",
      bandLower: "Lower Band",
      scoreDriversTitle: "Score Drivers",
      technicalReadTitle: "Technical Read",
      driverMomentumTrend: "Momentum + trend",
      driverBollinger: "Bollinger alignment",
      driverMarketRegime: "Market regime",
      driverOpportunity: "Volume + volatility",
      driverFunding: "Funding crowding",
      levelSupport: "Support",
      levelResistance: "Resistance",
      levelEntry: "Entry",
      levelStop: "Stop",
      levelTp1: "TP1",
      levelTp2: "TP2",
      sourceStatusLive: "Live public data",
      sourceStatusOptional: "Optional context",
      footerFallback: "This is a watchlist helper built from public market data, not financial advice."
    },
    ko: {
      heroTitle: "모닝 선물 브리프",
      heroCopyIdle: "브라우저에서 OKX 공개 데이터를 직접 불러와서 보고서를 즉시 다시 계산합니다.",
      refreshButton: "실시간 데이터 새로고침",
      refreshingButton: "새로고침 중...",
      badgeLive: "실시간 OKX",
      badgeIdle: "브라우저 계산",
      statusReady: "이 대시보드는 브라우저에서 OKX 공개 데이터를 직접 읽어 실시간으로 다시 계산합니다.",
      statusBusy: "OKX 공개 데이터를 불러와 감시 리스트를 다시 계산하는 중입니다...",
      statusUpdated: "공개 OKX 데이터 기준으로 리포트를 다시 계산했습니다.",
      statusUpdatedWarnings_one: "리포트를 다시 계산했고 경고가 1개 있습니다.",
      statusUpdatedWarnings_many: "리포트를 다시 계산했고 경고가 {count}개 있습니다.",
      statusNoReport: "아직 실시간 리포트가 없습니다. 새로고침 버튼으로 먼저 계산해보세요.",
      statusErrorPrefix: "새로고침 실패",
      warningTitle: "경고",
      warningPill_one: "메모 1개",
      warningPill_many: "메모 {count}개",
      warningCopy_one: "이번 계산에서 확인해두면 좋을 메모가 1개 있습니다.",
      warningCopy_many: "이번 계산에서 확인해두면 좋을 메모가 {count}개 있습니다.",
      marketRegime: "시장 분위기",
      coverageLabel: "추적 종목 수",
      coverageNote: "최소 거래대금 기준을 넘긴 종목들입니다.",
      coverageFearNote: "공포/탐욕 {value} / 100 ({label})",
      generated: "생성 시각",
      longTitle: "롱 감시 종목",
      shortTitle: "숏 감시 종목",
      longPill: "롱 우위",
      shortPill: "숏 우위",
      summaryTitle: "시장 요약",
      summaryPill: "맥락",
      viewsTitle: "시장 관점",
      viewsPill: "플레이북",
      sourceTitle: "실시간 출처",
      sourcePill: "데이터",
      noLongs: "이번 계산에서는 기준을 통과한 롱 후보가 없습니다.",
      noShorts: "이번 계산에서는 기준을 통과한 숏 후보가 없습니다.",
      noSummary: "실시간 리포트를 기다리는 중입니다.",
      noSources: "새로고침이 완료되면 데이터 출처가 여기에 표시됩니다.",
      noViews: "실시간 갱신 후 시장 관점이 표시됩니다.",
      viewCommon: "일반적인 관점",
      viewMyRead: "내 판단",
      viewRiskTitle: "리스크 우선",
      viewRiskCommon: "많은 선물 트레이더는 방향보다 먼저 레버리지, 청산 거리, 손절 위치, 포지션 크기를 봅니다.",
      viewRiskRead: "이 대시보드는 리스크 필터를 관문으로 봅니다. 과확장, 고변동성, 짧은 히스토리 종목은 점수가 높아도 진입 후보가 되면 안 됩니다.",
      viewMomentumTitle: "모멘텀",
      viewMomentumCommon: "추세 추종 관점은 상대강도, 거래 참여 증가, 시장 분위기가 받쳐주는 지속 흐름을 선호합니다.",
      viewMomentumRead: "여기서는 과확장 확인을 통과한 모멘텀만 유효합니다. 6시간/24시간 강한 움직임은 보되, 극단 움직임은 관심 후보로 낮추거나 제외합니다.",
      viewFundingTitle: "펀딩 / 쏠림",
      viewFundingCommon: "무기한 선물 트레이더는 펀딩비를 포지션 쏠림 신호로 봅니다. 롱이나 숏 비용이 비싸면 한쪽이 과밀할 수 있습니다.",
      viewFundingRead: "펀딩은 보조 입력입니다. 후보를 조금 강화하거나 약화시킬 수 있지만, 가격 구조를 뒤집는 단독 트리거로 쓰지는 않습니다.",
      viewLiquidityTitle: "유동성",
      viewLiquidityCommon: "일부 트레이더는 명확한 고점/저점 근처의 스탑런, 돌파 실패, 유동성 sweep 이후 진입을 기다립니다.",
      viewLiquidityRead: "가능성은 있지만 아직 완전히 통합하지 않았습니다. 유동성 사냥 아이디어는 별도 실험으로 만들고 하네스로 검증한 뒤 점수에 넣는 게 안전합니다.",
      viewMeanTitle: "평균회귀",
      viewMeanCommon: "역추세 트레이더는 과하게 뻗은 움직임이 힘을 잃을 때 짧은 무효화 기준으로 되돌림을 노립니다.",
      viewMeanRead: "이 대시보드는 평균회귀를 추세 진입 신호와 섞지 않습니다. 과확장 움직임은 먼저 걸러내고, 되돌림 전략은 별도 모델로 분리하는 편이 낫습니다.",
      reportFallback: "유동성이 높은 무기한 선물들을 비교해서 지금 상대적으로 강한 종목과 약한 종목을 추려냅니다.",
      regimeNote: "시장 점수 {score}, 상승 폭은 {breadth}%입니다.",
      fearUnavailable: "공포/탐욕 지수를 가져오지 못했습니다.",
      generatedMissing: "생성 시각이 없습니다.",
      generatedLatest: "브라우저에서 직접 생성한 리포트입니다.",
      scoreSuffixLong: "롱 점수",
      scoreSuffixShort: "숏 점수",
      chipPrice: "현재가",
      chipMove6h: "6시간",
      chipMove24h: "24시간",
      chipFunding: "펀딩비",
      chipVolume: "거래량",
      chipConfidence: "신뢰도",
      chipBandWidth: "밴드 폭",
      chipActionable: "진입 후보",
      chipWatchOnly: "관심 후보",
      chipBlocked: "고위험 관찰",
      perspectiveTitle: "트레이더 관점",
      perspectiveMomentum: "모멘텀",
      perspectiveBollinger: "볼린저",
      perspectiveFunding: "펀딩",
      perspectiveLiquidity: "유동성",
      perspectiveMeanReversion: "평균회귀",
      perspectiveStructure: "구조",
      verdictLong: "롱 우호",
      verdictShort: "숏 우호",
      verdictNeutral: "중립",
      verdictCaution: "주의",
      noTradePlan: "리스크 블록이 있어 거래 계획은 표시하지 않습니다. 맥락으로만 보세요.",
      planTitle: "간단 계획",
      planCurrentPrice: "현재가",
      planHoldWindow: "권장 보유",
      planTp1: "1차 익절",
      planTp2: "2차 익절",
      planStopLoss: "손절 기준",
      planLeverage: "권장 레버리지",
      planExitStyle: "정리 방식",
      planExitStyleLong: "분할 익절",
      planExitStyleShort: "분할 청산",
      planMoveFromHere: "현재가 대비 {value}",
      planRiskBudget: "위험 범위 {value}",
      planScaleOut: "분할 정리 가이드",
      planLogic: "이 가격을 잡은 이유",
      planStarter: "초보자 메모",
      invalidationLabel: "무효화 조건:",
      reasonsFallback: "이 후보에 대한 추가 메모가 없습니다.",
      summaryBreadthTitle: "시장 강도와 분위기",
      summaryBroadTitle: "시장 전반 상승 폭",
      summaryBroadBody: "추적 중인 유동성 종목의 {breadth}%가 상승 중입니다.",
      summaryWeakTitle: "상대적으로 약한 종목",
      summaryWeakBody: "추적 중인 선물 종목 가운데 상대적으로 약한 이름들입니다.",
      summaryWeakFallback: "약세 종목 데이터가 아직 충분하지 않습니다.",
      summaryFearBody: "공포/탐욕 {value} / 100 ({label})",
      chartTitle: "차트 보기",
      chartMeta: "최근 24시간 - 볼린저({period}, {deviation})",
      bandUpper: "상단 밴드",
      bandBasis: "기준선",
      bandLower: "하단 밴드",
      scoreDriversTitle: "점수 구성",
      technicalReadTitle: "기술적 해석",
      driverMomentumTrend: "모멘텀 + 추세",
      driverBollinger: "볼린저 정렬",
      driverMarketRegime: "시장 분위기",
      driverOpportunity: "거래량 + 변동성",
      driverFunding: "펀딩 혼잡도",
      levelSupport: "지지",
      levelResistance: "저항",
      levelEntry: "진입",
      levelStop: "손절",
      levelTp1: "1차",
      levelTp2: "2차",
      sourceStatusLive: "실시간 공개 데이터",
      sourceStatusOptional: "보조 지표",
      footerFallback: "이 화면은 공개 시장 데이터를 바탕으로 만든 감시 도구이며 투자 조언이 아닙니다."
    }
  };

  let currentLang = localStorage.getItem("morning-futures-lang") === "ko" ? "ko" : "en";
  let currentReport = null;
  const REFRESH_COOLDOWN_MS = 30_000;
  const RISK_FILTER = {
    minimumHistoryCandles: 168,
    maxLongMove6hPct: 2.6,
    maxLongMove24hPct: 3.2,
    maxShortMove6hPct: -2.6,
    maxShortMove24hPct: -3.2,
    maxLookbackMovePct: 25,
    maxAverageHourlyRangePct: 4.5,
    extendedBandPosition: 0.85,
    extendedBandMove6hPct: 1.8,
    counterTrendMove6hPct: 1.6
  };
  let lastRefreshTime = 0;
  let isRefreshing = false;
  let statusModel = { type: "ready" };

  const t = (key, vars = {}) => {
    const template = I18N[currentLang][key] ?? I18N.en[key] ?? key;
    return template.replace(/\{(\w+)\}/g, (_, token) => String(vars[token] ?? ""));
  };

  const localeTag = () => currentLang === "ko" ? "ko-KR" : "en-US";

  const localized = (en, ko) => ({ en, ko });

  const pickText = (value, fallback = "") => {
    if (typeof value === "string") {
      return value;
    }
    if (!value || typeof value !== "object") {
      return fallback;
    }
    if (currentLang === "ko") {
      return value.ko ?? value.en ?? fallback;
    }
    return value.en ?? value.ko ?? fallback;
  };

  const pickArray = (items) => Array.isArray(items) ? items.map((item) => pickText(item)).filter(Boolean) : [];

  const clampNumber = (value, minimum, maximum) => Math.min(maximum, Math.max(minimum, value));

  const normalizeNumber = (value, scale) => scale === 0 ? 0 : clampNumber(value / scale, -1, 1);

  const getAverage = (values) => {
    const items = values.filter((value) => Number.isFinite(Number(value))).map(Number);
    if (!items.length) {
      return 0;
    }
    return items.reduce((sum, value) => sum + value, 0) / items.length;
  };

  const getStandardDeviation = (values) => {
    const items = values.filter((value) => Number.isFinite(Number(value))).map(Number);
    if (!items.length) {
      return 0;
    }
    const average = getAverage(items);
    const sumOfSquares = items.reduce((sum, value) => sum + ((value - average) ** 2), 0);
    return Math.sqrt(sumOfSquares / items.length);
  };

  const getPercentChange = (baseValue, currentValue) => {
    if (!Number.isFinite(baseValue) || baseValue === 0) {
      return 0;
    }
    return ((currentValue - baseValue) / baseValue) * 100;
  };

  const formatSignedPct = (value, digits = 2) => {
    const numericValue = Number(value);
    if (!Number.isFinite(numericValue)) {
      return "N/A";
    }
    if (numericValue >= 0) {
      return `+${numericValue.toFixed(digits)}%`;
    }
    return `${numericValue.toFixed(digits)}%`;
  };

  const getPriceDigits = (value) => {
    const numericValue = Math.abs(Number(value));
    if (!Number.isFinite(numericValue) || numericValue === 0) {
      return 4;
    }
    if (numericValue >= 100) {
      return 2;
    }
    if (numericValue >= 1) {
      return 3;
    }
    if (numericValue >= 0.1) {
      return 4;
    }
    if (numericValue >= 0.01) {
      return 5;
    }
    return 6;
  };

  const roundTradePrice = (value) => {
    const numericValue = Number(value);
    if (!Number.isFinite(numericValue)) {
      return numericValue;
    }
    return Number(numericValue.toFixed(getPriceDigits(numericValue)));
  };

  const formatPrice = (value) => {
    const numericValue = Number(value);
    if (!Number.isFinite(numericValue)) {
      return "N/A";
    }
    return numericValue.toLocaleString(localeTag(), {
      minimumFractionDigits: getPriceDigits(numericValue),
      maximumFractionDigits: getPriceDigits(numericValue)
    });
  };

  const formatContribution = (value) => {
    const numericValue = Number(value);
    if (!Number.isFinite(numericValue)) {
      return "N/A";
    }
    return numericValue >= 0 ? `+${numericValue.toFixed(1)}` : numericValue.toFixed(1);
  };

  const getLastItems = (items, count) => items.length <= count ? [...items] : items.slice(items.length - count);

  const getWindowBeforeTail = (items, tailCount, windowSize) => {
    const end = items.length - tailCount;
    if (end <= 0) {
      return [];
    }
    const start = Math.max(0, end - windowSize);
    return items.slice(start, end);
  };

  const convertToOkxInstId = (symbol) => {
    const normalized = String(symbol || "").trim().toUpperCase();
    if (/^[A-Z0-9]+-USDT-SWAP$/.test(normalized)) {
      return normalized;
    }
    if (/^[A-Z0-9]+USDT$/.test(normalized)) {
      return `${normalized.slice(0, -4)}-USDT-SWAP`;
    }
    return normalized;
  };

  const getOkx24hChangePct = (ticker) => getPercentChange(Number(ticker.open24h), Number(ticker.last));

  const getOkxNotionalVolumeUsd = (ticker) => Number(ticker.last) * Number(ticker.volCcy24h);

  const translateFearLabel = (label) => {
    const map = {
      "Extreme Fear": localized("Extreme Fear", "극도의 공포"),
      Fear: localized("Fear", "공포"),
      Neutral: localized("Neutral", "중립"),
      Greed: localized("Greed", "탐욕"),
      "Extreme Greed": localized("Extreme Greed", "극도의 탐욕")
    };
    return map[label] ?? localized(label || "N/A", label || "N/A");
  };

  const fetchJson = async (url) => {
    const response = await fetch(url, {
      cache: "no-store",
      headers: {
        Accept: "application/json, text/plain, */*"
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status} from ${new URL(url).host}`);
    }

    return response.json();
  };

  const fetchOkxJson = async (path) => {
    let lastError = null;

    for (const host of APP_CONFIG.okxHosts) {
      try {
        return await fetchJson(`${host}${path}`);
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? new Error("Unable to reach the OKX public API.");
  };

  const mapWithConcurrency = async (items, limit, mapper) => {
    const results = new Array(items.length);
    let nextIndex = 0;

    const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
      while (true) {
        const currentIndex = nextIndex;
        nextIndex += 1;

        if (currentIndex >= items.length) {
          return;
        }

        results[currentIndex] = await mapper(items[currentIndex], currentIndex);
      }
    });

    await Promise.all(workers);
    return results;
  };

  const convertToKlineObjects = (klines) => {
    return [...klines]
      .map((item) => {
        const openTime = new Date(Number(item[0]));
        return {
          openTime: openTime.toISOString(),
          open: Number(item[1]),
          high: Number(item[2]),
          low: Number(item[3]),
          close: Number(item[4]),
          volume: Number(item[6]),
          quoteVolume: Number(item[7])
        };
      })
      .sort((a, b) => new Date(a.openTime) - new Date(b.openTime));
  };

  const getBollingerSeries = (candles, period = 20, stdDevMultiplier = 2) => {
    if (candles.length < period) {
      return [];
    }

    const series = [];

    for (let index = period - 1; index < candles.length; index += 1) {
      const window = candles.slice(index - period + 1, index + 1);
      const closes = window.map((candle) => candle.close);
      const basis = getAverage(closes);
      const stdDev = getStandardDeviation(closes);
      const upper = basis + (stdDevMultiplier * stdDev);
      const lower = basis - (stdDevMultiplier * stdDev);
      const widthPct = basis !== 0 ? ((upper - lower) / basis) * 100 : 0;
      const candle = candles[index];

      series.push({
        openTime: candle.openTime,
        open: Number(candle.open.toFixed(6)),
        high: Number(candle.high.toFixed(6)),
        low: Number(candle.low.toFixed(6)),
        close: Number(candle.close.toFixed(6)),
        basis: Number(basis.toFixed(6)),
        upper: Number(upper.toFixed(6)),
        lower: Number(lower.toFixed(6)),
        widthPct: Number(widthPct.toFixed(2))
      });
    }

    return series;
  };

  const getSymbolUniverse = (tickers) => {
    const eligible = tickers
      .filter((ticker) => /^[A-Z0-9]+-USDT-SWAP$/.test(String(ticker.instId)))
      .filter((ticker) => getOkxNotionalVolumeUsd(ticker) >= APP_CONFIG.minQuoteVolumeUsd)
      .sort((a, b) => getOkxNotionalVolumeUsd(b) - getOkxNotionalVolumeUsd(a));

    return eligible.slice(0, APP_CONFIG.universeSize);
  };

  const getFundingMap = async (instIds) => {
    const entries = await mapWithConcurrency(instIds, 4, async (instId) => {
      try {
        const encodedInstId = encodeURIComponent(instId);
        const response = await fetchOkxJson(`/api/v5/public/funding-rate?instId=${encodedInstId}`);
        if (response.data && response.data[0]) {
          return [instId, response.data[0]];
        }
      } catch (error) {
        return null;
      }
      return null;
    });

    return entries.reduce((map, entry) => {
      if (entry) {
        map[entry[0]] = entry[1];
      }
      return map;
    }, {});
  };

  const getMarketContext = async (universeTickers) => {
    let fearGreed = null;

    try {
      const fearResponse = await fetchJson("https://api.alternative.me/fng/?limit=1&format=json");
      const fearValue = Number(fearResponse?.data?.[0]?.value);
      const fearLabel = fearResponse?.data?.[0]?.value_classification;

      if (Number.isFinite(fearValue)) {
        fearGreed = {
          value: fearValue,
          label: translateFearLabel(fearLabel)
        };
      }
    } catch (error) {
      fearGreed = null;
    }

    const positiveBreadth = universeTickers.filter((ticker) => getOkx24hChangePct(ticker) > 0).length;
    const breadthPct = universeTickers.length ? (positiveBreadth / universeTickers.length) * 100 : 0;
    const btc = universeTickers.find((ticker) => ticker.instId === "BTC-USDT-SWAP");
    const eth = universeTickers.find((ticker) => ticker.instId === "ETH-USDT-SWAP");
    const btcChange = btc ? getOkx24hChangePct(btc) : 0;
    const ethChange = eth ? getOkx24hChangePct(eth) : 0;
    const fearScore = fearGreed ? normalizeNumber(fearGreed.value - 50, 20) : 0;
    const breadthScore = normalizeNumber(breadthPct - 50, 20);
    const btcScore = normalizeNumber(btcChange, 8);
    const ethScore = normalizeNumber(ethChange, 10);
    const regimeScore = (0.35 * btcScore) + (0.25 * ethScore) + (0.25 * breadthScore) + (0.15 * fearScore);

    let regimeLabel = localized("Mixed / Rotation", "혼조 / 순환장");
    if (regimeScore >= 0.45) {
      regimeLabel = localized("Constructive Risk-On", "강한 위험선호");
    } else if (regimeScore >= 0.15) {
      regimeLabel = localized("Mild Risk-On", "완만한 위험선호");
    } else if (regimeScore <= -0.45) {
      regimeLabel = localized("Defensive Risk-Off", "방어적 위험회피");
    } else if (regimeScore <= -0.15) {
      regimeLabel = localized("Mild Risk-Off", "완만한 위험회피");
    }

    let summary = localized(
      "The tape is balanced enough that relative strength and relative weakness matter more than making an all-market directional call.",
      "시장 전체 방향을 단정하기보다 종목별 상대강도와 상대약세를 구분해서 보는 편이 더 중요합니다."
    );

    if (regimeScore >= 0.15) {
      summary = localized(
        "BTC and ETH are holding up, breadth is constructive, and continuation setups deserve more attention than panic fades.",
        "BTC와 ETH가 버텨주고 있고 상승 폭도 괜찮아서, 급락 반등보다는 추세 지속 세팅을 더 우선해서 볼 만합니다."
      );
    } else if (regimeScore <= -0.15) {
      summary = localized(
        "Broad risk appetite is soft enough that downside continuation and failed-bounce setups deserve extra attention.",
        "전반적인 위험선호가 약해서 하락 지속이나 반등 실패 패턴을 조금 더 조심해서 볼 필요가 있습니다."
      );
    }

    const leaders = [...universeTickers]
      .sort((left, right) => getOkx24hChangePct(right) - getOkx24hChangePct(left))
      .slice(0, 3)
      .map((ticker) => ({
        symbol: ticker.instId,
        change24hPct: Number(getOkx24hChangePct(ticker).toFixed(2))
      }));

    const laggards = [...universeTickers]
      .sort((left, right) => getOkx24hChangePct(left) - getOkx24hChangePct(right))
      .slice(0, 3)
      .map((ticker) => ({
        symbol: ticker.instId,
        change24hPct: Number(getOkx24hChangePct(ticker).toFixed(2))
      }));

    return {
      regimeLabel,
      regimeScore: Number(regimeScore.toFixed(3)),
      breadthPositivePct: Number(breadthPct.toFixed(1)),
      summary,
      fearGreed,
      leaders,
      laggards,
      trackedCount: universeTickers.length
    };
  };

  const newScoreFromMetrics = ({
    change3hPct,
    change6hPct,
    change24hPct,
    trendWinRate,
    volumeRatio,
    fundingRatePct,
    volatilityPct,
    marketRegimeScore,
    bollingerPosition = 0,
    bollingerBasisSlopePct = 0,
    bollingerWidthRatio = 1
  }) => {
    const momentum = (0.45 * normalizeNumber(change6hPct, 4))
      + (0.35 * normalizeNumber(change24hPct, 8))
      + (0.20 * normalizeNumber(change3hPct, 2));
    const trend = normalizeNumber(trendWinRate, 1);
    const volume = normalizeNumber(volumeRatio - 1, 1.25);
    const volatility = normalizeNumber(volatilityPct, 3.5);
    const longCrowdingRelief = normalizeNumber(-1 * fundingRatePct, 0.04);
    const shortCrowdingRelief = normalizeNumber(fundingRatePct, 0.04);
    const overextendedLong = change6hPct > 5 ? 0.5 : 1.0;
    const overextendedShort = change6hPct < -5 ? 0.5 : 1.0;
    const bollingerPositionScore = bollingerPosition >= 0
      ? clampNumber(bollingerPosition, -1, 1) * overextendedLong
      : clampNumber(bollingerPosition, -1, 1) * overextendedShort;
    const bollingerBasisSlope = normalizeNumber(bollingerBasisSlopePct, 1.2);
    const bollingerExpansion = normalizeNumber(bollingerWidthRatio - 1, 0.6);

    const momentumTrendContribution = (22 * momentum) + (11 * trend);
    const marketRegimeContribution = 7 * marketRegimeScore;
    const bollingerContribution = (6 * bollingerPositionScore) + (4 * bollingerBasisSlope);
    const opportunityContribution = (10 * Math.max(0, volume))
      + (6 * volatility)
      + (3 * Math.max(0, bollingerExpansion));
    const longFundingContribution = 6 * longCrowdingRelief;
    const shortFundingContribution = 6 * shortCrowdingRelief;
    const directional = momentumTrendContribution + marketRegimeContribution + bollingerContribution;

    const longScore = clampNumber(50 + directional + opportunityContribution + longFundingContribution, 0, 100);
    const shortScore = clampNumber(50 - directional + opportunityContribution + shortFundingContribution, 0, 100);

    return {
      longScore: Number(longScore.toFixed(1)),
      shortScore: Number(shortScore.toFixed(1)),
      longEdge: Number((longScore - shortScore).toFixed(1)),
      shortEdge: Number((shortScore - longScore).toFixed(1)),
      momentumTrendContribution: Number(momentumTrendContribution.toFixed(1)),
      marketRegimeContribution: Number(marketRegimeContribution.toFixed(1)),
      bollingerContribution: Number(bollingerContribution.toFixed(1)),
      opportunityContribution: Number(opportunityContribution.toFixed(1)),
      longFundingContribution: Number(longFundingContribution.toFixed(1)),
      shortFundingContribution: Number(shortFundingContribution.toFixed(1))
    };
  };

  const getRiskProfile = ({
    candles,
    change6hPct,
    change24hPct,
    lookbackChangePct,
    volatilityPct,
    bollingerPosition,
    bandWidthRatio
  }) => {
    const riskFlags = [];
    const longBlocks = [];
    const shortBlocks = [];
    const historyDays = candles.length / 24;

    if (historyDays < 10) {
      riskFlags.push(localized(
        `${historyDays.toFixed(1)}d candle history`,
        `${historyDays.toFixed(1)}일 캔들 히스토리`
      ));
    }

    if (volatilityPct >= 3.2) {
      riskFlags.push(localized(
        `High average hourly range (${volatilityPct.toFixed(2)}%)`,
        `시간봉 평균 변동폭 높음 (${volatilityPct.toFixed(2)}%)`
      ));
    }

    if (Math.abs(lookbackChangePct) >= 25) {
      riskFlags.push(localized(
        `10d move is already ${formatSignedPct(lookbackChangePct, 1)}`,
        `10일 변동이 이미 ${formatSignedPct(lookbackChangePct, 1)}`
      ));
    }

    if (bandWidthRatio >= 1.45) {
      riskFlags.push(localized(
        `Bollinger bands expanded ${bandWidthRatio.toFixed(2)}x`,
        `볼린저 밴드가 ${bandWidthRatio.toFixed(2)}배 확장`
      ));
    }

    if (volatilityPct >= RISK_FILTER.maxAverageHourlyRangePct) {
      longBlocks.push(localized(
        `Skipped long: average hourly range is ${volatilityPct.toFixed(2)}%.`,
        `롱 제외: 시간봉 평균 변동폭이 ${volatilityPct.toFixed(2)}%입니다.`
      ));
      shortBlocks.push(localized(
        `Skipped short: average hourly range is ${volatilityPct.toFixed(2)}%.`,
        `숏 제외: 시간봉 평균 변동폭이 ${volatilityPct.toFixed(2)}%입니다.`
      ));
    }

    if (change6hPct >= RISK_FILTER.maxLongMove6hPct || change24hPct >= RISK_FILTER.maxLongMove24hPct) {
      longBlocks.push(localized(
        `Skipped long: move is extended (${formatSignedPct(change6hPct)} 6h, ${formatSignedPct(change24hPct)} 24h).`,
        `롱 제외: 상승이 과확장됐습니다 (6시간 ${formatSignedPct(change6hPct)}, 24시간 ${formatSignedPct(change24hPct)}).`
      ));
    }

    if (change6hPct <= RISK_FILTER.maxShortMove6hPct || change24hPct <= RISK_FILTER.maxShortMove24hPct) {
      shortBlocks.push(localized(
        `Skipped short: selloff is extended (${formatSignedPct(change6hPct)} 6h, ${formatSignedPct(change24hPct)} 24h).`,
        `숏 제외: 하락이 과확장됐습니다 (6시간 ${formatSignedPct(change6hPct)}, 24시간 ${formatSignedPct(change24hPct)}).`
      ));
    }

    if (change24hPct < 0 && change6hPct >= RISK_FILTER.counterTrendMove6hPct) {
      longBlocks.push(localized(
        `Skipped long: 6h rebound is fighting a negative 24h tape (${formatSignedPct(change24hPct)}).`,
        `롱 제외: 6시간 반등이 24시간 약세 흐름(${formatSignedPct(change24hPct)})과 충돌합니다.`
      ));
    }

    if (change24hPct > 0 && change6hPct <= -RISK_FILTER.counterTrendMove6hPct) {
      shortBlocks.push(localized(
        `Skipped short: 6h drop is fighting a positive 24h tape (${formatSignedPct(change24hPct)}).`,
        `숏 제외: 6시간 하락이 24시간 강세 흐름(${formatSignedPct(change24hPct)})과 충돌합니다.`
      ));
    }

    if (lookbackChangePct >= RISK_FILTER.maxLookbackMovePct) {
      longBlocks.push(localized(
        `Skipped long: 10d move is already ${formatSignedPct(lookbackChangePct, 1)}.`,
        `롱 제외: 10일 상승폭이 이미 ${formatSignedPct(lookbackChangePct, 1)}입니다.`
      ));
    }

    if (lookbackChangePct <= -RISK_FILTER.maxLookbackMovePct) {
      shortBlocks.push(localized(
        `Skipped short: 10d move is already ${formatSignedPct(lookbackChangePct, 1)}.`,
        `숏 제외: 10일 하락폭이 이미 ${formatSignedPct(lookbackChangePct, 1)}입니다.`
      ));
    }

    if (bollingerPosition >= RISK_FILTER.extendedBandPosition && change6hPct >= RISK_FILTER.extendedBandMove6hPct) {
      longBlocks.push(localized(
        "Skipped long: price is chasing the upper Bollinger extreme.",
        "롱 제외: 가격이 볼린저 상단 극단부를 추격 중입니다."
      ));
    }

    if (bollingerPosition <= -RISK_FILTER.extendedBandPosition && change6hPct <= -RISK_FILTER.extendedBandMove6hPct) {
      shortBlocks.push(localized(
        "Skipped short: price is chasing the lower Bollinger extreme.",
        "숏 제외: 가격이 볼린저 하단 극단부를 추격 중입니다."
      ));
    }

    return {
      riskFlags,
      riskBlocks: {
        long: longBlocks,
        short: shortBlocks
      }
    };
  };

  const getLiquiditySignal = (candles, lookback = 24) => {
    const items = Array.isArray(candles) ? candles : [];
    if (items.length < lookback + 2) {
      return {
        type: "none",
        direction: "neutral",
        label: localized("No sweep", "sweep 없음"),
        note: localized(
          "No clear liquidity sweep was detected on the latest hourly candle.",
          "최근 시간봉에서는 뚜렷한 유동성 sweep이 감지되지 않았습니다."
        )
      };
    }

    const current = items[items.length - 1];
    const priorWindow = getWindowBeforeTail(items, 1, lookback);
    const priorHigh = Math.max(...priorWindow.map((candle) => Number(candle.high)).filter(Number.isFinite));
    const priorLow = Math.min(...priorWindow.map((candle) => Number(candle.low)).filter(Number.isFinite));

    if (!Number.isFinite(priorHigh) || !Number.isFinite(priorLow)) {
      return {
        type: "none",
        direction: "neutral",
        label: localized("No sweep", "sweep 없음"),
        note: localized(
          "Liquidity context is unavailable because the recent high/low window is incomplete.",
          "최근 고점/저점 구간이 충분하지 않아 유동성 맥락을 계산하지 못했습니다."
        )
      };
    }

    const sweptLow = current.low < priorLow && current.close > priorLow && current.close > current.open;
    const sweptHigh = current.high > priorHigh && current.close < priorHigh && current.close < current.open;

    if (sweptLow) {
      return {
        type: "bullishSweep",
        direction: "long",
        level: roundTradePrice(priorLow),
        label: localized("Bullish sweep", "상방 sweep"),
        note: localized(
          `Price swept below ${formatPrice(priorLow)} and reclaimed it on the latest hourly candle.`,
          `최근 시간봉에서 ${formatPrice(priorLow)} 아래 유동성을 쓸고 다시 회복했습니다.`
        )
      };
    }

    if (sweptHigh) {
      return {
        type: "bearishSweep",
        direction: "short",
        level: roundTradePrice(priorHigh),
        label: localized("Bearish sweep", "하방 sweep"),
        note: localized(
          `Price swept above ${formatPrice(priorHigh)} and rejected it on the latest hourly candle.`,
          `최근 시간봉에서 ${formatPrice(priorHigh)} 위 유동성을 쓸고 다시 밀렸습니다.`
        )
      };
    }

    return {
      type: "none",
      direction: "neutral",
      label: localized("No sweep", "sweep 없음"),
      note: localized(
        "No clear liquidity sweep was detected on the latest hourly candle.",
        "최근 시간봉에서는 뚜렷한 유동성 sweep이 감지되지 않았습니다."
      )
    };
  };

  const getTechnicalChartNotes = ({
    bollingerPosition,
    bandWidthRatio,
    basisSlopePct,
    supportPrice,
    resistancePrice
  }) => {
    const notes = [];

    if (bollingerPosition >= 0.7 && bandWidthRatio >= 1.05) {
      notes.push(localized(
        "Price is pressing the upper Bollinger band while the bands expand, which supports bullish continuation if the basis holds.",
        "가격이 상단 볼린저 밴드를 밀고 있고 밴드도 벌어지고 있어, 기준선만 지키면 상승 추세 지속 쪽 해석이 더 자연스럽습니다."
      ));
    } else if (bollingerPosition >= 0.25) {
      notes.push(localized(
        "Price is holding above the Bollinger basis and leaning toward the upper band.",
        "가격이 볼린저 기준선 위에서 버티면서 상단 밴드 쪽으로 기울어져 있습니다."
      ));
    } else if (bollingerPosition <= -0.7 && bandWidthRatio >= 1.05) {
      notes.push(localized(
        "Price is pressing the lower Bollinger band while the bands expand, which keeps downside continuation in play.",
        "가격이 하단 볼린저 밴드를 밀고 있고 밴드도 벌어지고 있어, 하락 추세 지속 가능성을 열어둬야 합니다."
      ));
    } else if (bollingerPosition <= -0.25) {
      notes.push(localized(
        "Price is holding below the Bollinger basis and leaning toward the lower band.",
        "가격이 볼린저 기준선 아래에 머물며 하단 밴드 쪽으로 기울어져 있습니다."
      ));
    } else {
      notes.push(localized(
        "Price is hovering near the Bollinger basis, so the chart still looks balanced rather than impulsive.",
        "가격이 볼린저 기준선 부근에 있어 차트는 아직 강한 한쪽 추세보다 균형에 더 가깝습니다."
      ));
    }

    if (basisSlopePct >= 0.18) {
      notes.push(localized(
        `The Bollinger basis is sloping up by ${formatSignedPct(basisSlopePct, 2)}, which keeps short-term trend control with buyers.`,
        `볼린저 기준선이 ${formatSignedPct(basisSlopePct, 2)}만큼 위로 기울고 있어 단기 주도권은 매수 쪽에 있습니다.`
      ));
    } else if (basisSlopePct <= -0.18) {
      notes.push(localized(
        `The Bollinger basis is sloping down by ${formatSignedPct(basisSlopePct, 2)}, which keeps short-term trend control with sellers.`,
        `볼린저 기준선이 ${formatSignedPct(basisSlopePct, 2)}만큼 아래로 기울고 있어 단기 주도권은 매도 쪽에 있습니다.`
      ));
    } else {
      notes.push(localized(
        "The Bollinger basis is mostly flat, so the chart is still close to balance instead of a clean one-way trend.",
        "볼린저 기준선이 거의 평평해서 차트는 아직 한 방향 추세보다 균형 구간에 가깝습니다."
      ));
    }

    if (bandWidthRatio <= 0.85) {
      notes.push(localized(
        "Band width is tighter than its recent average, so a fresh volatility expansion could still be ahead.",
        "밴드 폭이 최근 평균보다 좁아서 변동성 확장이 한 번 더 나올 여지가 있습니다."
      ));
    } else if (bandWidthRatio >= 1.15) {
      notes.push(localized(
        "Band width is wider than its recent average, which confirms that the current move is active instead of sleepy.",
        "밴드 폭이 최근 평균보다 넓어서 현재 움직임이 실제로 살아 있다는 쪽에 무게가 실립니다."
      ));
    } else {
      notes.push(localized(
        "Band width is close to its recent average, so the move looks active but not unusually stretched.",
        "밴드 폭이 최근 평균과 비슷해서 움직임은 살아 있지만 과하게 늘어진 정도는 아닙니다."
      ));
    }

    notes.push(localized(
      `Recent range support is near ${formatPrice(supportPrice)} and resistance is near ${formatPrice(resistancePrice)}.`,
      `최근 범위 기준 지지는 ${formatPrice(supportPrice)} 부근이고 저항은 ${formatPrice(resistancePrice)} 부근입니다.`
    ));

    return notes;
  };

  const getSymbolSnapshot = async (ticker, fundingMap, marketRegimeScore) => {
    const symbol = String(ticker.instId);
    const encodedInstId = encodeURIComponent(symbol);
    const klineResponse = await fetchOkxJson(`/api/v5/market/candles?instId=${encodedInstId}&bar=1H&limit=${APP_CONFIG.klineLookbackHours}`);
    const candles = convertToKlineObjects(klineResponse.data || []);

    if (candles.length < RISK_FILTER.minimumHistoryCandles) {
      throw new Error(`Only ${candles.length} hourly candles returned for ${symbol}; skipping short-history listing risk.`);
    }

    const lastPrice = candles[candles.length - 1].close;
    const change3hPct = getPercentChange(candles[candles.length - 4].close, lastPrice);
    const change6hPct = getPercentChange(candles[candles.length - 7].close, lastPrice);
    const change24hPct = getPercentChange(candles[candles.length - 25].close, lastPrice);
    const lookbackChangePct = getPercentChange(candles[0].close, lastPrice);

    const recentCandles = getLastItems(candles, 6);
    const recent6Closes = recentCandles.map((candle) => candle.close);
    const prior6Candles = getWindowBeforeTail(candles, 6, 6);
    const prior6Closes = prior6Candles.map((candle) => candle.close);
    const recent6Avg = getAverage(recent6Closes);
    const prior6Avg = getAverage(prior6Closes) || 1;
    const trendWinRate = clampNumber((recent6Avg - prior6Avg) / Math.abs(prior6Avg), -1, 1);

    const baselineCandles = getWindowBeforeTail(candles, 6, 30);
    const recentVolume = getAverage(recentCandles.map((candle) => candle.quoteVolume));
    const baselineVolume = getAverage(baselineCandles.map((candle) => candle.quoteVolume));
    const volumeRatio = baselineVolume > 0 ? recentVolume / baselineVolume : 1;

    const rangeWindow = getLastItems(candles, 12);
    const volatilityPct = getAverage(rangeWindow.map((candle) => {
      if (!Number.isFinite(candle.open) || candle.open === 0) {
        return 0;
      }
      return ((candle.high - candle.low) / candle.open) * 100;
    }));

    const fundingRatePct = fundingMap[symbol] ? Number(fundingMap[symbol].fundingRate) * 100 : 0;
    const bollingerSeries = getBollingerSeries(candles, 20, 2);

    if (!bollingerSeries.length) {
      throw new Error(`Not enough candles returned to build Bollinger bands for ${symbol}.`);
    }

    const currentBollinger = bollingerSeries[bollingerSeries.length - 1];
    const priorBollingerWidths = getWindowBeforeTail(bollingerSeries, 1, 10);
    const averagePriorBandWidthPct = getAverage(priorBollingerWidths.map((item) => item.widthPct));
    const bandWidthRatio = averagePriorBandWidthPct > 0 ? currentBollinger.widthPct / averagePriorBandWidthPct : 1;
    const basisSlopePct = bollingerSeries.length >= 6
      ? getPercentChange(bollingerSeries[bollingerSeries.length - 6].basis, currentBollinger.basis)
      : 0;

    const halfBand = (currentBollinger.upper - currentBollinger.lower) / 2;
    const bollingerPosition = halfBand > 0
      ? clampNumber((lastPrice - currentBollinger.basis) / halfBand, -1, 1)
      : 0;

    const chartPoints = getLastItems(bollingerSeries, 24);
    const recentSupport = Math.min(...chartPoints.map((point) => point.low));
    const recentResistance = Math.max(...chartPoints.map((point) => point.high));
    const technicalNotes = getTechnicalChartNotes({
      bollingerPosition,
      bandWidthRatio,
      basisSlopePct,
      supportPrice: recentSupport,
      resistancePrice: recentResistance
    });
    const liquiditySignal = getLiquiditySignal(candles, 24);
    if (liquiditySignal.type !== "none") {
      technicalNotes.unshift(liquiditySignal.note);
    }
    const riskProfile = getRiskProfile({
      candles,
      change6hPct,
      change24hPct,
      lookbackChangePct,
      volatilityPct,
      bollingerPosition,
      bandWidthRatio
    });

    const scores = newScoreFromMetrics({
      change3hPct,
      change6hPct,
      change24hPct,
      trendWinRate,
      volumeRatio,
      fundingRatePct,
      volatilityPct,
      marketRegimeScore,
      bollingerPosition,
      bollingerBasisSlopePct: basisSlopePct,
      bollingerWidthRatio: bandWidthRatio
    });

    const longReasons = [];
    if (change6hPct > 1.5) {
      longReasons.push(localized(
        `6h momentum is running at ${formatSignedPct(change6hPct, 2)}.`,
        `6시간 모멘텀이 ${formatSignedPct(change6hPct, 2)}로 살아 있습니다.`
      ));
    }
    if (change24hPct > 3) {
      longReasons.push(localized(
        `24h trend remains positive at ${formatSignedPct(change24hPct, 2)}.`,
        `24시간 추세도 ${formatSignedPct(change24hPct, 2)}로 여전히 우상향입니다.`
      ));
    }
    if (volumeRatio >= 1.25) {
      longReasons.push(localized(
        `Quote volume is ${volumeRatio.toFixed(2)}x above its recent baseline.`,
        `거래대금이 최근 기준보다 ${volumeRatio.toFixed(2)}배 많습니다.`
      ));
    }
    if (trendWinRate >= 0.01) {
      longReasons.push(localized(
        `Recent 6h average price is ${formatSignedPct(trendWinRate * 100, 2)} versus the prior 6h average.`,
        `최근 6시간 평균 가격이 직전 6시간 평균보다 ${formatSignedPct(trendWinRate * 100, 2)} 높습니다.`
      ));
    }
    if (fundingRatePct <= -0.01) {
      longReasons.push(localized(
        `Funding at ${formatSignedPct(fundingRatePct, 3)} suggests short crowding.`,
        `펀딩비 ${formatSignedPct(fundingRatePct, 3)}는 숏 포지션이 몰려 있을 가능성을 보여줍니다.`
      ));
    }
    if (bollingerPosition >= 0.45) {
      longReasons.push(localized(
        "Price is holding above the Bollinger basis and leaning toward the upper band.",
        "가격이 볼린저 기준선 위에 있고 상단 밴드 쪽으로 기울어져 있습니다."
      ));
    }
    if (bandWidthRatio >= 1.1 && bollingerPosition >= 0.2) {
      longReasons.push(localized(
        "Bollinger bands are expanding, which currently supports continuation more than mean reversion.",
        "볼린저 밴드가 벌어지고 있어 평균회귀보다 추세 지속 쪽이 더 자연스럽습니다."
      ));
    }
    if (!longReasons.length) {
      longReasons.push(localized(
        "Relative strength is better than most tracked liquid futures pairs.",
        "추적 중인 다른 유동성 선물 종목보다 상대강도가 더 낫습니다."
      ));
    }

    const shortReasons = [];
    if (change6hPct < -1.5) {
      shortReasons.push(localized(
        `6h momentum is slipping at ${formatSignedPct(change6hPct, 2)}.`,
        `6시간 모멘텀이 ${formatSignedPct(change6hPct, 2)}로 약해지고 있습니다.`
      ));
    }
    if (change24hPct < -3) {
      shortReasons.push(localized(
        `24h trend remains weak at ${formatSignedPct(change24hPct, 2)}.`,
        `24시간 추세도 ${formatSignedPct(change24hPct, 2)}로 약한 편입니다.`
      ));
    }
    if (volumeRatio >= 1.25) {
      shortReasons.push(localized(
        `Selling pressure is active with ${volumeRatio.toFixed(2)}x baseline volume.`,
        `거래대금이 기준 대비 ${volumeRatio.toFixed(2)}배라 매도 압력이 살아 있습니다.`
      ));
    }
    if (trendWinRate <= -0.01) {
      shortReasons.push(localized(
        `Recent 6h average price is ${formatSignedPct(trendWinRate * 100, 2)} versus the prior 6h average.`,
        `최근 6시간 평균 가격이 직전 6시간 평균보다 ${formatSignedPct(trendWinRate * 100, 2)} 낮습니다.`
      ));
    }
    if (fundingRatePct >= 0.01) {
      shortReasons.push(localized(
        `Funding at ${formatSignedPct(fundingRatePct, 3)} hints that longs are still crowded.`,
        `펀딩비 ${formatSignedPct(fundingRatePct, 3)}는 롱 포지션이 여전히 혼잡하다는 신호일 수 있습니다.`
      ));
    }
    if (bollingerPosition <= -0.45) {
      shortReasons.push(localized(
        "Price is holding below the Bollinger basis and leaning toward the lower band.",
        "가격이 볼린저 기준선 아래에 있고 하단 밴드 쪽으로 기울어져 있습니다."
      ));
    }
    if (bandWidthRatio >= 1.1 && bollingerPosition <= -0.2) {
      shortReasons.push(localized(
        "Bollinger bands are expanding, which currently supports downside continuation more than snap-back risk.",
        "볼린저 밴드가 벌어지고 있어 급반등보다 하락 지속 쪽 해석이 더 자연스럽습니다."
      ));
    }
    if (!shortReasons.length) {
      shortReasons.push(localized(
        "Relative weakness is more persistent than the rest of the tracked basket.",
        "추적 중인 다른 종목보다 상대약세가 더 꾸준하게 이어지고 있습니다."
      ));
    }

    return {
      symbol,
      lastPrice: Number(lastPrice.toFixed(6)),
      move3hPct: Number(change3hPct.toFixed(2)),
      move6hPct: Number(change6hPct.toFixed(2)),
      move24hPct: Number(change24hPct.toFixed(2)),
      lookbackMovePct: Number(lookbackChangePct.toFixed(2)),
      trendWinRate: Number(trendWinRate.toFixed(3)),
      volumeRatio: Number(volumeRatio.toFixed(2)),
      fundingRatePct: Number(fundingRatePct.toFixed(4)),
      volatilityPct: Number(volatilityPct.toFixed(2)),
      longScore: scores.longScore,
      shortScore: scores.shortScore,
      longEdge: scores.longEdge,
      shortEdge: scores.shortEdge,
      longReasons,
      shortReasons,
      riskFlags: riskProfile.riskFlags,
      riskBlocks: riskProfile.riskBlocks,
      liquiditySignal,
      technicalNotes,
      chart: {
        points: chartPoints,
        support: roundTradePrice(recentSupport),
        resistance: roundTradePrice(recentResistance),
        bollingerPeriod: 20,
        bollingerDeviation: 2,
        widthPct: Number(currentBollinger.widthPct.toFixed(2)),
        widthRatio: Number(bandWidthRatio.toFixed(2)),
        basisSlopePct: Number(basisSlopePct.toFixed(2))
      },
      scoreComponents: {
        momentumTrend: scores.momentumTrendContribution,
        marketRegime: scores.marketRegimeContribution,
        bollinger: scores.bollingerContribution,
        opportunity: scores.opportunityContribution,
        longFunding: scores.longFundingContribution,
        shortFunding: scores.shortFundingContribution
      },
      longThesis: localized(
        `${symbol} is showing enough intraday continuation, participation, and crowding relief to stay on a bullish watchlist if the market regime holds.`,
        `${symbol}은 장중 추세 지속, 거래 참여, 포지션 혼잡 완화가 겹쳐서 시장 분위기만 유지되면 롱 감시 리스트에 둘 만합니다.`
      ),
      shortThesis: localized(
        `${symbol} is underperforming the broader liquid futures basket and still looks vulnerable to downside continuation if the tape does not recover.`,
        `${symbol}은 유동성 높은 선물 종목들 대비 상대약세가 이어지고 있어, 시장이 회복하지 못하면 추가 하락 쪽을 열어둬야 합니다.`
      )
    };
  };

  const newBeginnerTradePlan = ({ snapshot, direction, confidence }) => {
    const entryPrice = snapshot.lastPrice;
    const riskPct = clampNumber(Math.max(0.8, snapshot.volatilityPct * 0.65), 0.8, 2.4);

    let takeProfit1Multiple = 1.2;
    let takeProfit2Multiple = 1.9;
    let holdMinHours = 2;
    let holdMaxHours = 6;

    if (confidence >= 70) {
      takeProfit1Multiple = 1.3;
      takeProfit2Multiple = 2.2;
      holdMaxHours = 8;
    } else if (confidence < 58) {
      takeProfit1Multiple = 1.1;
      takeProfit2Multiple = 1.6;
      holdMaxHours = 4;
    }

    if (Math.abs(snapshot.move6hPct) >= 3.5) {
      holdMinHours = 1;
      holdMaxHours = Math.max(holdMinHours + 2, holdMaxHours - 1);
    }

    const takeProfit1Pct = Number((riskPct * takeProfit1Multiple).toFixed(2));
    const takeProfit2Pct = Number((riskPct * takeProfit2Multiple).toFixed(2));
    const stopLossPct = Number(riskPct.toFixed(2));

    let recommendedLeverage = "1x-3x";
    if (riskPct >= 1.7 || snapshot.volatilityPct >= 2.6) {
      recommendedLeverage = "1x-2x";
    } else if (confidence >= 72 && riskPct <= 1.1) {
      recommendedLeverage = "2x-3x";
    }

    let scaleOutGuide = localized(
      "Take 40% at TP1, 40% at TP2, and leave the last 20% open only if momentum still looks healthy.",
      "1차 목표가에서 40%, 2차 목표가에서 40%를 정리하고 마지막 20%는 추세가 살아 있을 때만 남겨두는 방식이 무난합니다."
    );
    if (confidence >= 70) {
      scaleOutGuide = localized(
        "Take 30% at TP1, 50% at TP2, and trail the last 20% only if the trend still confirms.",
        "1차 목표가에서 30%, 2차 목표가에서 50%를 정리하고 마지막 20%는 추세가 확인될 때만 따라가는 편이 낫습니다."
      );
    } else if (confidence < 58) {
      scaleOutGuide = localized(
        "Take 50% at TP1, 30% at TP2, and close the rest by the end of the hold window unless momentum expands.",
        "1차 목표가에서 50%, 2차 목표가에서 30%를 정리하고 모멘텀이 더 붙지 않으면 남은 물량도 보유 시간 안에 닫는 편이 무난합니다."
      );
    }

    const priceLogic = localized(
      `These levels use recent hourly volatility. The stop is about 1R away, TP1 is near ${takeProfit1Multiple.toFixed(1)}R, and TP2 is near ${takeProfit2Multiple.toFixed(1)}R.`,
      `이 가격대는 최근 시간봉 변동성을 기준으로 잡았습니다. 손절은 대략 1R, 1차 목표는 ${takeProfit1Multiple.toFixed(1)}R, 2차 목표는 ${takeProfit2Multiple.toFixed(1)}R 정도를 뜻합니다.`
    );
    const leverageNote = localized(
      "Conservative in-app heuristic for beginners, not exchange advice.",
      "초보자를 위한 보수적 가이드일 뿐이며 거래소의 공식 레버리지 조언은 아닙니다."
    );
    const starterNote = localized(
      "For beginners, do not add to a losing futures position.",
      "초보자라면 손실 중인 선물 포지션에 물타기를 하지 않는 편이 좋습니다."
    );

    let stopLossPrice;
    let takeProfit1Price;
    let takeProfit2Price;
    let partialExitRule;
    let timingNote;

    if (direction === "long") {
      stopLossPrice = roundTradePrice(entryPrice * (1 - (stopLossPct / 100)));
      takeProfit1Price = roundTradePrice(entryPrice * (1 + (takeProfit1Pct / 100)));
      takeProfit2Price = roundTradePrice(entryPrice * (1 + (takeProfit2Pct / 100)));
      partialExitRule = localized(
        "If price reaches TP1, consider taking 30-50% off. If it reaches TP2, consider closing most or all of the rest.",
        "가격이 1차 목표가에 닿으면 30~50% 정도를 먼저 정리하고, 2차 목표가에 닿으면 남은 물량 대부분을 정리하는 쪽이 무난합니다."
      );
      timingNote = localized(
        "This is designed for a same-day long. If price goes nowhere by the end of the hold window, reduce or close the trade.",
        "당일 롱 대응용 계획입니다. 권장 보유 시간이 끝날 때까지 가격이 거의 움직이지 않으면 줄이거나 닫는 편이 낫습니다."
      );
    } else {
      stopLossPrice = roundTradePrice(entryPrice * (1 + (stopLossPct / 100)));
      takeProfit1Price = roundTradePrice(entryPrice * (1 - (takeProfit1Pct / 100)));
      takeProfit2Price = roundTradePrice(entryPrice * (1 - (takeProfit2Pct / 100)));
      partialExitRule = localized(
        "If price reaches TP1 on the way down, consider taking 30-50% off. If it reaches TP2, consider closing most or all of the rest.",
        "가격이 1차 목표가까지 내려오면 30~50% 정도를 먼저 정리하고, 2차 목표가까지 내려오면 남은 물량 대부분을 정리하는 쪽이 무난합니다."
      );
      timingNote = localized(
        "This is designed for a same-day short. If price stops trending lower after the hold window, reduce or close the trade.",
        "당일 숏 대응용 계획입니다. 권장 보유 시간이 지난 뒤에도 추가 하락이 멈추면 줄이거나 닫는 편이 낫습니다."
      );
    }

    return {
      style: localized("same-day intraday", "당일 장중 대응"),
      entryPrice: roundTradePrice(entryPrice),
      stopLossPrice,
      stopLossPct,
      takeProfit1Price,
      takeProfit1Pct,
      takeProfit2Price,
      takeProfit2Pct,
      holdMinHours,
      holdMaxHours,
      holdWindowLabel: `${holdMinHours}-${holdMaxHours}h`,
      partialExitRule,
      timingNote,
      recommendedLeverage,
      scaleOutGuide,
      priceLogic,
      leverageNote,
      starterNote
    };
  };

  const newPerspective = (key, verdict, note) => ({ key, verdict, note });

  const getCandidatePerspectives = (snapshot, direction) => {
    const isLong = direction === "long";
    const perspectives = [];
    const trendAligned = isLong
      ? snapshot.move6hPct > 0 && snapshot.move24hPct > 0
      : snapshot.move6hPct < 0 && snapshot.move24hPct < 0;
    const trendOpposed = isLong
      ? snapshot.move24hPct < 0
      : snapshot.move24hPct > 0;
    perspectives.push(newPerspective(
      "momentum",
      trendAligned ? (isLong ? "long" : "short") : (trendOpposed ? "caution" : "neutral"),
      trendAligned
        ? localized("Trend-followers see aligned 6h and 24h pressure.", "추세 추종 관점에서는 6시간과 24시간 압력이 같은 방향입니다.")
        : localized("Momentum is mixed, so chasing needs confirmation.", "모멘텀이 섞여 있어서 추격 진입은 확인이 더 필요합니다.")
    ));

    const bandPosition = Number(snapshot.bollingerPosition || 0);
    const bandExtended = Math.abs(bandPosition) >= RISK_FILTER.extendedBandPosition;
    perspectives.push(newPerspective(
      "bollinger",
      bandExtended ? "caution" : (bandPosition > 0 ? "long" : (bandPosition < 0 ? "short" : "neutral")),
      bandExtended
        ? localized("Bollinger traders would treat this as stretched rather than clean continuation.", "볼린저 관점에서는 깔끔한 지속보다 과확장 구간으로 봅니다.")
        : localized("Price is inside a usable Bollinger zone, not at an extreme band stretch.", "가격이 극단 밴드 확장보다는 활용 가능한 볼린저 구간 안에 있습니다.")
    ));

    const funding = Number(snapshot.fundingRatePct || 0);
    const fundingVerdict = funding < -0.03 ? "long" : (funding > 0.03 ? "short" : "neutral");
    perspectives.push(newPerspective(
      "funding",
      fundingVerdict,
      funding < -0.03
        ? localized("Negative funding suggests shorts are paying, which can help long squeezes.", "음수 펀딩은 숏 쪽이 비용을 내는 구조라 롱 스퀴즈에 우호적일 수 있습니다.")
        : funding > 0.03
          ? localized("Positive funding suggests long crowding, so longs need more caution.", "양수 펀딩은 롱 쏠림을 뜻할 수 있어 롱은 더 조심해야 합니다.")
          : localized("Funding is not crowded enough to give a strong contrarian signal.", "펀딩은 강한 역발상 신호를 줄 만큼 쏠려 있지 않습니다.")
    ));

    const sweep = snapshot.liquiditySignal || {};
    perspectives.push(newPerspective(
      "liquidity",
      sweep.direction === direction ? (isLong ? "long" : "short") : (sweep.direction === "neutral" || !sweep.direction ? "neutral" : "caution"),
      sweep.direction === direction
        ? localized("A recent liquidity sweep supports this direction.", "최근 유동성 sweep 이 이 방향을 보조합니다.")
        : sweep.direction && sweep.direction !== "neutral"
          ? localized("Liquidity evidence points against this direction.", "유동성 관점은 이 방향과 충돌합니다.")
          : localized("No clear stop-run or sweep signal is visible yet.", "아직 뚜렷한 스탑런이나 sweep 신호는 보이지 않습니다.")
    ));

    const lookbackMove = Number(snapshot.lookbackMovePct || 0);
    const reversionCaution = isLong ? lookbackMove > RISK_FILTER.maxLookbackMovePct : lookbackMove < -RISK_FILTER.maxLookbackMovePct;
    perspectives.push(newPerspective(
      "meanReversion",
      reversionCaution ? "caution" : "neutral",
      reversionCaution
        ? localized("Mean-reversion traders would be wary because the multi-day move is already extended.", "평균회귀 관점에서는 며칠간 움직임이 이미 커서 조심할 구간입니다.")
        : localized("The multi-day move is not extreme enough to force a reversion-first read.", "며칠간 움직임이 극단적이지 않아 평균회귀를 우선할 상황은 아닙니다.")
    ));

    const slope = Number(snapshot.chart?.basisSlopePct || 0);
    const structureAligned = isLong ? slope > 0 : slope < 0;
    perspectives.push(newPerspective(
      "structure",
      structureAligned ? (isLong ? "long" : "short") : "caution",
      structureAligned
        ? localized("Simple swing structure and Bollinger basis slope agree with this side.", "단순 스윙 구조와 볼린저 기준선 기울기가 이 방향과 맞습니다.")
        : localized("Structure is not aligned; this is not a clean wave/structure setup.", "구조가 맞지 않아 깔끔한 파동/구조 세팅은 아닙니다.")
    ));

    return perspectives;
  };

  const convertToCandidate = (snapshot, direction, signalStatus = "actionable") => {
    const score = direction === "long" ? snapshot.longScore : snapshot.shortScore;
    const edge = direction === "long" ? snapshot.longEdge : snapshot.shortEdge;
    const reasons = direction === "long" ? snapshot.longReasons : snapshot.shortReasons;
    const thesis = direction === "long" ? snapshot.longThesis : snapshot.shortThesis;
    const confidence = clampNumber(50 + (Math.abs(edge) * 0.7), 50, 95);
    const beginnerPlan = newBeginnerTradePlan({ snapshot, direction, confidence });
    let momentumTrendPoints = snapshot.scoreComponents.momentumTrend;
    let marketRegimePoints = snapshot.scoreComponents.marketRegime;
    let bollingerPoints = snapshot.scoreComponents.bollinger;
    let fundingPoints = snapshot.scoreComponents.longFunding;

    if (direction === "short") {
      momentumTrendPoints *= -1;
      marketRegimePoints *= -1;
      bollingerPoints *= -1;
      fundingPoints = snapshot.scoreComponents.shortFunding;
    }

    const riskBlockCount = direction === "long"
      ? (snapshot.riskBlocks?.long?.length || 0)
      : (snapshot.riskBlocks?.short?.length || 0);
    const resolvedSignalStatus = signalStatus === "actionable" ? "actionable" : (riskBlockCount ? "blocked" : "watch");

    return {
      symbol: snapshot.symbol,
      direction,
      signalStatus: resolvedSignalStatus,
      biasScore: Number(score.toFixed(1)),
      edge: Number(Math.abs(edge).toFixed(1)),
      confidence: Math.round(confidence),
      lastPrice: snapshot.lastPrice,
      move6hPct: snapshot.move6hPct,
      move24hPct: snapshot.move24hPct,
      lookbackMovePct: snapshot.lookbackMovePct,
      fundingRatePct: snapshot.fundingRatePct,
      volumeRatio: snapshot.volumeRatio,
      volatilityPct: snapshot.volatilityPct,
      bollingerPosition: snapshot.bollingerPosition,
      riskFlags: Array.isArray(snapshot.riskFlags) ? snapshot.riskFlags.slice(0, 3) : [],
      liquiditySignal: snapshot.liquiditySignal,
      perspectives: getCandidatePerspectives(snapshot, direction),
      reasons: reasons.slice(0, 3),
      technicalNotes: snapshot.technicalNotes.slice(0, 4),
      scoreBreakdown: [
        { key: "momentumTrend", points: Number(momentumTrendPoints.toFixed(1)) },
        { key: "bollinger", points: Number(bollingerPoints.toFixed(1)) },
        { key: "marketRegime", points: Number(marketRegimePoints.toFixed(1)) },
        { key: "opportunity", points: Number(snapshot.scoreComponents.opportunity.toFixed(1)) },
        { key: "funding", points: Number(fundingPoints.toFixed(1)) }
      ],
      thesis,
      invalidation: direction === "long"
        ? localized(
          `Reassess if price falls below ${formatPrice(beginnerPlan.stopLossPrice)} or the 6h trend flips negative.`,
          `가격이 ${formatPrice(beginnerPlan.stopLossPrice)} 아래로 밀리거나 6시간 추세가 음전하면 다시 봐야 합니다.`
        )
        : localized(
          `Reassess if price rises above ${formatPrice(beginnerPlan.stopLossPrice)} or the 6h trend turns back up.`,
          `가격이 ${formatPrice(beginnerPlan.stopLossPrice)} 위로 올라가거나 6시간 추세가 다시 위로 꺾이면 다시 봐야 합니다.`
        ),
      chart: snapshot.chart,
      beginnerPlan
    };
  };

  const buildLiveSources = (marketContext) => {
    const generated = new Date().toISOString();
    const sources = [
      {
        source: "OKX",
        title: localized(
          "Public swap tickers, funding snapshots, and 1H candles.",
          "공개 스왑 티커, 펀딩 스냅샷, 1시간 캔들을 사용합니다."
        ),
        link: "https://www.okx.com/en-us/okx-api",
        published: generated,
        publishedLocal: generated,
        sentimentLabel: localized("Live public data", "실시간 공개 데이터")
      }
    ];

    sources.push({
      source: "Client-side scoring",
      title: localized(
        "Momentum, Bollinger position, funding crowding, breadth, and volatility are scored directly in the browser.",
        "모멘텀, 볼린저 위치, 펀딩 혼잡도, 시장 폭, 변동성을 브라우저에서 직접 점수화합니다."
      ),
      link: "",
      published: generated,
      publishedLocal: generated,
      sentimentLabel: localized("Live public data", "실시간 공개 데이터")
    });

    if (marketContext.fearGreed) {
      sources.push({
        source: "Alternative.me",
        title: localized(
          "Fear & Greed is used as optional market context when the public feed is reachable.",
          "공개 피드에 접근 가능할 때 공포/탐욕 지수를 보조 시장 맥락으로 사용합니다."
        ),
        link: "https://api.alternative.me/fng/",
        published: generated,
        publishedLocal: generated,
        sentimentLabel: localized("Optional context", "보조 지표")
      });
    }

    return sources;
  };

  const buildReport = async () => {
    const warnings = [];
    const tickersResponse = await fetchOkxJson("/api/v5/market/tickers?instType=SWAP");
    const tickers = Array.isArray(tickersResponse.data) ? tickersResponse.data : [];
    const universe = getSymbolUniverse(tickers);

    if (!universe.length) {
      throw new Error("No eligible swaps were returned by the OKX public API.");
    }

    const fundingMap = await getFundingMap(universe.map((ticker) => ticker.instId));
    const marketContext = await getMarketContext(universe);

    const snapshotResults = await mapWithConcurrency(universe, 3, async (ticker) => {
      try {
        return await getSymbolSnapshot(ticker, fundingMap, marketContext.regimeScore);
      } catch (error) {
        warnings.push(localized(
          `Skipped ${ticker.instId}: ${error.message}`,
          `${ticker.instId} 건너뜀: ${error.message}`
        ));
        return null;
      }
    });

    const snapshots = snapshotResults.filter(Boolean);

    if (snapshots.length < 4) {
      throw new Error("Not enough liquid pair snapshots were built to form a live report.");
    }

    const minimumLongBiasScore = 75;
    const minimumLongDirectionalEdge = 12;
    const minimumShortBiasScore = 78;
    const minimumShortDirectionalEdge = 14;
    const maximumShortMarketRegimeScore = 0.1;
    const minimumLongWatchScore = 55;
    const minimumLongWatchEdge = 3;
    const minimumShortWatchScore = 55;
    const minimumShortWatchEdge = 3;
    const maximumShortWatchMarketRegimeScore = 1;
    const fillWatchSnapshots = (primarySnapshots, fallbackSnapshots, limit) => {
      const selected = [];
      const seen = new Set();
      [...primarySnapshots, ...fallbackSnapshots].forEach((snapshot) => {
        if (selected.length >= limit || seen.has(snapshot.symbol)) {
          return;
        }
        selected.push(snapshot);
        seen.add(snapshot.symbol);
      });
      return selected;
    };
    const rawLongWatchSnapshots = [...snapshots]
      .sort((left, right) => (right.longEdge - left.longEdge) || (right.longScore - left.longScore))
      .filter((snapshot) => snapshot.longEdge >= minimumLongWatchEdge && snapshot.longScore >= minimumLongWatchScore);
    const rawShortWatchSnapshots = [...snapshots]
      .sort((left, right) => (right.shortEdge - left.shortEdge) || (right.shortScore - left.shortScore))
      .filter((snapshot) => (
        snapshot.shortEdge >= minimumShortWatchEdge
        && snapshot.shortScore >= minimumShortWatchScore
        && marketContext.regimeScore <= maximumShortWatchMarketRegimeScore
      ));
    const longFallbackSnapshots = [...snapshots]
      .sort((left, right) => (right.longScore - left.longScore) || (right.longEdge - left.longEdge));
    const shortFallbackSnapshots = [...snapshots]
      .sort((left, right) => (right.shortScore - left.shortScore) || (right.shortEdge - left.shortEdge));
    const longWatchSnapshots = fillWatchSnapshots(rawLongWatchSnapshots, longFallbackSnapshots, APP_CONFIG.topPicks);
    const shortWatchSnapshots = fillWatchSnapshots(rawShortWatchSnapshots, shortFallbackSnapshots, APP_CONFIG.topPicks);
    const longActionableSnapshots = longWatchSnapshots
      .filter((snapshot) => (
        snapshot.longEdge >= minimumLongDirectionalEdge
        && snapshot.longScore >= minimumLongBiasScore
        && !snapshot.riskBlocks?.long?.length
      ));
    const shortActionableSnapshots = shortWatchSnapshots
      .filter((snapshot) => (
        snapshot.shortEdge >= minimumShortDirectionalEdge
        && snapshot.shortScore >= minimumShortBiasScore
        && marketContext.regimeScore <= maximumShortMarketRegimeScore
        && !snapshot.riskBlocks?.short?.length
      ));
    const longSnapshots = longActionableSnapshots
      .slice(0, APP_CONFIG.topPicks);
    const shortSnapshots = shortActionableSnapshots
      .slice(0, APP_CONFIG.topPicks);
    const longWatchOnlySnapshots = longWatchSnapshots
      .filter((snapshot) => !longSnapshots.includes(snapshot))
        .slice(0, Math.max(0, APP_CONFIG.topPicks - longSnapshots.length));
    const shortWatchOnlySnapshots = shortWatchSnapshots
      .filter((snapshot) => !shortSnapshots.includes(snapshot))
      .slice(0, Math.max(0, APP_CONFIG.topPicks - shortSnapshots.length));
    const blockedLongCount = rawLongWatchSnapshots.filter((snapshot) => snapshot.riskBlocks?.long?.length).length;
    const blockedShortCount = rawShortWatchSnapshots.filter((snapshot) => snapshot.riskBlocks?.short?.length).length;

    if (blockedLongCount || blockedShortCount) {
      warnings.push(localized(
        `Risk filters removed ${blockedLongCount} long and ${blockedShortCount} short extended setups.`,
        `리스크 필터가 과확장된 롱 ${blockedLongCount}개, 숏 ${blockedShortCount}개를 제외했습니다.`
      ));
    }

    if (!longSnapshots.length) {
      warnings.push(localized(
        "No long setups cleared the minimum quality filter in this refresh.",
        "이번 계산에서는 기준을 통과한 롱 후보가 없었습니다."
      ));
    }

    if (!shortSnapshots.length) {
      warnings.push(localized(
        "No short setups cleared the minimum quality filter in this refresh.",
        "이번 계산에서는 기준을 통과한 숏 후보가 없었습니다."
      ));
    }

    const generatedAt = new Date().toISOString();

    return {
      generatedAt,
      generatedAtLocal: generatedAt,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC",
      isSample: false,
      marketContext,
      longCandidates: [
        ...longSnapshots.map((snapshot) => convertToCandidate(snapshot, "long", "actionable")),
        ...longWatchOnlySnapshots.map((snapshot) => convertToCandidate(snapshot, "long", "watch"))
      ],
      shortCandidates: [
        ...shortSnapshots.map((snapshot) => convertToCandidate(snapshot, "short", "actionable")),
        ...shortWatchOnlySnapshots.map((snapshot) => convertToCandidate(snapshot, "short", "watch"))
      ],
      headlines: buildLiveSources(marketContext),
      warnings,
      disclaimer: localized(
        "This watchlist is rebuilt from public market data in your browser. It is not financial advice and should not be used as automatic execution logic.",
        "이 감시 리스트는 브라우저에서 공개 시장 데이터를 직접 계산해 만든 것으로 투자 조언이 아니며 자동 매매 로직으로 사용하면 안 됩니다."
      )
    };
  };

  const renderEmpty = (target, text) => {
    target.innerHTML = `<div class="empty">${text}</div>`;
  };

  const getDriverLabel = (driver) => {
    const key = driver?.key || "";
    switch (key) {
      case "momentumTrend":
        return t("driverMomentumTrend");
      case "bollinger":
        return t("driverBollinger");
      case "marketRegime":
        return t("driverMarketRegime");
      case "opportunity":
        return t("driverOpportunity");
      case "funding":
        return t("driverFunding");
      default:
        return key;
    }
  };

  const setStatusModel = (type, extra = {}) => {
    statusModel = { type, ...extra };
    renderStatus();
  };

  const renderStatus = () => {
    refreshStatus.className = "refresh-status";
    let text = t("statusReady");

    switch (statusModel.type) {
      case "busy":
        text = t("statusBusy");
        refreshStatus.classList.add("is-busy");
        break;
      case "success":
        text = t("statusUpdated");
        refreshStatus.classList.add("is-success");
        break;
      case "success-warning":
        if (statusModel.count === 1) {
          text = t("statusUpdatedWarnings_one");
        } else {
          text = t("statusUpdatedWarnings_many", { count: statusModel.count || 0 });
        }
        refreshStatus.classList.add("is-success");
        break;
      case "error":
        text = `${t("statusErrorPrefix")}: ${statusModel.detail || "Unknown error."}`;
        refreshStatus.classList.add("is-error");
        break;
      case "no-report":
        text = t("statusNoReport");
        break;
      default:
        text = currentReport ? t("statusUpdated") : t("statusReady");
        break;
    }

    refreshStatus.textContent = text;
  };

  const setRefreshBusy = (busy) => {
    isRefreshing = busy;
    refreshButton.disabled = busy;
    refreshButton.textContent = busy ? t("refreshingButton") : t("refreshButton");
  };

  const applyLocaleToStatic = () => {
    document.getElementById("hero-title").textContent = t("heroTitle");
    warningTitle.textContent = t("warningTitle");
    document.getElementById("regime-label").textContent = t("marketRegime");
    document.getElementById("fear-label").textContent = t("coverageLabel");
    document.getElementById("generated-label").textContent = t("generated");
    document.getElementById("long-title").textContent = t("longTitle");
    document.getElementById("short-title").textContent = t("shortTitle");
    document.getElementById("long-pill").textContent = t("longPill");
    document.getElementById("short-pill").textContent = t("shortPill");
    document.getElementById("summary-title-head").textContent = t("summaryTitle");
    document.getElementById("summary-pill").textContent = t("summaryPill");
    document.getElementById("views-title-head").textContent = t("viewsTitle");
    document.getElementById("views-pill").textContent = t("viewsPill");
    document.getElementById("headline-title-head").textContent = t("sourceTitle");
    document.getElementById("headline-pill").textContent = t("sourcePill");

    languageButtons.forEach((button) => {
      button.classList.toggle("is-active", button.dataset.lang === currentLang);
    });

    setRefreshBusy(isRefreshing);

    if (currentReport) {
      applyReport(currentReport);
    } else {
      sampleBadge.textContent = t("badgeIdle");
      document.getElementById("hero-copy").textContent = t("heroCopyIdle");
      renderNoReport();
    }

    renderStatus();
  };

  const renderBeginnerPlan = (plan, direction) => {
    if (!plan) {
      return "";
    }

    const exitRule = pickText(plan.partialExitRule);
    const scaleOutGuide = pickText(plan.scaleOutGuide);
    const priceLogic = pickText(plan.priceLogic);
    const leverageNote = pickText(plan.leverageNote);
    const starterNote = pickText(plan.starterNote);

    return `
      <section class="plan-block">
        <div class="plan-head">
          <div class="plan-title">${t("planTitle")}</div>
          <div class="plan-style">${pickText(plan.style)}</div>
        </div>
        <div class="plan-grid">
          <div class="plan-item">
            <span class="plan-label">${t("planCurrentPrice")}</span>
            <strong class="plan-value">${formatPrice(plan.entryPrice)}</strong>
            <div class="muted">${t("planHoldWindow")}: ${plan.holdWindowLabel}</div>
          </div>
          <div class="plan-item">
            <span class="plan-label">${t("planTp1")}</span>
            <strong class="plan-value">${formatPrice(plan.takeProfit1Price)}</strong>
            <div class="muted">${t("planMoveFromHere", { value: formatSignedPct(plan.takeProfit1Pct) })}</div>
          </div>
          <div class="plan-item">
            <span class="plan-label">${t("planTp2")}</span>
            <strong class="plan-value">${formatPrice(plan.takeProfit2Price)}</strong>
            <div class="muted">${t("planMoveFromHere", { value: formatSignedPct(plan.takeProfit2Pct) })}</div>
          </div>
          <div class="plan-item">
            <span class="plan-label">${t("planStopLoss")}</span>
            <strong class="plan-value">${formatPrice(plan.stopLossPrice)}</strong>
            <div class="muted">${t("planRiskBudget", { value: formatSignedPct(-Math.abs(plan.stopLossPct)) })}</div>
          </div>
          <div class="plan-item">
            <span class="plan-label">${t("planLeverage")}</span>
            <strong class="plan-value">${plan.recommendedLeverage}</strong>
            <div class="muted">${t("planExitStyle")}: ${direction === "long" ? t("planExitStyleLong") : t("planExitStyleShort")}</div>
          </div>
        </div>
        ${exitRule ? `<div class="plan-note"><strong>${t("planExitStyle")}:</strong> ${exitRule}</div>` : ""}
        ${scaleOutGuide ? `<div class="plan-note"><strong>${t("planScaleOut")}:</strong> ${scaleOutGuide}</div>` : ""}
        ${priceLogic ? `<div class="plan-note"><strong>${t("planLogic")}:</strong> ${priceLogic}</div>` : ""}
        ${leverageNote ? `<div class="plan-note">${leverageNote}</div>` : ""}
        ${starterNote ? `<div class="plan-note"><strong>${t("planStarter")}:</strong> ${starterNote}</div>` : ""}
      </section>
    `;
  };

  const renderMiniChart = (candidate) => {
    const chart = candidate.chart || {};
    const points = Array.isArray(chart.points) ? chart.points : [];

    if (points.length < 2) {
      return "";
    }

    const width = 360;
    const height = 190;
    const padding = { top: 12, right: 54, bottom: 18, left: 10 };
    const plotWidth = width - padding.left - padding.right;
    const plotHeight = height - padding.top - padding.bottom;
    const levelValues = [
      chart.support,
      chart.resistance,
      candidate.beginnerPlan?.entryPrice,
      candidate.beginnerPlan?.stopLossPrice,
      candidate.beginnerPlan?.takeProfit1Price,
      candidate.beginnerPlan?.takeProfit2Price
    ].map(Number).filter(Number.isFinite);

    const highValues = points.flatMap((point) => [
      Number(point.high),
      Number(point.upper),
      Number(point.basis),
      Number(point.lower)
    ]).filter(Number.isFinite);
    const lowValues = points.flatMap((point) => [
      Number(point.low),
      Number(point.upper),
      Number(point.basis),
      Number(point.lower)
    ]).filter(Number.isFinite);

    const rawMin = Math.min(...lowValues, ...levelValues);
    const rawMax = Math.max(...highValues, ...levelValues);
    const baseRange = rawMax - rawMin || Math.max(Math.abs(rawMax) * 0.04, 1);
    const yPadding = baseRange * 0.1;
    const minPrice = rawMin - yPadding;
    const maxPrice = rawMax + yPadding;
    const priceRange = maxPrice - minPrice || 1;
    const slot = plotWidth / points.length;
    const bodyWidth = Math.max(4, Math.min(12, slot * 0.56));
    const xFor = (index) => padding.left + (slot * index) + (slot / 2);
    const yFor = (value) => padding.top + (((maxPrice - Number(value)) / priceRange) * plotHeight);
    const pathFor = (key) => points
      .map((point, index) => `${index === 0 ? "M" : "L"} ${xFor(index).toFixed(2)} ${yFor(point[key]).toFixed(2)}`)
      .join(" ");

    const grids = [0.15, 0.4, 0.65, 0.9].map((ratio) => {
      const y = padding.top + (plotHeight * ratio);
      return `<line class="chart-grid" x1="${padding.left}" y1="${y.toFixed(2)}" x2="${(width - padding.right).toFixed(2)}" y2="${y.toFixed(2)}"></line>`;
    }).join("");

    const candles = points.map((point, index) => {
      const open = Number(point.open);
      const close = Number(point.close);
      const high = Number(point.high);
      const low = Number(point.low);
      const x = xFor(index);
      const bodyTop = Math.min(yFor(open), yFor(close));
      const bodyBottom = Math.max(yFor(open), yFor(close));
      const bodyHeight = Math.max(2, bodyBottom - bodyTop);
      const bodyX = x - (bodyWidth / 2);
      const candleClass = close >= open ? "chart-candle-up" : "chart-candle-down";

      return `
        <line class="chart-wick" x1="${x.toFixed(2)}" y1="${yFor(high).toFixed(2)}" x2="${x.toFixed(2)}" y2="${yFor(low).toFixed(2)}"></line>
        <rect class="${candleClass}" x="${bodyX.toFixed(2)}" y="${bodyTop.toFixed(2)}" width="${bodyWidth.toFixed(2)}" height="${bodyHeight.toFixed(2)}" rx="2"></rect>
      `;
    }).join("");

    const levelDescriptors = [
      { label: t("levelSupport"), value: chart.support, className: "support" },
      { label: t("levelResistance"), value: chart.resistance, className: "resistance" },
      { label: t("levelEntry"), value: candidate.beginnerPlan?.entryPrice, className: "entry" },
      { label: t("levelStop"), value: candidate.beginnerPlan?.stopLossPrice, className: "stop" },
      { label: t("levelTp1"), value: candidate.beginnerPlan?.takeProfit1Price, className: "tp" },
      { label: t("levelTp2"), value: candidate.beginnerPlan?.takeProfit2Price, className: "tp" }
    ].filter((item) => Number.isFinite(Number(item.value)));

    const levels = levelDescriptors.map((item) => {
      const y = yFor(item.value);
      return `<line class="chart-level ${item.className}" x1="${padding.left}" y1="${y.toFixed(2)}" x2="${(width - padding.right).toFixed(2)}" y2="${y.toFixed(2)}"></line>`;
    }).join("");

    const legend = levelDescriptors.map((item) => `<span class="chip">${item.label} ${formatPrice(item.value)}</span>`).join("");

    return `
      <section class="analysis-block">
        <div class="analysis-head">
          <div class="analysis-title">${t("chartTitle")}</div>
          <div class="analysis-meta">${t("chartMeta", {
            period: chart.bollingerPeriod || 20,
            deviation: chart.bollingerDeviation || 2
          })}</div>
        </div>
        <div class="chart-frame">
          <svg class="mini-chart" viewBox="0 0 ${width} ${height}" role="img" aria-label="${candidate.symbol} chart">
            ${grids}
            ${levels}
            <path class="chart-band-upper" d="${pathFor("upper")}"></path>
            <path class="chart-band-basis" d="${pathFor("basis")}"></path>
            <path class="chart-band-lower" d="${pathFor("lower")}"></path>
            ${candles}
          </svg>
        </div>
        <div class="chips">
          <span class="chip">${t("bandUpper")}</span>
          <span class="chip">${t("bandBasis")}</span>
          <span class="chip">${t("bandLower")}</span>
          ${legend}
        </div>
      </section>
    `;
  };

  const renderScoreBreakdown = (candidate) => {
    const breakdown = Array.isArray(candidate.scoreBreakdown) ? candidate.scoreBreakdown : [];
    if (!breakdown.length) {
      return "";
    }

    return `
      <section class="analysis-block">
        <div class="analysis-head">
          <div class="analysis-title">${t("scoreDriversTitle")}</div>
        </div>
        <div class="driver-list">
          ${breakdown.map((driver) => {
            const value = Number(driver.points || 0);
            const valueClass = value >= 0 ? "is-positive" : "is-negative";
            return `
              <div class="driver-row">
                <span class="driver-label">${getDriverLabel(driver)}</span>
                <span class="driver-value ${valueClass}">${formatContribution(value)}</span>
              </div>
            `;
          }).join("")}
        </div>
      </section>
    `;
  };

  const renderTechnicalNotes = (candidate) => {
    const notes = pickArray(candidate.technicalNotes);
    if (!notes.length) {
      return "";
    }

    return `
      <section class="analysis-block">
        <div class="analysis-head">
          <div class="analysis-title">${t("technicalReadTitle")}</div>
        </div>
        <ul class="note-list">
          ${notes.map((note) => `<li>${note}</li>`).join("")}
        </ul>
      </section>
    `;
  };

  const getPerspectiveLabel = (key) => {
    switch (key) {
      case "momentum":
        return t("perspectiveMomentum");
      case "bollinger":
        return t("perspectiveBollinger");
      case "funding":
        return t("perspectiveFunding");
      case "liquidity":
        return t("perspectiveLiquidity");
      case "meanReversion":
        return t("perspectiveMeanReversion");
      case "structure":
        return t("perspectiveStructure");
      default:
        return key;
    }
  };

  const getVerdictLabel = (verdict) => {
    switch (verdict) {
      case "long":
        return t("verdictLong");
      case "short":
        return t("verdictShort");
      case "caution":
        return t("verdictCaution");
      default:
        return t("verdictNeutral");
    }
  };

  const renderPerspectives = (candidate) => {
    const perspectives = Array.isArray(candidate.perspectives)
      ? candidate.perspectives
      : getCandidatePerspectives(candidate, candidate.direction || "long");
    if (!perspectives.length) {
      return "";
    }

    return `
      <section class="analysis-block">
        <div class="analysis-head">
          <div class="analysis-title">${t("perspectiveTitle")}</div>
        </div>
        <div class="perspective-list">
          ${perspectives.map((item) => `
            <div class="perspective-item">
              <div class="perspective-name">${getPerspectiveLabel(item.key)}</div>
              <div class="perspective-body">
                <div class="perspective-verdict">${getVerdictLabel(item.verdict)}</div>
                <div>${pickText(item.note)}</div>
              </div>
            </div>
          `).join("")}
        </div>
      </section>
    `;
  };

  const renderCandidate = (candidate, direction) => {
    const reasons = pickArray(candidate.reasons);
    const riskFlags = pickArray(candidate.riskFlags);
    const thesis = pickText(candidate.thesis);
    const invalidation = pickText(candidate.invalidation, t("reasonsFallback"));
    const bandWidthRatio = Number(candidate.chart?.widthRatio || 0);
    const isActionable = candidate.signalStatus === "actionable";
    const isBlocked = candidate.signalStatus === "blocked";
    const liquiditySignal = candidate.liquiditySignal || {};
    const hasLiquiditySignal = liquiditySignal.type && liquiditySignal.type !== "none";

    return `
      <article class="candidate">
        <div class="candidate-top">
          <div>
            <div class="symbol">${candidate.symbol}</div>
            <p class="thesis">${thesis || ""}</p>
          </div>
          <div class="score-stack">
            <div class="score-value">${Math.round(Number(candidate.biasScore || 0))}</div>
            <div class="score-note">${direction === "long" ? t("scoreSuffixLong") : t("scoreSuffixShort")}</div>
          </div>
        </div>
        <div class="chips">
          <span class="chip ${isActionable ? "action-chip" : (isBlocked ? "blocked-chip" : "watch-chip")}">${isActionable ? t("chipActionable") : (isBlocked ? t("chipBlocked") : t("chipWatchOnly"))}</span>
          <span class="chip">${t("chipPrice")} ${formatPrice(candidate.lastPrice)}</span>
          <span class="chip">${t("chipMove6h")} ${formatSignedPct(candidate.move6hPct)}</span>
          <span class="chip">${t("chipMove24h")} ${formatSignedPct(candidate.move24hPct)}</span>
          <span class="chip">${t("chipFunding")} ${formatSignedPct(candidate.fundingRatePct)}</span>
          <span class="chip">${t("chipVolume")} ${Number(candidate.volumeRatio || 0).toFixed(2)}x</span>
          ${bandWidthRatio ? `<span class="chip">${t("chipBandWidth")} ${bandWidthRatio.toFixed(2)}x</span>` : ""}
          ${hasLiquiditySignal ? `<span class="chip liquidity-chip">${pickText(liquiditySignal.label)}</span>` : ""}
          <span class="chip">${t("chipConfidence")} ${Math.round(Number(candidate.confidence || 0))}</span>
          ${riskFlags.map((flag) => `<span class="chip risk-chip">${flag}</span>`).join("")}
        </div>
        ${renderMiniChart(candidate)}
        ${isBlocked ? `<section class="analysis-block"><div class="muted">${t("noTradePlan")}</div></section>` : renderBeginnerPlan(candidate.beginnerPlan, direction)}
        ${renderPerspectives(candidate)}
        ${renderScoreBreakdown(candidate)}
        ${renderTechnicalNotes(candidate)}
        ${reasons.length
          ? `<ul class="reason-list">${reasons.map((reason) => `<li>${reason}</li>`).join("")}</ul>`
          : `<div class="muted">${t("reasonsFallback")}</div>`}
        <div class="muted"><strong>${t("invalidationLabel")}</strong> ${invalidation}</div>
      </article>
    `;
  };

  const renderSummary = (report) => {
    const target = document.getElementById("summary-list");
    const context = report.marketContext || {};
    const leaders = Array.isArray(context.leaders) ? context.leaders : [];
    const laggards = Array.isArray(context.laggards) ? context.laggards : [];
    const regimeLabelText = pickText(context.regimeLabel, "Mixed");
    const summaryText = pickText(context.summary, t("reportFallback"));
    const fearGreedCopy = context.fearGreed
      ? `<div class="muted">${t("summaryFearBody", {
        value: context.fearGreed.value,
        label: pickText(context.fearGreed.label)
      })}</div>`
      : "";

    target.innerHTML = `
      <article class="summary-item">
        <div class="summary-top">
          <div class="summary-title">${t("summaryBreadthTitle")}</div>
          <span class="pill market">${regimeLabelText}</span>
        </div>
        <div class="muted">${summaryText}</div>
        ${fearGreedCopy}
      </article>
      <article class="summary-item">
        <div class="summary-top">
          <div class="summary-title">${t("summaryBroadTitle")}</div>
          <div class="muted">${t("summaryBroadBody", {
            breadth: Number(context.breadthPositivePct || 0).toFixed(1)
          })}</div>
        </div>
        <div class="chips">
          ${leaders.map((item) => `<span class="chip">${item.symbol} ${formatSignedPct(item.change24hPct)}</span>`).join("")}
        </div>
      </article>
      <article class="summary-item">
        <div class="summary-top">
          <div class="summary-title">${t("summaryWeakTitle")}</div>
          <div class="muted">${laggards.length ? t("summaryWeakBody") : t("summaryWeakFallback")}</div>
        </div>
        <div class="chips">
          ${laggards.map((item) => `<span class="chip">${item.symbol} ${formatSignedPct(item.change24hPct)}</span>`).join("")}
        </div>
      </article>
    `;
  };

  const getMarketViews = () => [
    {
      title: t("viewRiskTitle"),
      common: t("viewRiskCommon"),
      read: t("viewRiskRead")
    },
    {
      title: t("viewMomentumTitle"),
      common: t("viewMomentumCommon"),
      read: t("viewMomentumRead")
    },
    {
      title: t("viewFundingTitle"),
      common: t("viewFundingCommon"),
      read: t("viewFundingRead")
    },
    {
      title: t("viewLiquidityTitle"),
      common: t("viewLiquidityCommon"),
      read: t("viewLiquidityRead")
    },
    {
      title: t("viewMeanTitle"),
      common: t("viewMeanCommon"),
      read: t("viewMeanRead")
    }
  ];

  const renderMarketViews = () => {
    const target = document.getElementById("views-list");
    const views = getMarketViews();

    target.innerHTML = views.map((view) => `
      <article class="summary-item">
        <div class="summary-top">
          <div class="summary-title">${view.title}</div>
        </div>
        <div class="muted"><strong>${t("viewCommon")}:</strong> ${view.common}</div>
        <div class="muted"><strong>${t("viewMyRead")}:</strong> ${view.read}</div>
      </article>
    `).join("");
  };

  const renderSources = (items) => {
    const target = document.getElementById("headline-list");
    if (!Array.isArray(items) || !items.length) {
      renderEmpty(target, t("noSources"));
      return;
    }

    target.innerHTML = items.map((item) => `
      <article class="headline">
        <div class="headline-top">
          <div class="summary-title">${item.source || "Source"}</div>
          <div class="muted">${pickText(item.sentimentLabel, t("sourceStatusLive"))}</div>
        </div>
        <div class="headline-title">
          ${item.link
            ? `<a href="${item.link}" target="_blank" rel="noreferrer">${pickText(item.title)}</a>`
            : pickText(item.title)}
        </div>
        <div class="muted">${item.publishedLocal ? new Date(item.publishedLocal).toLocaleString(localeTag()) : ""}</div>
      </article>
    `).join("");
  };

  const renderWarnings = (warnings) => {
    const localizedWarnings = pickArray(warnings);

    if (!localizedWarnings.length) {
      warningPanel.hidden = true;
      warningList.innerHTML = "";
      warningPill.textContent = t("warningPill_one");
      warningCopy.textContent = t("warningCopy_one");
      return;
    }

    warningPanel.hidden = false;
    warningPill.textContent = localizedWarnings.length === 1
      ? t("warningPill_one")
      : t("warningPill_many", { count: localizedWarnings.length });
    warningCopy.textContent = localizedWarnings.length === 1
      ? t("warningCopy_one")
      : t("warningCopy_many", { count: localizedWarnings.length });
    warningList.innerHTML = localizedWarnings.map((warning) => `<li>${warning}</li>`).join("");
  };

  const applyReport = (report) => {
    currentReport = report;
    sampleBadge.textContent = t("badgeLive");

    const context = report.marketContext || {};
    const generated = report.generatedAtLocal || report.generatedAt || "";

    document.getElementById("hero-copy").textContent = pickText(context.summary, t("reportFallback"));
    document.getElementById("regime-value").textContent = pickText(context.regimeLabel, "Mixed");
    document.getElementById("regime-note").textContent = t("regimeNote", {
      score: Number(context.regimeScore || 0).toFixed(2),
      breadth: Number(context.breadthPositivePct || 0).toFixed(1)
    });

    document.getElementById("fear-value").textContent = String(context.trackedCount || 0);
    document.getElementById("fear-note").textContent = context.fearGreed
      ? t("coverageFearNote", {
        value: context.fearGreed.value,
        label: pickText(context.fearGreed.label)
      })
      : t("coverageNote");

    document.getElementById("generated-value").textContent = generated
      ? new Date(generated).toLocaleTimeString(localeTag(), { hour: "2-digit", minute: "2-digit" })
      : "N/A";
    document.getElementById("generated-note").textContent = generated
      ? new Date(generated).toLocaleDateString(localeTag())
      : t("generatedMissing");

    const longTarget = document.getElementById("long-list");
    const shortTarget = document.getElementById("short-list");

    if (!Array.isArray(report.longCandidates) || !report.longCandidates.length) {
      renderEmpty(longTarget, t("noLongs"));
    } else {
      longTarget.innerHTML = report.longCandidates.map((candidate) => renderCandidate(candidate, "long")).join("");
    }

    if (!Array.isArray(report.shortCandidates) || !report.shortCandidates.length) {
      renderEmpty(shortTarget, t("noShorts"));
    } else {
      shortTarget.innerHTML = report.shortCandidates.map((candidate) => renderCandidate(candidate, "short")).join("");
    }

    renderSummary(report);
    renderMarketViews();
    renderSources(report.headlines || []);
    renderWarnings(report.warnings || []);
    document.getElementById("footer-note").textContent = pickText(report.disclaimer, t("footerFallback"));
  };

  const renderNoReport = () => {
    currentReport = null;
    document.getElementById("regime-value").textContent = "...";
    document.getElementById("regime-note").textContent = t("noSummary");
    document.getElementById("fear-value").textContent = "...";
    document.getElementById("fear-note").textContent = t("coverageNote");
    document.getElementById("generated-value").textContent = "...";
    document.getElementById("generated-note").textContent = t("generatedLatest");
    renderEmpty(document.getElementById("long-list"), t("noLongs"));
    renderEmpty(document.getElementById("short-list"), t("noShorts"));
    renderEmpty(document.getElementById("summary-list"), t("noSummary"));
    renderEmpty(document.getElementById("views-list"), t("noViews"));
    renderEmpty(document.getElementById("headline-list"), t("noSources"));
    renderWarnings([]);
    document.getElementById("footer-note").textContent = t("footerFallback");
  };

  const refreshReport = async ({ enforceCooldown = true } = {}) => {
    const now = Date.now();
    if (enforceCooldown && now - lastRefreshTime < REFRESH_COOLDOWN_MS) {
      const remaining = Math.ceil((REFRESH_COOLDOWN_MS - (now - lastRefreshTime)) / 1000);
      setStatusModel("error", { detail: `Too many requests. Please wait ${remaining}s.` });
      return;
    }

    if (enforceCooldown) {
      lastRefreshTime = now;
    }

    setRefreshBusy(true);
    setStatusModel("busy");

    try {
      const report = await buildReport();
      applyReport(report);

      if (Array.isArray(report.warnings) && report.warnings.length) {
        setStatusModel("success-warning", { count: report.warnings.length });
      } else {
        setStatusModel("success");
      }
    } catch (error) {
      if (enforceCooldown) {
        lastRefreshTime = 0;
      }
      renderNoReport();
      setStatusModel("error", { detail: error.message || "Unknown error." });
    } finally {
      setRefreshBusy(false);
    }
  };

  refreshButton.addEventListener("click", () => {
    refreshReport();
  });

  languageButtons.forEach((button) => {
    button.addEventListener("click", () => {
      currentLang = button.dataset.lang === "ko" ? "ko" : "en";
      localStorage.setItem("morning-futures-lang", currentLang);
      applyLocaleToStatic();
      if (currentReport) {
        applyReport(currentReport);
      } else {
        renderNoReport();
      }
    });
  });

  applyLocaleToStatic();
  renderNoReport();
  setStatusModel("ready");
  refreshReport({ enforceCooldown: false });
})();
