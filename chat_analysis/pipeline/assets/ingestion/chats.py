"""@bruin
name: ingestion.chats
type: python
image: python:3.11
connection: duckdb-default
materialization:
  type: table
  strategy: append

# depends:
#   - ingestion.topic_lookup

columns:
  - name: user
    type: string
    description: User identifier
  - name: topic_id
    type: integer
    description: Unique identifier for the topic
  - name: id
    type: integer
    description: Chat message id
  - name: created_at
    type: timestamp
    description: Message creation timestamp
  - name: attempt
    type: integer
    description: Attempt/order number in a conversation
  - name: response
    type: string
    description: Assistant response text
  - name: user_message
    type: string
    description: User input text
  - name: extracted_at
    type: timestamp
    description: UTC extraction timestamp

@bruin"""

import os
from pathlib import Path

import pandas as pd


def materialize():
    start_date = os.environ["BRUIN_START_DATE"]
    end_date = os.environ["BRUIN_END_DATE"]
    run_start = pd.to_datetime(start_date, utc=True)
    run_end = pd.to_datetime(end_date, utc=True)

    data_root = Path(os.getenv("CHAT_DATA_DIR", Path(__file__).resolve().parents[4] / "data"))
    month_end = (run_end - pd.Timedelta(seconds=1)).to_period("M")
    month_starts = pd.period_range(start=run_start.to_period("M"), end=month_end, freq="M")

    frames = []
    for month in month_starts:
        month_file = data_root / f"{month}.csv"
        if month_file.exists():
            frame = pd.read_csv(month_file, parse_dates=["createdAt"])
            frame["createdAt"] = pd.to_datetime(frame["createdAt"], utc=True, errors="coerce")
            frames.append(frame)

    if frames:
        df = pd.concat(frames, ignore_index=True, copy=False)
        df = df[(df["createdAt"] >= run_start) & (df["createdAt"] < run_end)]
    else:
        df = pd.DataFrame(columns=["user", "topic_id", "id", "createdAt", "attempt", "response", "userMessage"])

    df["extracted_at"] = pd.Timestamp.now(tz="UTC")
    return df
