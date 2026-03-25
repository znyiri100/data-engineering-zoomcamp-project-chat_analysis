/* @bruin

name: chat_analysis_2026_dataset.reports_monthly
type: bq.sql

materialization:
  type: table
  strategy: delete+insert
  incremental_key: report_month
  partition_by: DATE_TRUNC(report_month, MONTH)
  cluster_by:
    - "`user`"
    - topic

depends:
  - chat_analysis_2026_dataset.staging_chats

columns:
  - name: report_month
    type: DATE
    description: The month of the report (first day of the month)
    primary_key: true
  - name: "`user`"
    type: STRING
    description: Unique user identifier
    primary_key: true
  - name: topic
    type: STRING
    description: The conversation topic
    primary_key: true
  - name: message_count
    type: BIGINT
    description: Total number of messages for the user and topic in this month
    checks:
      - name: non_negative

@bruin */

SELECT 
    DATE_TRUNC(CAST(created_at AS DATE), MONTH) AS report_month,
    `user`,
    topic,
    COUNT(*) AS message_count
FROM chat_analysis_2026_dataset.staging_chats
WHERE created_at >= TIMESTAMP_TRUNC(CAST('{{ start_datetime }}' AS TIMESTAMP), MONTH)
  -- AND created_at <  CAST(DATE_ADD(CAST(TIMESTAMP_TRUNC(CAST('{{ start_datetime }}' AS TIMESTAMP), MONTH) AS DATE), INTERVAL 1 MONTH) AS TIMESTAMP)
  AND created_at <  TIMESTAMP_TRUNC(CAST('{{ end_datetime }}' AS TIMESTAMP), MONTH)
GROUP BY 1, 2, 3
