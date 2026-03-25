#!/usr/bin/env bash
# Download chat analysis CSV data from GitHub and upload to GCS
# Usage: ./upload_to_gcs.sh [BUCKET_NAME]
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - wget installed

set -euo pipefail

FORCE=false
BUCKET_NAME="${GCS_BUCKET:-}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--force)
      FORCE=true
      shift
      ;;
    *)
      if [[ "$1" != -* ]]; then
        BUCKET_NAME="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$BUCKET_NAME" ]]; then
    echo "Usage: ./upload_to_gcs.sh [-f|--force] [BUCKET_NAME]"
    echo "Error: BUCKET_NAME is required if GCS_BUCKET is not set."
    exit 1
fi
PROJECT_ID="${PROJECT_ID}"
REGION="US"
GITHUB_RAW="https://raw.githubusercontent.com/znyiri100/data-engineering-zoomcamp-project-chat_analysis/main/data"
TMP_DIR=$(mktemp -d)

# CSV files to download (monthly chat data + lookup table)
FILES=(
    "2025-05.csv"
    "2025-07.csv"
    "2025-08.csv"
    "2025-09.csv"
    "2025-10.csv"
    "2025-11.csv"
    "2025-12.csv"
    "2026-01.csv"
    "2026-02.csv"
    "topic_lookup.csv"
)

echo "=== Chat Analysis: GitHub → GCS Upload ==="
echo "  Project:  $PROJECT_ID"
echo "  Bucket:   gs://$BUCKET_NAME"
echo "  Source:    $GITHUB_RAW"
echo ""

# Check if bucket exists
if ! gcloud storage buckets describe "gs://$BUCKET_NAME" --project="$PROJECT_ID" &>/dev/null; then
    echo "Error: Bucket gs://$BUCKET_NAME does not exist. Please create it first."
    exit 1
else
    echo "  ✓ Bucket exists"
fi

# Download from GitHub and upload to GCS
echo ""
echo "Downloading from GitHub and uploading to GCS..."
for filename in "${FILES[@]}"; do
    echo "  $filename ..."
    if [[ "$FORCE" == "false" ]] && gcloud storage ls "gs://$BUCKET_NAME/data/$filename" &>/dev/null; then
        echo "    ↳ File already exists. Skipping... (use -f or --force to overwrite)"
        # continue
        break   # if file already uploaded, skip the rest of the files
    fi
    wget -q -O "$TMP_DIR/$filename" "$GITHUB_RAW/$filename"
    gcloud storage cp "$TMP_DIR/$filename" "gs://$BUCKET_NAME/data/$filename"
done

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "=== Upload complete ==="
echo "Verify: gcloud storage ls gs://$BUCKET_NAME/data/"
