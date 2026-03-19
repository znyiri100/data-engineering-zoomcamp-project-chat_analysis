#!/usr/bin/env bash
# Download chat analysis CSV data from GitHub and upload to GCS
# Usage: ./upload_to_gcs.sh [BUCKET_NAME]
#
# Prerequisites:
#   - gcloud CLI installed and authenticated (gcloud auth login)
#   - wget installed

set -euo pipefail

BUCKET_NAME="${1:-chat-analysis-data-kestra-sandbox}"
PROJECT_ID="kestra-sandbox-8656"
REGION="us-central1"
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

# Create bucket if it doesn't exist
if ! gcloud storage buckets describe "gs://$BUCKET_NAME" --project="$PROJECT_ID" &>/dev/null; then
    echo "Creating bucket gs://$BUCKET_NAME ..."
    gcloud storage buckets create "gs://$BUCKET_NAME" \
        --project="$PROJECT_ID" \
        --location="$REGION" \
        --uniform-bucket-level-access
    echo "  ✓ Bucket created"
else
    echo "  ✓ Bucket already exists"
fi

# Download from GitHub and upload to GCS
echo ""
echo "Downloading from GitHub and uploading to GCS..."
for filename in "${FILES[@]}"; do
    echo "  $filename ..."
    wget -q -O "$TMP_DIR/$filename" "$GITHUB_RAW/$filename"
    gcloud storage cp "$TMP_DIR/$filename" "gs://$BUCKET_NAME/data/$filename"
done

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "=== Upload complete ==="
echo "Verify: gcloud storage ls gs://$BUCKET_NAME/data/"
