param(
    [int]$Port = 8787
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\MorningFutures.ps1")

$projectRoot = Get-ProjectRoot
$dashboardRoot = Join-Path $projectRoot "dashboard"
$dataRoot = Join-Path $projectRoot "data"
$configPath = Join-Path $projectRoot "config.json"

function Write-JsonResponse {
    param(
        [Parameter(Mandatory = $true)]
        [System.Net.HttpListenerResponse]$Response,
        [Parameter(Mandatory = $true)]
        [object]$Payload,
        [int]$StatusCode = 200
    )

    $json = $Payload | ConvertTo-Json -Depth 8
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $Response.StatusCode = $StatusCode
    $Response.ContentType = "application/json; charset=utf-8"
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
}

function Invoke-DashboardRefresh {
    $config = Get-MorningFuturesConfig -ConfigPath $configPath
    $report = New-MorningFuturesReport -Config $config
    $outputPath = Save-MorningFuturesReport -Report $report

    return [pscustomobject]@{
        ok = $true
        outputPath = $outputPath
        generatedAt = $report.generatedAt
        generatedAtLocal = $report.generatedAtLocal
        warningCount = @($report.warnings).Count
        warnings = @($report.warnings)
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add(("http://localhost:{0}/" -f $Port))
$listener.Start()

Write-Host ("Morning Futures dashboard is live at http://localhost:{0}" -f $Port)
Write-Host "Press Ctrl+C to stop the local server."

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $requestPath = $context.Request.Url.AbsolutePath
        $requestMethod = $context.Request.HttpMethod
        $filePath = $null
        $contentType = "text/plain; charset=utf-8"

        try {
            if ($requestPath -eq "/api/refresh") {
                if ($requestMethod -ne "POST") {
                    Write-JsonResponse -Response $context.Response -Payload @{
                        ok = $false
                        message = "Method not allowed."
                    } -StatusCode 405
                }
                else {
                    $refreshResult = Invoke-DashboardRefresh
                    Write-JsonResponse -Response $context.Response -Payload $refreshResult
                }
            }
            else {
                if ($requestPath -eq "/" -or $requestPath -eq "/dashboard" -or $requestPath -eq "/dashboard/") {
                    $filePath = Join-Path $dashboardRoot "index.html"
                    $contentType = "text/html; charset=utf-8"
                }
                elseif ($requestPath -like "/data/*") {
                    $relative = $requestPath.Substring(6)
                    $filePath = Join-Path $dataRoot $relative
                    $contentType = "application/json; charset=utf-8"
                }
                elseif ($requestPath -like "/dashboard/*") {
                    $relative = $requestPath.Substring(11)
                    $filePath = Join-Path $dashboardRoot $relative
                    $contentType = "text/html; charset=utf-8"
                }

                if ($filePath -and (Test-Path -LiteralPath $filePath)) {
                    $bytes = [System.IO.File]::ReadAllBytes($filePath)
                    $context.Response.StatusCode = 200
                    $context.Response.ContentType = $contentType
                    $context.Response.ContentLength64 = $bytes.Length
                    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
                else {
                    $message = [System.Text.Encoding]::UTF8.GetBytes("Not found")
                    $context.Response.StatusCode = 404
                    $context.Response.ContentType = "text/plain; charset=utf-8"
                    $context.Response.ContentLength64 = $message.Length
                    $context.Response.OutputStream.Write($message, 0, $message.Length)
                }
            }
        }
        catch {
            Write-JsonResponse -Response $context.Response -Payload @{
                ok = $false
                message = $_.Exception.Message
            } -StatusCode 500
        }

        $context.Response.OutputStream.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
}
