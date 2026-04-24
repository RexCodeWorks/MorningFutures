# Morning Futures

Morning Futures is a crypto futures watchlist dashboard. It now supports a browser-only mode that rebuilds the report live from public OKX data, which makes it a good fit for GitHub Pages.

The browser version is aimed at a lightweight personal dashboard:

- refresh on demand from the page itself
- no always-on personal computer required
- no Telegram or Discord setup required
- no RSS dependency
- easy to publish through GitHub Pages

It is intentionally opinionated and simple. The output is a watchlist helper, not financial advice.

## Recommended Mode: GitHub Pages

The `dashboard/` app can be deployed directly to GitHub Pages. In this mode:

- `dashboard/index.html` loads the UI
- `dashboard/app.js` fetches public OKX market data directly in the browser
- the refresh button rebuilds the watchlist live without PowerShell
- `.github/workflows/deploy-pages.yml` deploys the `dashboard/` folder to GitHub Pages on push

### Publish It

1. Push this repository to GitHub.
2. In GitHub, open `Settings -> Pages`.
3. Set the source to `GitHub Actions`.
4. Push to `main` or `master`, or run the `Deploy Dashboard To GitHub Pages` workflow manually.
5. Open the Pages URL GitHub gives you.

## What The Browser Version Uses

- OKX public swap tickers
- OKX 1H swap candles
- OKX funding-rate snapshots
- Alternative.me Fear & Greed as optional context when available

## Project Layout

- `dashboard/index.html`
  Main dashboard UI.
- `dashboard/app.js`
  Browser-side live data fetch and scoring logic for GitHub Pages.
- `.github/workflows/deploy-pages.yml`
  GitHub Pages deployment workflow for the `dashboard/` folder.
- `scripts/Update-MorningFuturesReport.ps1`
  Legacy local report builder.
- `scripts/Start-MorningFuturesDashboard.ps1`
  Legacy local HTTP server.
- `scripts/Register-MorningFuturesTask.ps1`
  Legacy Windows Task Scheduler helper.
- `scripts/Test-MorningFuturesSmoke.ps1`
  Legacy PowerShell smoke test.

## Legacy Local PowerShell Mode

The older Windows-first flow still exists if you want it later:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Update-MorningFuturesReport.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\Start-MorningFuturesDashboard.ps1
```

Then open `http://localhost:8787`.

## Notes

- The scoring model favors liquid perpetual futures pairs.
- The default watchlist is intentionally biased toward large and mid-cap swaps so the first refresh is less noisy.
- Public APIs can rate-limit, change shape, or block browser access. If that happens, the dashboard will need endpoint or logic updates.
- A strong score is not a guarantee. Use it as a watchlist, not as an autopilot.
