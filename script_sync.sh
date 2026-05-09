#!/usr/bin/env bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin/
set -e

if [[ ! "$BORG_S3_BACKUP_BUCKET" ]]; then
  printf "\n ** Please provide with BORG_S3_BACKUP_BUCKET on the environment\n"
  exit 1
fi

# Clean up old backups: keep 7 end of day and 4 additional end of week archives.
# Prune operation is not important, s3 sync is - do not exit were this to fail
echo "Validating repository integrity and compacting..."

if [[ -z "$SKIP_EXPENSIVE_CHECK" ]]; then
	echo "Checking repository integrity..."
	borg check $BORG_REPO
fi

echo "Prunning and compacting..."
borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=3
borg compact

SYNC_COMMAND="aws s3 sync ${BORG_REPO} s3://${BORG_S3_BACKUP_BUCKET} --delete --exclude 'lock.exclusive/*'"

# Sync borg repo to s3
printf "\n\n ** Syncing to AWS bucket ${BORG_S3_BACKUP_BUCKET}...\n"
borg with-lock ${BORG_REPO} ${SYNC_COMMAND}
