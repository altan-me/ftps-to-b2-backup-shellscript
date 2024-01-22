#!/bin/bash
set -e

# Set default file creation mask
umask 022

# -----------------------
# Parse Options
# eg --no-slack --no-b2
# -----------------------
USE_SLACK=1
USE_B2=1

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-slack) USE_SLACK=0 ;;
        --no-b2) USE_B2=0 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# -----------------------
# Dependency Checks
# -----------------------
command -v lftp >/dev/null 2>&1 || { echo >&2 "lftp is not installed. Aborting."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is not installed. Aborting."; exit 1; }
if ! command -v b2 >/dev/null 2>&1; then
    if ! command -v backblaze-b2 >/dev/null 2>&1; then
        echo >&2 "Neither b2 nor backblaze-b2 is installed. Aborting."
        exit 1
    fi
fi

# -----------------------
# Configuration
# -----------------------
# FTPS and Backblaze B2 Details
HOST='ftps.example.com'  # Replace with your FTPS server address
USER='username'         # FTPS username
PASS='password'         # FTPS password
REMOTE_DIR='/'          # Remote directory to download from
PARALLEL_CON=5         # Number of parallel ftps connections (change this to a lower value if you find files are skipped)
LOCAL_DIR='/data/recordings' # Local directory to save files
B2_BUCKET='b2_bucket_name'   # B2 bucket name
B2_THREADS=10                # B2 Threads (1-99)

# Slack Webhook URL
SLACK_WEBHOOK_URL='https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX' # Webhook URL

# Last run time file
LAST_RUN_FILE="last_run_time.txt"

# Logging file
LOG_FILE="script_log.log"

# Start Script duration tracking
duration_start=$(date +%s)

# -----------------------
# Functions
# -----------------------
log() {
    echo "[$(date)] $1" >> $LOG_FILE
}

send_slack_notification() {
    if [ $USE_SLACK -eq 1 ]; then
        local message=$1
        local color=${2:-"#FF0000"} # Default to red color for errors
        curl -X POST --data-urlencode "payload={\"attachments\": [{\"color\": \"$color\", \"text\": \"$message\"}]}" $SLACK_WEBHOOK_URL
    fi
}

# -----------------------
# Main Script
# -----------------------
log "Script started"

# Format for last run time (YearMonthDay)
TIME_FORMAT="%Y%m%d"

# Check if last run time file exists
if [ -f "$LAST_RUN_FILE" ]; then
    LAST_RUN_TIME=$(cat $LAST_RUN_FILE)
else
    LAST_RUN_TIME="19700101"
fi

# FTPS download with explicit TLS
if ! lftp -e "set ftp:ssl-force true; set ftp:ssl-protect-data true; mirror --verbose --parallel=$PARALLEL_CON --newer-than=$LAST_RUN_TIME --depth-first $REMOTE_DIR $LOCAL_DIR; quit" -u $USER,$PASS $HOST; then
    log "FTPS download failed"
    send_slack_notification "FTPS download failed"
    exit 1
fi

# After the lftp command, ensure user can write to folders
if [ -d "$LOCAL_DIR" ]; then
    chmod -R u+w "$LOCAL_DIR"
fi

log "FTPS download completed"
date +$TIME_FORMAT > $LAST_RUN_FILE

# Sync to Backblaze B2
if [ $USE_B2 -eq 1 ]; then
    # Sync to Backblaze B2
    if ! backblaze-b2 sync --threads $B2_THREADS --replaceNewer $LOCAL_DIR b2://$B2_BUCKET; then
        log "Backblaze B2 sync failed"
        send_slack_notification "Backblaze B2 sync failed"
        exit 1
    fi
fi

# Deleting files and folders in the local directory
log "Deleting all files and folders in $LOCAL_DIR..."
rm -rf "$LOCAL_DIR"/*

log "Local dir cleanup complete."

# End time and duration calculation
duration_end=$(date +%s)
run_duration=$((duration_end - duration_start))

success_message="Recording Download and sync to B2 completed successfully at $(date) and took $(run_duration) seconds"
log "$success_message"
send_slack_notification "$success_message" "#36A64F" # Green color for success

log "Script completed"
