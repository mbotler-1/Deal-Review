# Deal JSON schema

The renderer (`render_review.ps1`) consumes one JSON object per deal. Every section is optional —
omit a key and that section is skipped. Text fields accept inline HTML (`<strong>`, `<br>`), so
content you control can be lightly formatted. See `examples/won_deal.json` and
`examples/lost_deal.json` for complete, working instances.

## Top level

| Key | Type | Notes |
|---|---|---|
| `outcome` | `"won"` \| `"lost"` | Drives default palette and reason-box styling. Default `"won"`. |
| `palette` | string | Optional override: `green`, `blue-gold`, `purple-red`, `orange-red`. Defaults to `green` for won, `blue-gold` for lost. |
| `title` | string | Cover title, e.g. `"Acme Robotics Deal Review"`. |
| `chips` | string[] | Cover chips. The **first** is styled by `outcome` (won=green, lost=red); the rest are neutral. |
| `subtitle` | string | Cover subtitle line. |
| `closed_label` | string | Top-right cover text, e.g. `"Closed 2026-03-18"`. |
| `footer_left` | string | Footer left text. |
| `footer_id` | string | Footer right text, e.g. an opp ID. |
| `summary_title` | string | Reason-box heading. Defaults to "Why This Deal Closed" / "Why This Deal Was Lost". |
| `summary` | string | Reason-box paragraph. |
| `context` | string | "Deal Context" paragraph. |

## Sections (arrays)

**`stats`** — up to 5 cells in the stat bar:
```json
{ "label": "Amount", "value": "$120K", "sub": "up from $90K initial" }
```

**`phases`** — the process swimlane (rendered left→right, auto-numbered):
```json
{ "label": "Proposal", "dates": "Feb 27 – Mar 10", "lost": false }
```
Set `"lost": true` on the final phase of a lost deal to tint it red.

**`timeline`** — chronological events:
```json
{ "date": "Mar 6, 2026", "dot": "sf", "title": "Amount raised", "body": "...",
  "flag": { "kind": "signal", "text": "Scope expansion" } }
```
`dot` ∈ `call, email, sf, milestone, gap, signal, lost, post`. `flag.kind` ∈ `gap, signal` (optional).

**`calls`** — call deep-dive cards:
```json
{ "title": "Call 1: Discovery", "meta": "Feb 19 · 32 min · ...", "chip": "Discovery",
  "brief": "One-paragraph summary.",
  "sections": [
    { "title": "Buying Signals", "items": [ { "kind": "pos", "text": "Committed to April go-live" } ] }
  ] }
```
`item.kind` ∈ `pos` (✓ green), `warn` (⚠ amber), `note` (● grey). Sections auto-split into two columns.

**`moments`** — 2×2 key-moments grid:
```json
{ "title": "Pricing & Budget", "items": ["$90K initial", "$120K full-funnel"] }
```

**`wins`** (won) / **`reengage`** (lost) — a 3-card grid:
```json
{ "label": "Speed to Value", "text": "Discovery-to-close in ~3 weeks." }
```

**`gaps`** — process-gap cards:
```json
{ "label": "Gap 1: Creative Readiness", "body": "What happened.", "rec": "The fix." }
```

## Minimal example

```json
{
  "outcome": "won",
  "title": "Acme Deal Review",
  "chips": ["Closed Won", "Enterprise"],
  "stats": [{ "label": "Amount", "value": "$120K" }],
  "phases": [{ "label": "Discovery" }, { "label": "Closed Won" }],
  "summary": "Closed fast on a clear launch deadline.",
  "gaps": [{ "label": "Gap 1", "body": "…", "rec": "…" }]
}
```
