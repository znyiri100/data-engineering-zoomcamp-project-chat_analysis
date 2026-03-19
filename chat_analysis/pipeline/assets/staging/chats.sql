/* @bruin

name: staging.chats
type: bq.sql

depends:
  - ingestion.chats
  - ingestion.topic_lookup

materialization:
  type: table
  strategy: time_interval
  incremental_key: created_at
  time_granularity: date

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
FROM ingestion.chats c
LEFT JOIN ingestion.topic_lookup l ON c.topic_id = l.topic_id
WHERE c.created_at >= '{{ start_datetime }}'
  AND c.created_at < '{{ end_datetime }}'
  AND (l.topic IN UNNEST(['{{ var.chat_types | join("','") }}']) OR {{ var.chat_types | length }} = 0)
