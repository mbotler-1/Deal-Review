-- TEMPLATE. Replace {{placeholders}} from config.yaml. BigQuery dialect.
-- Activity timeline. In many CRMs activities attach to the ACCOUNT, not the opp, so pull by
-- account within the deal window PLUS anything explicitly linked to the opp. Adjust the link
-- column ({{activity_link_col}}) and window params to your data.
-- Params: @account_id, @opp_id, @win_start (YYYY-MM-DD), @win_end (YYYY-MM-DD)
SELECT
  {{activity_date_col}}    AS date,
  {{activity_subject_col}} AS subject
  -- add: type, owner, description, contact, and an is_call flag if your data has one
FROM `{{project}}.{{crm_dataset}}.{{activities_table}}`
WHERE ( {{activity_link_col}} = @account_id OR {{activity_link_col}} = @opp_id )
  AND {{activity_date_col}} BETWEEN DATE(@win_start) AND DATE(@win_end)
ORDER BY {{activity_date_col}} ASC
