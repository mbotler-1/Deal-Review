<#
render_review.ps1 - Turn a normalized deal JSON into a print-ready HTML deal review.

Cross-platform: Windows PowerShell 5.1 or PowerShell 7+ (pwsh) on macOS/Linux.
No external modules. Point it at a deal JSON (see examples/ and docs/DEAL_SCHEMA.md);
it writes a single, self-contained HTML page.

Usage:
    ./render_review.ps1 examples/won_deal.json -Out examples/output/won_example.html
    ./render_review.ps1 examples/lost_deal.json        # writes alongside the input

The data layer (pulling a real deal from a warehouse) is separate: see skill/ and
config.example.yaml. This renderer only cares about the JSON shape, so feed it from
BigQuery, Snowflake, a CRM export, or hand-authored fixtures like the examples.
#>
param(
  [Parameter(Mandatory = $true, Position = 0)][string]$DealPath,
  [string]$Out
)
$ErrorActionPreference = 'Stop'

# --- Palettes: swap these hex values for your own brand ----------------------
$PALETTES = @{
  'green'      = @{ navy = '#0D1C14'; accent = '#4A9E6A'; accentLight = '#A8D8BA'; accentInk = '#2c6b45'; amber = '#D4903A'; signal = '#3A9EAF' }  # Won
  'blue-gold'  = @{ navy = '#12141C'; accent = '#6A7EC8'; accentLight = '#E2E7F5'; accentInk = '#3a4a86'; amber = '#C8A830'; signal = '#C8A830' }  # Lost - financial
  'purple-red' = @{ navy = '#1A1220'; accent = '#C8664A'; accentLight = '#F3DED6'; accentInk = '#9c4227'; amber = '#7C5CBF'; signal = '#7C5CBF' }  # Lost - brand
  'orange-red' = @{ navy = '#12181F'; accent = '#5B8DD9'; accentLight = '#DFEAF7'; accentInk = '#2f5b93'; amber = '#D46A30'; signal = '#D46A30' }  # Lost - default
}

function Prop($obj, $name) {
  if ($null -eq $obj) { return $null }
  $p = $obj.PSObject.Properties[$name]
  if ($p) { return $p.Value } else { return $null }
}

