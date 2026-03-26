/* @bruin

name: chat_analysis_2026_dataset.reports_chats_report_daily
type: bq.sql

materialization:
  type: table
  strategy: time_interval
  incremental_key: report_day
  time_granularity: date
  partition_by: report_day
  cluster_by:
    - "`user`"
    - topic

depends:
  - chat_analysis_2026_dataset.staging_chats

custom_checks:
  - name: unique_user_topic_day
    description: Ensure each user has only one record per topic per day
    query: |
      SELECT count(*)
      FROM (
          SELECT `user`, topic, report_day
          FROM chat_analysis_2026_dataset.reports_chats_report_daily
          GROUP BY 1, 2, 3
          HAVING count(*) > 1
      )
    value: 0

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
    CAST(created_at AS DATE) AS report_day,
    `user`,
    topic,
    COUNT(*) AS message_count
FROM chat_analysis_2026_dataset.staging_chats
WHERE created_at >= '{{ start_datetime }}'
  AND created_at < '{{ end_datetime }}'
GROUP BY 1, 2, 3
