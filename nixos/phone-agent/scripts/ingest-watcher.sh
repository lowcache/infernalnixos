#!/usr/bin/env bash
set -euo pipefail
INGEST_DIR="${1:?}"
WATCH_DIR="$INGEST_DIR/staged"
PROCESSED_DIR="$INGEST_DIR/processed"
LOG_DIR="$HOME/.local/share/phone-agent"
mkdir -p "$LOG_DIR"
for staged_file in "$WATCH_DIR"/*.json; do
    [ -f "$staged_file" ] || continue
    # Tolerate a malformed file: jq exits 5 on a JSON parse error, which under
    # 'set -e' would wedge the whole run (and trip the path unit's start-limit),
    # blocking every other staged file. Route unparseable files to 'other'.
    TYPE=$(jq -r '.pipeline // "unknown"' "$staged_file" 2>/dev/null || echo unknown)
    case "$TYPE" in
        audio_transcript) TARGET="$PROCESSED_DIR/transcripts" ;;
        image_ocr)        TARGET="$PROCESSED_DIR/ocr" ;;
        share_extract)    TARGET="$PROCESSED_DIR/summaries" ;;
        *)                TARGET="$PROCESSED_DIR/other" ;;
    esac
    mkdir -p "$TARGET"; mv "$staged_file" "$TARGET/"
    echo "$(date -Iseconds) new $TYPE: $(basename "$staged_file")" \
        >> "$LOG_DIR/new_ingest.log"
done
