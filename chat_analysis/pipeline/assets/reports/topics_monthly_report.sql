/* @bruin

name: reports.topics_monthly_report
type: duckdb.sql

materialization:
  type: table
  strategy: time_interval
  incremental_key: report_month
  time_granularity: date

depends:
  - staging.chats

columns:
  - name: report_month
    type: DATE
    description: The month of the report
    primary_key: true
  - name: topic
    type: VARCHAR
    description: The conversation topic
    primary_key: true
  - name: message_count
    type: BIGINT
    description: Total number of messages for the topic in this month
    checks:
      - name: non_negative

@bruin */

SELECT 
    DATE_TRUNC('month', CAST(created_at AS DATE)) AS report_month,
    topic,
    COUNT(*) AS message_count
FROM staging.chats
WHERE created_at >= '{{ start_datetime }}'
  AND created_at < '{{ end_datetime }}'
GROUP BY 1, 2
