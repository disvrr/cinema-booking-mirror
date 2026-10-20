#!/usr/bin/env bash
set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/pg_backups"
FILE_NAME="cinema_backup_${TIMESTAMP}.sql.gz"
S3_BUCKET="s3://demo2-postgres-backups/backups"

mkdir -p "$BACKUP_DIR"

# Data base backup using pg_dump and gzip compression
PGPASSWORD="cinema_password" pg_dump -h localhost -U cinema_user -d cinema | gzip > "${BACKUP_DIR}/${FILE_NAME}"

# Upload to S3 using EC2 IAM Role
aws s3 cp "${BACKUP_DIR}/${FILE_NAME}" "${S3_BUCKET}/${FILE_NAME}"

# Cleanup
rm -f "${BACKUP_DIR}/${FILE_NAME}"