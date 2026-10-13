---
name: deal-review
description: Generate a Sales Deal Process Review from a data warehouse. Trigger when the user asks for a deal review / deal-process review AND provides an opportunity name or ID. Resolves the opportunity (asking which one if the name is ambiguous), pulls the deal's CRM + call data, normalizes it to a deal JSON, and renders a print-ready HTML review.
---

# Deal Review (warehouse skill)

Optional data layer for the Deal Review Generator. Pulls a real opportunity from your warehouse
and hands it to `render_review.ps1`. This is a **BigQuery reference implementation** — the SQL is
templated (`{{placeholders}}`) so you can repoint it at your own schema. See
`SCHEMA_MAPPING.md`.

## Prerequisites
- `config.yaml` filled in (copy from `..config.example.yaml`): project, datasets, and the
  `schema_map` column mapping.
- The `bq` CLI on PATH (or `gcloud_sdk_bin` set in config); read access to your warehouse.

## When to run
Trigger when BOTH: (1) the user asks for a deal / deal-process review, AND (2) an opportunity name
or ID is provided. If no opp is given, ask for it first.

## Step 1 — resolve the opportunity
Run `10_resolve_opportunity.sql` with `-Params @{ opp_query = '<name-or-id>' }`.
- **1 row** → use it; echo name / account / amount / stage / close date / owner to confirm.
- **>1 row** → STOP and ask which one, showing `id | account | amount | stage | close_date | owner`.
- **0 rows** → report no match; suggest checking spelling or using an ID.

## Step 2 — extract the deal data
With the resolved ids, run the extraction templates (save each as JSON):

| Query | Produces |
|---|---|
| `20_opportunity.sql` | current opportunity record |
| `30_field_history.sql` | field-level changes over time (snapshot-diff or audit table) |
| `40_activities.sql` | activity timeline (pull by account within the deal window) |
| `50_calls.sql` | call transcripts / AI briefs (optional) |

Notes that generalize across CRMs:
- Activities often attach to the **account**, not the opp — pull by account in the deal window,
  then merge anything explicitly linked to the opp.
- If a call source isn't in the warehouse, fall back to call *events* from activities, or skip the
  call cards. Never fabricate call content.

## Step 3 — normalize to the deal JSON
Map the rows into the shape in `DEAL_SCHEMA.md`:
- opportunity + cycle math → `stats`; stage picklist → `phases`
- field-history changes → `timeline` events (dot=`sf`), with gap/signal `flag`s
- activities/meetings → `timeline` events (dot=`call`/`email`/`milestone`)
- calls → `calls` cards; win/loss reason + synthesis → `summary`
- derived checks → `gaps` (see `../docs/SCHEMA_MAPPING.md` for the check list)
- Infer `outcome` from stage (Closed Won → won, Closed Lost → lost).

## Step 4 — render
`render_review.ps1 <deal.json> -Out <output.dir>/<Account>_Deal_Review.html`

## Rules
- Never string-interpolate the opp name/ID into SQL — pass via `-Params` (BigQuery named params).
- Keep everything warehouse-specific in `config.yaml` and the query templates; the renderer stays generic.
