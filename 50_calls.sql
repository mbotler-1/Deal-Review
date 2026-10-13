-- TEMPLATE (optional). Replace {{placeholders}} from config.yaml. BigQuery dialect.
-- Call transcripts / AI briefs, joined by account (or opp) within the deal window.
-- If your call metadata/transcript live in nested JSON, extract with JSON_VALUE / JSON_QUERY_ARRAY.
-- Leave calls_dataset blank in config to skip call cards entirely.
-- Params: @account_id, @win_start (YYYY-MM-DD), @win_end (YYYY-MM-DD)
SELECT
  call_date,
  title,
  duration_seconds,
  attendees,      -- name/role list; may need flattening from JSON
  brief           -- AI summary if available; else pull transcript text
FROM `{{project}}.{{calls_dataset}}.{{calls_table}}`
WHERE {{calls_link_col}} = @account_id
  AND call_date BETWEEN DATE(@win_start) AND DATE(@win_end)
ORDER BY call_date ASC
