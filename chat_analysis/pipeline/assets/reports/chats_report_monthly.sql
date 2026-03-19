/* @bruin

name: reports.chats_report_monthly
type: bq.sql

materialization:
  type: table
  strategy: delete+insert
  incremental_key: report_month

depends:
  - staging.chats

columns:
  - name: report_month
    type: STRING
    description: The month of the report in YYYY-MM format
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
    FORMAT_DATE('%Y-%m', CAST(created_at AS DATE)) AS report_month,
    `user`,
    topic,
    COUNT(*) AS message_count
FROM staging.chats
WHERE created_at >= TIMESTAMP_TRUNC(CAST('{{ start_datetime }}' AS TIMESTAMP), MONTH)
  -- AND created_at <  CAST(DATE_ADD(CAST(TIMESTAMP_TRUNC(CAST('{{ start_datetime }}' AS TIMESTAMP), MONTH) AS DATE), INTERVAL 1 MONTH) AS TIMESTAMP)
  AND created_at <  TIMESTAMP_TRUNC(CAST('{{ end_datetime }}' AS TIMESTAMP), MONTH)
GROUP BY 1, 2, 3
