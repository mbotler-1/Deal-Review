# Mapping your warehouse to a deal review

The renderer is warehouse-agnostic — it only reads the deal JSON
([`DEAL_SCHEMA.md`](DEAL_SCHEMA.md)). To generate that JSON from your own data, you connect a
data layer. The included `skill/` is a **BigQuery reference implementation**; the same shape works
for Snowflake, a CRM export, or anything else.

## The pipeline

```
opportunity name/ID
      │
      ▼
resolve  ──►  extract (opportunity, activities, field history, calls)  ──►  normalize to deal JSON  ──►  render_review.ps1  ──►  HTML
```

## Step-by-step

1. **Resolve** the opportunity from a name or ID. If a name matches more than one, present the
   candidates (id / account / amount / stage / close date / owner) and ask which one.
2. **Extract** the pieces:
   - **Opportunity** — the current record (amount, stage, close date, owner, lead source, loss reason).
   - **Activities** — tasks/events/emails for the timeline. In many CRMs activities attach to the
     *account*, not the opportunity — pull by account within the deal's date window, then merge
     anything explicitly linked to the opp.
   - **Field history** — field-level changes over time. Two common sources:
     - *Snapshot diff:* if you keep daily row snapshots, diff consecutive days per field.
     - *Audit table:* if your CRM exposes a native field-history/audit feed, read it directly.
   - **Calls** (optional) — transcripts or AI briefs from your call platform, joined by account/opp.
3. **Normalize** the rows into the deal JSON. This is the one warehouse-specific step: map your
   columns (see `config.example.yaml` → `schema_map`) into `stats`, `timeline`, `calls`, etc.
4. **Render** with `render_review.ps1`.

## Field-mapping cheatsheet

| Deal JSON | Typical CRM source |
|---|---|
| `stats` (amount, cycle, owner, lead source) | opportunity record |
| `phases` | your stage picklist, grouped into ~5 phases |
| `summary` / reason box | win/loss reason + call synthesis |
| `timeline` (dot=`sf`) | field-history changes (stage, amount, owner, close date) |
| `timeline` (dot=`call`/`email`/`milestone`) | activities / meetings |
| `calls` | call transcripts or AI briefs |
| `gaps` | derived checks (see below) |

## Process-gap checks (portable ideas)

These are CRM-agnostic and drive the `gaps` section. Compute what your data supports:

- **Creation lag** — opp created long after the first meeting.
- **Amount accuracy** — booked amount vs. amount at creation / quoted.
- **Close-date slippage** — count of close-date pushes.
- **Forecast hygiene** — probability that never reflected reality (e.g. high until the day it's lost).
- **Stage compression / dwell** — multiple stages in one day, or months parked in one stage.
- **Attribution** — SDR/AE/CS credit and record-type correctness.
- **Re-engage task (lost)** — was a dated follow-up created for a timing/budget loss?
- **Objection follow-through** — was a blocker raised on a call ever resolved/tracked?

## A note on this reference implementation

`skill/queries/*.sql` are BigQuery templates with `{{placeholders}}` for project/dataset/table and
generic column names. They were generalized from a CRM + call-recording warehouse. Expect to edit the
column names and joins to match your CRM — treat them as a starting point, not turnkey.
