"""@bruin
name: chat_analysis_2026_dataset.ingestion_chats
type: python
image: python:3.11
connection: bigquery-default

secrets:
  - key: GCS_BUCKET
  - key: bigquery-default
    inject_as: GCP_CREDENTIALS

materialization:
  type: table
  strategy: append

depends:
  - upload_to_gcs

columns:
  - name: user
    type: string
    description: User identifier
    checks:
      - name: not_null
  - name: topic_id
    type: integer
    description: Unique identifier for the topic
  - name: id
    type: integer
    description: Chat message id
    checks:
      - name: not_null
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

import io
import json
import os

import pandas as pd
from google.cloud import storage
from google.oauth2 import service_account


GCS_BUCKET = os.getenv("GCS_BUCKET")


def _get_storage_client():
    """Create a GCS client using Bruin-injected credentials, or fall back to ADC."""
    creds_json = os.environ.get("GCP_CREDENTIALS")
    if creds_json:
        conn = json.loads(creds_json)
        sa_json = conn.get("service_account_json", "")
        if sa_json:
            credentials = service_account.Credentials.from_service_account_info(json.loads(sa_json))
            return storage.Client(credentials=credentials, project=conn.get("project_id"))
    # Fall back to Application Default Credentials (local dev / use_application_default_credentials)
    return storage.Client()


def materialize():
    if not GCS_BUCKET:
        raise ValueError("GCS_BUCKET is not set. Add it as a Bruin secret for this asset/environment.")

    start_date = os.environ["BRUIN_START_DATE"]
    end_date = os.environ["BRUIN_END_DATE"]
    run_start = pd.to_datetime(start_date, utc=True)
    run_end = pd.to_datetime(end_date, utc=True)

    month_end = (run_end - pd.Timedelta(seconds=1)).to_period("M")
    month_starts = pd.period_range(start=run_start.to_period("M"), end=month_end, freq="M")

    client = _get_storage_client()
    bucket = client.bucket(GCS_BUCKET)

    frames = []
    for month in month_starts:
        blob_name = f"data/{month}.csv"
        blob = bucket.blob(blob_name)
        if blob.exists():
            csv_bytes = blob.download_as_bytes()
            frame = pd.read_csv(io.BytesIO(csv_bytes), parse_dates=["createdAt"])
            frame["createdAt"] = pd.to_datetime(frame["createdAt"], utc=True, errors="coerce")
            frames.append(frame)
            print(f"Loaded {blob_name} ({len(frame)} rows)")
        else:
            print(f"Skipping {blob_name} (not found)")

    if frames:
        df = pd.concat(frames, ignore_index=True, copy=False)
        df = df[(df["createdAt"] >= run_start) & (df["createdAt"] < run_end)]
    else:
        df = pd.DataFrame(columns=["user", "topic_id", "id", "createdAt", "attempt", "response", "userMessage"])

    df = df.rename(columns={"createdAt": "created_at", "userMessage": "user_message"})
    df["extracted_at"] = pd.Timestamp.now(tz="UTC")

    print(f"Returning {len(df)} rows for materialization")
    return df
