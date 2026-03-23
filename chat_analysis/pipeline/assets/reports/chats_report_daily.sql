/* @bruin

name: chat_analysis_dataset.reports_chats_report_daily
type: bq.sql

materialization:
  type: table
  strategy: time_interval
  incremental_key: report_day
  time_granularity: date

depends:
  - chat_analysis_dataset.staging_chats

columns:
  - name: "`user`"
    type: VARCHAR
    description: Unique user identifier
    primary_key: true
  - name: topic
    type: VARCHAR
    description: The conversation topic
    primary_key: true
  - name: report_day
    type: DATE
    description: The date the messages were sent
    primary_key: true
  - name: message_count
    type: BIGINT
    description: Total number of messages sent by the user on this date
    checks:
      - name: non_negative

@bruin */

SELECT 
    FORMAT_DATE('%Y-%m-%d', CAST(created_at AS DATE)) AS report_day,
    `user`,
    topic,
    COUNT(*) AS message_count
FROM chat_analysis_dataset.staging_chats
WHERE created_at >= '{{ start_datetime }}'
  AND created_at < '{{ end_datetime }}'
GROUP BY 1, 2, 3
