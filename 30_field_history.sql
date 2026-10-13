-- TEMPLATE. Replace {{placeholders}} from config.yaml. BigQuery dialect.
-- Field-level history for one opportunity, two supported modes (see field_history_mode):
--
-- (A) snapshot_diff  -- you keep daily row snapshots in {{field_history_table}} with a batch_date.
--     Diff consecutive snapshots per tracked field and emit rows where the value changed.
--     Below is the snapshot-diff pattern; list the fields you want to track in the UNPIVOT.
-- (B) audit_table    -- if your CRM exposes a native field-history/audit feed, SELECT from it
--     directly instead: (edit_date, field, old_value, new_value) WHERE opportunity_id = @opp_id.
--
-- Param: @opp_id
WITH snap AS (
  SELECT
    {{opportunity_id_col}} AS opportunity_id, batch_date,
    CAST({{stage_col}}      AS STRING) AS stage,
    CAST({{amount_col}}     AS STRING) AS amount,
    CAST({{close_date_col}} AS STRING) AS close_date,
    CAST({{owner_col}}      AS STRING) AS owner
    -- add more tracked fields here, all CAST to STRING
  FROM `{{project}}.{{crm_dataset}}.{{field_history_table}}`
  WHERE {{opportunity_id_col}} = @opp_id
),
long AS (
  SELECT opportunity_id, batch_date, field, value
  FROM snap
  UNPIVOT INCLUDE NULLS (value FOR field IN (stage, amount, close_date, owner))
),
chg AS (
  SELECT
    batch_date AS edit_date, field, value AS new_value,
    LAG(value) OVER (PARTITION BY opportunity_id, field ORDER BY batch_date) AS old_value,
    MIN(batch_date) OVER (PARTITION BY opportunity_id) AS first_bd, batch_date AS bd
  FROM long
)
SELECT edit_date, field, old_value, new_value
FROM chg
WHERE bd > first_bd AND old_value IS DISTINCT FROM new_value
ORDER BY edit_date, field
