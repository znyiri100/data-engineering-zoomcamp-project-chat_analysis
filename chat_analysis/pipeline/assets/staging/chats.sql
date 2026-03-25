/* @bruin

name: chat_analysis_2026_dataset.staging_chats
type: bq.sql

depends:
  - chat_analysis_2026_dataset.ingestion_chats
  - chat_analysis_2026_dataset.ingestion_topic_lookup

materialization:
  type: table
  strategy: time_interval
  incremental_key: created_at
  time_granularity: date
  partition_by: DATE(created_at)
  cluster_by:
    - "`user`"
    - topic

columns:
  - name: id
    type: integer
    description: Primary key for the chat message
    primary_key: true
    nullable: false
    checks:
      - name: not_null
  - name: created_at
    type: timestamp
    description: Creation date/time

@bruin */

SELECT 
    c.id,
    c.`user`,
    l.topic,
    c.created_at,
    c.attempt,
    c.response,
    c.user_message
FROM chat_analysis_2026_dataset.ingestion_chats c
LEFT JOIN chat_analysis_2026_dataset.ingestion_topic_lookup l ON c.topic_id = l.topic_id
WHERE c.created_at >= '{{ start_datetime }}'
  AND c.created_at < '{{ end_datetime }}'
  AND (l.topic IN UNNEST(['{{ var.chat_types | join("','") }}']) OR {{ var.chat_types | length }} = 0)
