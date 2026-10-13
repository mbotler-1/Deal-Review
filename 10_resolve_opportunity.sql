-- TEMPLATE. Replace {{placeholders}} from config.yaml (schema_map). BigQuery dialect.
-- Resolve an opportunity by NAME (fragment, case-insensitive) or exact ID.
-- If >1 row returns, the caller asks the user to pick an id.
-- Param: @opp_query  (a name fragment, or an id)
SELECT
  {{opportunity_id_col}}   AS opportunity_id,
  {{opportunity_name_col}} AS opportunity_name,
  {{account_name_col}}     AS account_name,
  {{account_id_col}}       AS account_id,
  {{amount_col}}           AS amount,
  {{stage_col}}            AS stage,
  {{close_date_col}}       AS close_date,
  {{created_date_col}}     AS created_date,
  {{owner_col}}            AS owner
FROM `{{project}}.{{crm_dataset}}.{{opportunities_table}}`
WHERE {{opportunity_id_col}} = @opp_query
   OR LOWER({{opportunity_name_col}}) LIKE LOWER(CONCAT('%', @opp_query, '%'))
ORDER BY {{created_date_col}} DESC
