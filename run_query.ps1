<#
run_query.ps1 - Run a BigQuery SQL file via the bq CLI and return rows as JSON/CSV.

Generic runner for the warehouse reference implementation. Nothing here is specific to any
company's schema — the project id and SDK path come from parameters or environment, and the
SQL (with named parameters) comes from a file.

Environment / params:
  -Project      BigQuery project id (or set env DEAL_REVIEW_BQ_PROJECT)
  -SdkBin       Path to the Google Cloud SDK 'bin' dir if `bq` is not on PATH
                (or set env GCLOUD_SDK_BIN). Leave empty to use PATH.
  -Params       Hashtable of BigQuery named params -> values (STRING typed). Reference as @name in SQL.
  -MaxRows      Row cap (default 5000).
  -Format       json (default) | prettyjson | csv
  -OutFile      Write result here (UTF-8, no BOM) instead of returning it.

Usage:
  ./run_query.ps1 -SqlFile queries/10_resolve_opportunity.sql -Params @{ opp_query = 'Acme' } -Format prettyjson
#>
param(
  [Parameter(Mandatory = $true)][string]$SqlFile,
  [string]$Project = $env:DEAL_REVIEW_BQ_PROJECT,
  [string]$SdkBin = $env:GCLOUD_SDK_BIN,
  [hashtable]$Params = @{},
  [int]$MaxRows = 5000,
  [ValidateSet('json', 'prettyjson', 'csv', 'pretty')][string]$Format = 'json',
  [string]$OutFile
)
$ErrorActionPreference = 'Stop'

if (-not $Project) { throw "No BigQuery project. Pass -Project or set DEAL_REVIEW_BQ_PROJECT." }
if ($SdkBin -and (Test-Path $SdkBin)) { $env:PATH = "$SdkBin;$env:PATH" }
$bq = 'bq'
$bqCmd = Get-Command bq -ErrorAction SilentlyContinue
if (-not $bqCmd) { throw "The 'bq' CLI was not found. Install the Google Cloud SDK or set -SdkBin / GCLOUD_SDK_BIN." }

if (-not (Test-Path -LiteralPath $SqlFile)) { throw "SQL file not found: $SqlFile" }
$sql = Get-Content -Raw -LiteralPath $SqlFile
$sql = $sql -replace '^\xEF\xBB\xBF', ''  # strip UTF-8 BOM

# The bq.cmd wrapper truncates a positional argument at the first newline, and a query beginning
# with a `--` comment is misread as a flag. Drop every `--` line comment and flatten to one line.
# (Assumes no `--` inside a string literal, which holds for the shipped templates.)
$lines = $sql -split "`r?`n"
$clean = foreach ($ln in $lines) {
  $idx = $ln.IndexOf('--')
  if ($idx -ge 0) { $ln.Substring(0, $idx) } else { $ln }
}
$sql = (($clean -join ' ') -replace '\s+', ' ').Trim()

$bqArgs = @('query', "--project_id=$Project", '--use_legacy_sql=false', "--format=$Format", "--max_rows=$MaxRows")
foreach ($k in $Params.Keys) { $bqArgs += "--parameter=$($k):STRING:$($Params[$k])" }
$bqArgs += $sql

$result = & $bq @bqArgs

if ($OutFile) {
  $dir = Split-Path -Parent $OutFile
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [System.IO.File]::WriteAllText($OutFile, ($result -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "Wrote $OutFile"
}
else { $result }
