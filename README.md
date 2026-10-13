# Deal Review Generator

> Print-ready HTML deal-process reviews for Closed Won & Lost opportunities — CRM timeline, call intelligence, and automated process-gap analysis.

Turn a single opportunity into an **executive-ready, print-ready HTML deal-process review** —
a timeline of CRM stage changes and activities, call-intelligence cards, and an automated
process-gap analysis. Works for **Closed Won** and **Closed Lost** deals.

The engine is a small, dependency-free renderer that takes a **normalized deal JSON** and
produces a self-contained HTML page. Where the JSON comes from is up to you — a warehouse
(BigQuery/Snowflake), a CRM export, or hand-authored fixtures like the two included examples.

> Data and rendering are deliberately decoupled. The renderer never talks to your warehouse;
> it only reads the deal JSON. That keeps the showcase runnable by anyone and lets you wire it
> to whatever data source you have.

## See it in 30 seconds (no warehouse, no accounts needed)

```powershell
# PowerShell 7+ (pwsh) on macOS/Linux/Windows, or Windows PowerShell 5.1
./render_review.ps1 won_deal.json -Out won_example.html
./render_review.ps1 lost_deal.json -Out lost_example.html
```

Open the HTML in a browser. Pre-rendered copies are committed as
[`won_example.html`](won_example.html) and [`lost_example.html`](lost_example.html) so you can preview without running anything.

| Example | Outcome | What it shows |
|---|---|---|
| [`won_deal.json`](won_deal.json) → [won_example.html](won_example.html) | **Closed Won** | Green palette, "What Worked" wins grid, win-reason box |
| [`lost_deal.json`](lost_deal.json) → [lost_example.html](lost_example.html) | **Closed Lost** | Blue-gold palette, loss-reason box, "Re-Engagement Path" |

*(All example data is fictional — Acme Robotics and Globex Media are made up.)*

## What a review contains

- **Cover + stat bar** — amount, cycle, owner, lead source, outcome
- **Phase swimlane** — the deal mapped to your process stages
- **Win / loss reason** box
- **Chronological timeline** — activities, calls, and CRM field changes, with gap/signal flags
- **Call deep-dive cards** — goals, buying signals, objections, pricing
- **Key moments** grid
- **What Worked** (won) *or* **Re-Engagement Path** (lost)
- **Process-gap analysis** — SLA, forecast hygiene, attribution, discounting, and more

## How to print / share

Open the HTML in Chrome → `Ctrl/Cmd+P` → **Save as PDF** → Portrait, Minimum margins,
✓ **Background graphics**.

## Project layout

```
deal-review-generator/
├─ render_review.ps1        # the renderer: deal JSON -> HTML (dependency-free)
├─ won_deal.json            # fictional Closed Won fixture
├─ lost_deal.json           # fictional Closed Lost fixture
├─ won_example.html        # pre-rendered sample HTML
├─ lost_example.html       # pre-rendered sample HTML
├─ DEAL_SCHEMA.md           # the normalized deal-JSON contract
├─ SCHEMA_MAPPING.md       # how to map your CRM/warehouse into that JSON
├─ SKILL.md                 # orchestration for use as a Claude Code skill
├─ 10_resolve_opportunity.sql
├─ 20_opportunity.sql
├─ 30_field_history.sql
├─ 40_activities.sql
├─ 50_calls.sql
├─ run_query.ps1            # generic bq CLI runner
├─ config.example.yaml      # warehouse + schema mapping (copy to config.yaml)
├─ .gitignore
├─ LICENSE                  # MIT
└─ deal-review-generator.zip
```

## Connect your own data

You have two options:

1. **Bring your own JSON.** Produce a deal JSON in the shape described in
   [`DEAL_SCHEMA.md`](DEAL_SCHEMA.md) from any source, then run `render_review.ps1`.
2. **Use the warehouse skill.** [`SKILL.md`](SKILL.md) contains a BigQuery reference implementation
   (a `bq` CLI runner + parameterized SQL templates). Copy `config.example.yaml` to `config.yaml`,
   fill in your project, datasets, and column mapping (see
   [`SCHEMA_MAPPING.md`](SCHEMA_MAPPING.md)), and adapt the queries to your CRM schema.
   It was originally built against a CRM + call-recording warehouse; the SQL is templated so you can
   repoint it. As a Claude Code skill, invoking it with an opportunity name/ID resolves the deal,
   pulls the data, and hands it to the renderer.

## Requirements

- **Renderer:** PowerShell 7+ (`pwsh`, cross-platform) or Windows PowerShell 5.1. No modules.
- **Warehouse skill (optional):** the Google Cloud SDK (`bq`) on your `PATH`, plus read access to
  your warehouse. Nothing warehouse-specific is hardcoded — it's all in `config.yaml`.

## Publishing to GitHub

This repo is self-contained and safe to make public — it has no real customer data or internal
schema (the examples are fictional). To put it on GitHub, run these in a terminal from the
unzipped folder:

```bash
git init
git add .
git commit -m "Initial commit: Deal Review Generator"
```

Then create the remote and push. With the GitHub CLI (`gh`):

```bash
gh repo create deal-review-generator --public --source=. --push
```

Or, without `gh`, create an empty repo on github.com first, then:

```bash
git remote add origin https://github.com/<your-username>/deal-review-generator.git
git branch -M main
git push -u origin main
```

Before pushing, you may want to:
- Put your name/handle in [`LICENSE`](LICENSE).
- Drop a screenshot of a rendered example near the top of this README — GitHub renders images
  inline, and it makes the repo far more compelling at a glance.

## License

MIT — see [LICENSE](LICENSE).