function New-Css($pal) {
  @"
:root{
  --navy:$($pal.navy); --accent:$($pal.accent); --accent-light:$($pal.accentLight);
  --accent-ink:$($pal.accentInk); --amber:$($pal.amber); --signal:$($pal.signal);
  --red:#C84040; --red-light:#F5DADA; --green:#3AAF80; --green-light:#C6EDD9;
  --border:#D0D9E4; --bg:#F4F6F9; --text:#1A2A3A; --text-muted:#5A6E82;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'Inter','Segoe UI',sans-serif;background:var(--bg);color:var(--text);font-size:13px;line-height:1.5;-webkit-print-color-adjust:exact;print-color-adjust:exact;}
.page{max-width:1200px;margin:0 auto;padding:0 0 60px;background:var(--bg);}
.cover{background:var(--navy);color:#fff;padding:40px 48px 32px;display:flex;justify-content:space-between;align-items:flex-end;gap:20px;}
.cover-title{font-size:28px;font-weight:700;margin-bottom:8px;}
.cover-sub{font-size:14px;color:rgba(255,255,255,.6);}
.cover-right{text-align:right;color:rgba(255,255,255,.5);font-size:12px;white-space:nowrap;}
.chip{display:inline-block;padding:4px 12px;border-radius:20px;font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.05em;margin-right:8px;}
.chip-won{background:var(--green-light);color:var(--green);}
.chip-lost{background:var(--red-light);color:var(--red);}
.chip-alt{background:rgba(255,255,255,.12);color:#fff;}
.stat-bar{display:flex;background:#fff;border-bottom:2px solid var(--border);flex-wrap:wrap;}
.stat{flex:1;min-width:150px;padding:16px 20px;border-right:1px solid var(--border);}
.stat:last-child{border-right:none;}
.stat-label{font-size:10px;text-transform:uppercase;letter-spacing:.06em;color:var(--text-muted);margin-bottom:4px;}
.stat-value{font-size:18px;font-weight:700;color:var(--text);}
.stat-sub{font-size:11px;color:var(--text-muted);margin-top:2px;}
.phase-bar{display:flex;background:var(--navy);flex-wrap:wrap;}
.phase{flex:1;min-width:140px;padding:12px 16px;border-right:1px solid rgba(255,255,255,.1);color:#fff;}
.phase:last-child{border-right:none;}
.phase-num{font-size:10px;opacity:.5;margin-bottom:2px;}
.phase-label{font-weight:600;font-size:12px;}
.phase-lost .phase-label{color:#E8A0A0;}
.phase-dates{font-size:10px;margin-top:3px;opacity:.6;}
.body{background:var(--bg);padding:32px 48px;}
.reason{border-radius:8px;padding:20px 24px;margin-bottom:20px;}
.reason-won{background:var(--green-light);border-left:4px solid var(--green);}
.reason-lost{background:var(--red-light);border-left:4px solid var(--red);}
.context-box{background:#fff;border:1px solid var(--border);border-radius:8px;padding:20px 24px;margin-bottom:24px;}
.box-title{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;margin-bottom:8px;}
.section-header{display:flex;align-items:center;gap:12px;margin:32px 0 16px;}
.section-header h2{font-size:13px;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:var(--text-muted);white-space:nowrap;}
.section-header::after{content:'';flex:1;height:1px;background:var(--border);}
.timeline{position:relative;padding-left:32px;margin-bottom:20px;}
.timeline::before{content:'';position:absolute;left:8px;top:0;bottom:0;width:2px;background:var(--border);}
.t-event{position:relative;margin-bottom:20px;}
.t-dot{position:absolute;left:-28px;top:4px;width:12px;height:12px;border-radius:50%;border:2px solid #fff;box-shadow:0 0 0 2px currentColor;}
.dot-call{background:#3A7EC8;color:#3A7EC8;}
.dot-email{background:#8A9BB0;color:#8A9BB0;}
.dot-sf{background:var(--accent);color:var(--accent);}
.dot-milestone{background:var(--amber);color:var(--amber);width:16px;height:16px;left:-30px;top:2px;}
.dot-gap{background:var(--red);color:var(--red);}
.dot-signal{background:var(--signal);color:var(--signal);}
.dot-lost{background:var(--red);color:var(--red);width:16px;height:16px;left:-30px;top:2px;}
.dot-post{background:#A8D8EA;color:#A8D8EA;}
.t-date{font-size:10px;color:var(--text-muted);margin-bottom:2px;}
.t-title{font-weight:600;font-size:13px;margin-bottom:4px;}
.t-body{font-size:12px;color:var(--text-muted);}
.flag{display:inline-block;font-size:10px;font-weight:600;padding:2px 8px;border-radius:4px;margin-top:4px;}
.flag-gap{background:var(--red-light);color:var(--red);}
.flag-signal{background:#DDF3EC;color:var(--green);}
.call-card{background:#fff;border:1px solid var(--border);border-radius:8px;padding:24px;margin-bottom:24px;}
.call-header{display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:16px;padding-bottom:12px;border-bottom:1px solid var(--border);gap:16px;}
.call-title{font-weight:700;font-size:15px;}
.call-meta{font-size:11px;color:var(--text-muted);margin-top:4px;}
.call-chip{font-size:10px;font-weight:600;padding:3px 10px;border-radius:12px;background:var(--accent-light);color:var(--accent-ink);white-space:nowrap;}
.call-brief{font-size:12px;font-style:italic;color:var(--text-muted);margin-bottom:16px;padding:10px 14px;background:var(--bg);border-radius:6px;}
.call-sections{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
.call-section{margin-bottom:14px;}
.call-section-title{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--text-muted);margin-bottom:8px;}
.call-section ul{list-style:none;padding:0;}
.call-section li{font-size:12px;padding:3px 0 3px 18px;position:relative;}
.call-section li::before{position:absolute;left:0;}
.call-section li.pos::before{content:'\2713';color:var(--green);}
.call-section li.warn::before{content:'\26A0';color:var(--amber);}
.call-section li.note::before{content:'\25CF';color:var(--text-muted);font-size:9px;top:3px;}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:12px;}
.card{background:#fff;border:1px solid var(--border);border-radius:8px;padding:20px;}
.card-title{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--text-muted);margin-bottom:12px;}
.card ul{list-style:none;padding:0;}
.card li{font-size:12px;padding:3px 0 3px 16px;position:relative;color:var(--text);}
.card li::before{content:'\25CF';position:absolute;left:0;color:var(--accent);font-size:9px;top:4px;}
.grid3{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:12px;}
.tri-card{background:#fff;border-radius:8px;padding:20px;border-top:3px solid var(--accent);}
.tri-card.win{border-top-color:var(--green);}
.tri-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;margin-bottom:8px;color:var(--accent);}
.tri-card.win .tri-label{color:var(--green);}
.tri-card p{font-size:12px;color:var(--text-muted);}
.gaps-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;}
.gap-card{background:#fff;border-radius:8px;padding:20px;border-left:3px solid var(--red);}
.gap-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.06em;color:var(--red);margin-bottom:8px;}
.gap-card p{font-size:12.5px;}
.gap-rec{margin-top:10px;padding-top:10px;border-top:1px solid var(--border);font-size:11px;color:var(--text-muted);}
.gap-rec strong{color:var(--text);}
.footer{background:var(--navy);color:rgba(255,255,255,.4);padding:16px 48px;font-size:11px;display:flex;justify-content:space-between;gap:16px;flex-wrap:wrap;}
@media (max-width:760px){.grid2,.grid3,.call-sections,.gaps-grid{grid-template-columns:1fr;}}
@media print{body{font-size:11px;}.page{max-width:100%;padding:0;}}
"@
}

function Get-ChipsHtml($chips, $outcome) {
  $sb = ''
  for ($i = 0; $i -lt $chips.Count; $i++) {
    if ($i -eq 0) { $cls = if ($outcome -eq 'won') { 'chip-won' } else { 'chip-lost' } }
    else { $cls = 'chip-alt' }
    $sb += "<span class=""chip $cls"">$($chips[$i])</span>"
  }
  return $sb
}

function Get-FlagHtml($flag) {
  if (-not $flag) { return '' }
  $kind = Prop $flag 'kind'; if (-not $kind) { $kind = 'gap' }
  $cls = if ($kind -eq 'signal') { 'flag-signal' } else { 'flag-gap' }
  return "<span class=""flag $cls"">$(Prop $flag 'text')</span>"
}

function Get-TimelineHtml($events) {
  $rows = foreach ($e in $events) {
    $dot = Prop $e 'dot'; if (-not $dot) { $dot = 'sf' }
    "<div class=""t-event""><div class=""t-dot dot-$dot""></div>" +
    "<div class=""t-date"">$(Prop $e 'date')</div>" +
    "<div class=""t-title"">$(Prop $e 'title')</div>" +
    "<div class=""t-body"">$(Prop $e 'body')</div>$(Get-FlagHtml (Prop $e 'flag'))</div>"
  }
  return "<div class=""timeline"">$($rows -join '')</div>"
}

function Get-CallsHtml($calls) {
  $cards = foreach ($c in $calls) {
    $secs = @(foreach ($s in (Prop $c 'sections')) {
        $items = ''
        foreach ($it in (Prop $s 'items')) {
          $k = Prop $it 'kind'; if (-not $k) { $k = 'note' }
          $items += "<li class=""$k"">$(Prop $it 'text')</li>"
        }
        "<div class=""call-section""><div class=""call-section-title"">$(Prop $s 'title')</div><ul>$items</ul></div>"
      })
    $mid = [math]::Ceiling($secs.Count / 2)
    $left = ($secs[0..([math]::Max(0, $mid - 1))] -join '')
    $right = if ($mid -lt $secs.Count) { ($secs[$mid..($secs.Count - 1)] -join '') } else { '' }
    if ($secs.Count -eq 0) { $left = ''; $right = '' }
    $brief = if (Prop $c 'brief') { "<div class=""call-brief"">$(Prop $c 'brief')</div>" } else { '' }
    $chip = if (Prop $c 'chip') { "<span class=""call-chip"">$(Prop $c 'chip')</span>" } else { '' }
    "<div class=""call-card""><div class=""call-header""><div>" +
    "<div class=""call-title"">$(Prop $c 'title')</div>" +
    "<div class=""call-meta"">$(Prop $c 'meta')</div></div>$chip</div>" +
    "$brief<div class=""call-sections""><div>$left</div><div>$right</div></div></div>"
  }
  return ($cards -join '')
}

function Get-MomentsHtml($moments) {
  $cards = foreach ($m in $moments) {
    $items = ''
    foreach ($i in (Prop $m 'items')) { $items += "<li>$i</li>" }
    "<div class=""card""><div class=""card-title"">$(Prop $m 'title')</div><ul>$items</ul></div>"
  }
  return "<div class=""grid2"">$($cards -join '')</div>"
}

function Get-TriHtml($items, $win) {
  $cls = if ($win) { 'tri-card win' } else { 'tri-card' }
  $cards = foreach ($i in $items) {
    "<div class=""$cls""><div class=""tri-label"">$(Prop $i 'label')</div><p>$(Prop $i 'text')</p></div>"
  }
  return "<div class=""grid3"">$($cards -join '')</div>"
}

function Get-GapsHtml($gaps) {
  $cards = foreach ($g in $gaps) {
    $rec = if (Prop $g 'rec') { "<div class=""gap-rec""><strong>Recommendation:</strong> $(Prop $g 'rec')</div>" } else { '' }
    "<div class=""gap-card""><div class=""gap-label"">$(Prop $g 'label')</div><p>$(Prop $g 'body')</p>$rec</div>"
  }
  return "<div class=""gaps-grid"">$($cards -join '')</div>"
}

function Get-StatsHtml($stats) {
  $cells = foreach ($s in $stats) {
    "<div class=""stat""><div class=""stat-label"">$(Prop $s 'label')</div>" +
    "<div class=""stat-value"">$(Prop $s 'value')</div>" +
    "<div class=""stat-sub"">$(Prop $s 'sub')</div></div>"
  }
  return "<div class=""stat-bar"">$($cells -join '')</div>"
}

function Get-PhasesHtml($phases) {
  $n = 0
  $cells = foreach ($ph in $phases) {
    $n++
    $lost = if (Prop $ph 'lost') { ' phase-lost' } else { '' }
    "<div class=""phase$lost""><div class=""phase-num"">Phase $n</div>" +
    "<div class=""phase-label"">$(Prop $ph 'label')</div>" +
    "<div class=""phase-dates"">$(Prop $ph 'dates')</div></div>"
  }
  return "<div class=""phase-bar"">$($cells -join '')</div>"
}

function Get-Section($title, $inner) {
  return "<div class=""section-header""><h2>$title</h2></div>$inner"
}

# --- Load & render -----------------------------------------------------------
if (-not (Test-Path -LiteralPath $DealPath)) { throw "Deal file not found: $DealPath" }
# Read as UTF-8 explicitly. Windows PowerShell 5.1's Get-Content defaults to ANSI, which mangles
# non-ASCII characters (accented names, em dashes) in a UTF-8 JSON file.
$dealJson = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $DealPath), (New-Object System.Text.UTF8Encoding($false)))
$deal = $dealJson | ConvertFrom-Json

$outcome = Prop $deal 'outcome'; if (-not $outcome) { $outcome = 'won' }
$palName = Prop $deal 'palette'
if (-not $palName) { $palName = if ($outcome -eq 'won') { 'green' } else { 'blue-gold' } }
$pal = $PALETTES[$palName]; if (-not $pal) { $pal = $PALETTES['green'] }

$parts = New-Object System.Collections.Generic.List[string]

$parts.Add("<div class=""cover""><div><div style=""margin-bottom:12px;"">" +
  "$(Get-ChipsHtml (Prop $deal 'chips') $outcome)</div>" +
  "<div class=""cover-title"">$(Prop $deal 'title')</div>" +
  "<div class=""cover-sub"">$(Prop $deal 'subtitle')</div></div>" +
  "<div class=""cover-right"">$(Prop $deal 'closed_label')<br>Prepared by Sales Ops</div></div>")
$parts.Add((Get-StatsHtml (Prop $deal 'stats')))
$parts.Add((Get-PhasesHtml (Prop $deal 'phases')))

$body = New-Object System.Collections.Generic.List[string]
$reasonCls = if ($outcome -eq 'won') { 'reason-won' } else { 'reason-lost' }
$reasonInk = if ($outcome -eq 'won') { 'var(--accent-ink)' } else { 'var(--red)' }
if (Prop $deal 'summary') {
  $st = Prop $deal 'summary_title'
  if (-not $st) { $st = if ($outcome -eq 'won') { 'Why This Deal Closed' } else { 'Why This Deal Was Lost' } }
  $body.Add("<div class=""reason $reasonCls""><div class=""box-title"" style=""color:$reasonInk;"">$st</div><p>$(Prop $deal 'summary')</p></div>")
}
if (Prop $deal 'context') {
  $body.Add("<div class=""context-box""><div class=""box-title"" style=""color:var(--text-muted);"">Deal Context</div><p>$(Prop $deal 'context')</p></div>")
}
if (Prop $deal 'timeline') { $body.Add((Get-Section 'Deal Timeline' (Get-TimelineHtml (Prop $deal 'timeline')))) }
if (Prop $deal 'calls') { $body.Add((Get-Section 'Call Deep Dives' (Get-CallsHtml (Prop $deal 'calls')))) }
if (Prop $deal 'moments') { $body.Add((Get-Section 'Key Moments' (Get-MomentsHtml (Prop $deal 'moments')))) }
if (Prop $deal 'wins') { $body.Add((Get-Section 'What Worked' (Get-TriHtml (Prop $deal 'wins') $true))) }
if (Prop $deal 'reengage') { $body.Add((Get-Section 'Re-Engagement Path' (Get-TriHtml (Prop $deal 'reengage') $false))) }
if (Prop $deal 'gaps') { $body.Add((Get-Section 'Process Gaps' (Get-GapsHtml (Prop $deal 'gaps')))) }
$parts.Add("<div class=""body"">$($body -join '')</div>")

$footL = Prop $deal 'footer_left'; if (-not $footL) { $footL = 'Confidential - Internal Use' }
$parts.Add("<div class=""footer""><span>$footL</span><span>$(Prop $deal 'footer_id')</span></div>")

$title = Prop $deal 'title'; if (-not $title) { $title = 'Deal Review' }
$html = "<!DOCTYPE html>`n<html lang=""en"">`n<head>`n<meta charset=""UTF-8"">`n" +
  "<title>$title</title>`n<style>$(New-Css $pal)</style>`n</head>`n<body>`n" +
  "<div class=""page"">`n$($parts -join "`n")`n</div>`n</body>`n</html>`n"

if (-not $Out) { $Out = [System.IO.Path]::ChangeExtension($DealPath, '.html') }
$dir = Split-Path -Parent $Out
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
[System.IO.File]::WriteAllText($Out, $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote $Out"
