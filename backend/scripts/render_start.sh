#!/usr/bin/env bash
set -e

# If GCP service account JSON is provided via the GCP_SA_JSON env var, write it to a file
if [ -n "${GCP_SA_JSON:-}" ]; then
  echo "Writing GCP service account JSON to /tmp/gcp_sa.json"
  printf '%s' "$GCP_SA_JSON" > /tmp/gcp_sa.json
  export GOOGLE_APPLICATION_CREDENTIALS="/tmp/gcp_sa.json"
fi

echo "Starting CareVibe backend: node src/server.js"
exec node src/server.js
