# Refreshes gauges.json from the NOAA NWPS catalog.
# Run from the repo root: .\update-gauges.ps1
# NOAA's /v1/gauges endpoint can 504 intermittently — retry if it fails.

$ErrorActionPreference = "Stop"
$url = "https://api.water.noaa.gov/nwps/v1/gauges"
$out = Join-Path $PSScriptRoot "gauges.json"

Write-Host "Fetching $url ..."
$r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 300
Write-Host ("Got {0} bytes" -f $r.RawContentLength)

$j = $r.Content | ConvertFrom-Json
$stripped = @($j.gauges | Where-Object { $_.lid -and $_.name } | ForEach-Object {
    [ordered]@{
        lid   = $_.lid
        name  = $_.name
        state = if ($_.state -and $_.state.abbreviation) { $_.state.abbreviation } else { "" }
    }
})

$json = $stripped | ConvertTo-Json -Compress -Depth 5
[System.IO.File]::WriteAllText($out, $json, (New-Object System.Text.UTF8Encoding($false)))
$size = (Get-Item $out).Length

Write-Host ("Wrote {0} ({1} gauges, {2} bytes)" -f $out, $stripped.Count, $size)
