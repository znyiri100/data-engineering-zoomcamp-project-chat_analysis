"""@bruin
name: upload_to_gcs
type: python
connection: bigquery-default
secrets:
  - key: GCS_BUCKET
  - key: PROJECT_ID
  - key: bigquery-default
    inject_as: GCS_CONNECTION
@bruin"""

import os
import sys
import json
import requests
from google.cloud import storage
from google.oauth2 import service_account

# CSV files to download (monthly chat data + lookup table)
FILES = [
    "2025-05.csv",
    "2025-07.csv",
    "2025-08.csv",
    "2025-09.csv",
    "2025-10.csv",
    "2025-11.csv",
    "2025-12.csv",
    "2026-01.csv",
    "2026-02.csv",
    "topic_lookup.csv",
]

GITHUB_RAW = "https://raw.githubusercontent.com/znyiri100/data-engineering-zoomcamp-project-chat_analysis/main/data"

def _get_storage_client(project_id: str | None):
    """
    Create a GCS client using Bruin-injected connection JSON when available.
    Falls back to local credentials / ADC for local development.
    """
    conn_json = os.environ.get("GCS_CONNECTION")
    if conn_json:
        try:
            conn = json.loads(conn_json)
            sa_json = conn.get("service_account_json", "")
            if sa_json:
                credentials = service_account.Credentials.from_service_account_info(json.loads(sa_json))
                return storage.Client(credentials=credentials, project=project_id or conn.get("project_id"))
        except Exception as exc:
            print(f"Warning: Failed to parse GCS_CONNECTION, falling back to ADC. Details: {exc}")

    return storage.Client(project=project_id)

def main():
    bucket_name = os.environ.get("GCS_BUCKET")
    project_id = os.environ.get("PROJECT_ID")
    force = os.environ.get("BRUIN_FULL_REFRESH") == "1"

    # For local development: try to use the .credentials.json if it exists and GOOGLE_APPLICATION_CREDENTIALS is not set
    if not os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        # Look for .credentials.json in the project root (4 levels up from this file)
        root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
        creds_path = os.path.join(root_dir, ".credentials.json")
        if os.path.exists(creds_path):
            print(f"  ↳ Using local credentials: {creds_path}")
            os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = creds_path

    if not bucket_name:
        print("Error: GCS_BUCKET environment variable is not set.")
        sys.exit(1)

    print(f"=== Chat Analysis: GitHub → GCS Upload (Python) ===")
    print(f"  Project:  {project_id}")
    print(f"  Bucket:   gs://{bucket_name}")
    print(f"  Source:   {GITHUB_RAW}\n")

    try:
        storage_client = _get_storage_client(project_id)
        bucket = storage_client.bucket(bucket_name)
        
        # Verify bucket access
        if not bucket.exists():
            print(f"Error: Bucket gs://{bucket_name} does not exist. Please create it first.")
            sys.exit(1)
        print("  ✓ Bucket exists\n")

        print("Downloading from GitHub and uploading to GCS...")
        for filename in FILES:
            print(f"  {filename} ...")
            gcs_path = f"data/{filename}"
            blob = bucket.blob(gcs_path)

            if not force and blob.exists():
                print(f"    ↳ File already exists. Skipping... (use full-refresh to overwrite)")
                # break in original script, but probably better to check all
                continue

            # Download from GitHub
            resp = requests.get(f"{GITHUB_RAW}/{filename}")
            resp.raise_for_status()
            
            # Upload to GCS
            blob.upload_from_string(resp.content)
            print("    ↳ Uploaded successfully")

        print("\n=== Upload complete ===")

    except Exception as e:
        print(f"Error during upload: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
