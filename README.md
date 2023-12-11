# Backup and Sync Script

This script is a custom solution developed due to limitations encountered with rclone in handling FTPS connections. Unlike rclone, which excels with a variety of cloud storage and network file transfer protocols, this script is specifically optimized for FTPS (File Transfer Protocol Secure) and not for SFTP (SSH File Transfer Protocol). It automates the process of downloading files from an FTPS server and syncing them to Backblaze B2 cloud storage, and provides optional Slack notifications for operational updates and error alerts.

## Features

- **FTPS Download**: Securely download files from an FTPS server.
- **Backblaze B2 Sync**: Synchronize downloaded files to Backblaze B2 storage.
- **Slack Notifications**: Send notifications to a Slack channel for successful operations or errors.
- **Configurable Options**: Options to enable or disable Slack notifications and Backblaze B2 sync.
- **Logging**: Detailed logging of operations and errors.

## Prerequisites

- `lftp`: For FTPS downloads.
- `curl`: For sending Slack notifications.
- `b2`: For syncing files to Backblaze B2.

## Configuration

Before running the script, configure the following variables in the script:

- FTPS server details: `HOST`, `USER`, `PASS`, `REMOTE_DIR`
- Local directory for file storage: `LOCAL_DIR`
- Backblaze B2 details: `B2_BUCKET`, `B2_THREADS`
- Slack webhook URL: `SLACK_WEBHOOK_URL`

## Usage

Run the script with optional flags:

- `--no-slack`: Disable Slack notifications.
- `--no-b2`: Disable syncing to Backblaze B2.

Example:

```bash
./backup_sync_script.sh --no-slack
```

## Error Handling

If any critical operation fails, such as FTPS download or B2 sync, the script will log the error, send a Slack notification (if enabled), and terminate.

## Logging

Logs are stored in `script_log.log`, detailing each operation and timestamp.

## Last Run Time Tracking

The script tracks the last successful run time to optimize subsequent downloads. This information is stored in `last_run_time.txt`.

## Security Note

Please ensure that sensitive information such as FTPS credentials and Slack webhook URLs are securely stored and have limited access.
