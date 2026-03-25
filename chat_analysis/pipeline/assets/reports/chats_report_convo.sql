/* @bruin

name: chat_analysis_2026_dataset.reports_convo
type: bq.sql

materialization:
  type: table
  strategy: time_interval
  incremental_key: created_at
  time_granularity: date
  partition_by: report_day
  cluster_by:
    - "`user`"
    - topic
    - conversation_id

depends:
  - chat_analysis_2026_dataset.staging_chats

columns:
  - name: report_day
    type: DATE
    description: Message day
  - name: "`user`"
    type: STRING
    description: User identifier
  - name: topic
    type: STRING
    description: Conversation topic
  - name: conversation_id
    type: STRING
    description: Globally unique and stable conversation identifier
  - name: message_index_in_conversation
    type: BIGINT
    description: 1-based order of the message inside the conversation
  - name: chat_id
    type: BIGINT
    description: Original chat row id
    primary_key: true
  - name: created_at
    type: TIMESTAMP
    description: Message timestamp
  - name: attempt
    type: BIGINT
    description: Attempt/order number from source
  - name: user_message
    type: STRING
    description: User input message
  - name: response
    type: STRING
    description: Bot response message

@bruin */

WITH ordered AS (
    SELECT
        id AS chat_id,
        `user`,
        topic,
        created_at,
        attempt,
        user_message,
        response,
        LAG(attempt) OVER (
            PARTITION BY `user`, topic
            ORDER BY created_at, id
        ) AS prev_attempt
    FROM chat_analysis_2026_dataset.staging_chats
    WHERE created_at < '{{ end_datetime }}'
),
conversation_flags AS (
    SELECT
        *,
        CASE
            WHEN prev_attempt IS NULL THEN 1
            WHEN attempt IS NULL THEN 1
            WHEN attempt <= prev_attempt THEN 1
            ELSE 0
        END AS is_new_conversation
    FROM ordered
),
conversationized AS (
    SELECT
        *,
        SUM(is_new_conversation) OVER (
            PARTITION BY `user`, topic
            ORDER BY created_at, chat_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS conversation_id_local
    FROM conversation_flags
),
finalized AS (
    SELECT
        CAST(created_at AS DATE) AS report_day,
        `user`,
        topic,
        TO_JSON_STRING(STRUCT(
            `user` AS `user`,
            topic AS topic,
            conversation_id_local AS conversation_seq
        )) AS conversation_id,
        ROW_NUMBER() OVER (
            PARTITION BY `user`, topic, conversation_id_local
            ORDER BY created_at, chat_id
        ) AS message_index_in_conversation,
        chat_id,
        created_at,
        attempt,
        user_message,
        response
    FROM conversationized
)
SELECT
    report_day,
    `user`,
    topic,
    conversation_id,
    message_index_in_conversation,
    chat_id,
    created_at,
    attempt,
    user_message,
    response
FROM finalized
WHERE created_at >= '{{ start_datetime }}'
  AND created_at < '{{ end_datetime }}'
