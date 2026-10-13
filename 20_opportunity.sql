-- TEMPLATE. Replace {{placeholders}} from config.yaml. BigQuery dialect.
-- Full current-state opportunity record. Add any custom fields your review uses
-- (demo booked by, product, lead source detail, loss reason, etc.).
-- Param: @opp_id
SELECT
  {{opportunity_id_col}}   AS opportunity_id,
  {{opportunity_name_col}} AS opportunity_name,
  {{account_name_col}}     AS account_name,
  {{account_id_col}}       AS account_id,
  {{amount_col}}           AS amount,
  {{stage_col}}            AS stage,
  {{close_date_col}}       AS close_date,
  {{created_date_col}}     AS created_date,
  {{owner_col}}            AS owner,
  {{lead_source_col}}      AS lead_source,
  {{loss_reason_col}}      AS loss_reason
FROM `{{project}}.{{crm_dataset}}.{{opportunities_table}}`
WHERE {{opportunity_id_col}} = @opp_id
