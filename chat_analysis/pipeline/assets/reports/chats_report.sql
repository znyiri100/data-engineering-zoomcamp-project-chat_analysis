/* @bruin

name: reports.chats_report
type: bq.sql

materialization:
  type: table
  strategy: time_interval
  incremental_key: created_date
  time_granularity: date

depends:
  - staging.chats

columns:
  - name: "`user`"
    type: VARCHAR
    description: Unique user identifier
    primary_key: true
  - name: topic
    type: VARCHAR
    description: The conversation topic
    primary_key: true
  - name: created_date
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
    `user`,
    topic,
    CAST(created_at AS DATE) AS created_date,
    COUNT(*) AS message_count
FROM staging.chats
WHERE created_at >= '{{ start_datetime }}'
  AND created_at < '{{ end_datetime }}'
GROUP BY 1, 2, 3
