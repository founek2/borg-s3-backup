#!/usr/bin/env bash
set -e

BACKUP_VERSION=$(date +%Y-%m-%dT%H.%M)

# TODO clone repository from S3 and upload it back after backup

if [[ ! "$BORG_REPO" ]]; then
  printf "\n ** Please provide with BORG_REPO on the environment\n"
  exit 1
fi

if [[ ! "$BORG_S3_BACKUP_BUCKET" ]]; then
  printf "\n ** Please provide with BORG_S3_BACKUP_BUCKET on the environment\n"
  exit 1
fi

SYNC_COMMAND="aws s3 sync ${BORG_REPO} s3://${BORG_S3_BACKUP_BUCKET} --profile=${BORG_S3_BACKUP_AWS_PROFILE} --delete"


EXCLUDES_FILE=$(dirname $0)/excludes.lst
if [ ! -f "${EXCLUDES_FILE}" ]; then
	printf "\n ** Please create an excludes file (even if empty) at '${EXCLUDES_FILE}'.\n"
	exit 1
fi

# Local borg backup
borg create ${BORG_REPO}::work-${BACKUP_VERSION} \
	/var/data /var/deploy /etc/fstab \
	-v \
	--progress \
	--stats \
	--exclude-caches \
	--exclude-from ${EXCLUDES_FILE} \
	--compression zlib,6

# Define and store the backup's exit status
OPERATION_STATUS=$?


if [ $OPERATION_STATUS == 0 ]; then
	# Clean up old backups: keep 7 end of day and 4 additional end of week archives.
	# Prune operation is not important, s3 sync is - do not exit were this to fail
	borg prune -v --list --keep-daily=7 --keep-weekly=4
	borg compact

	# Sync borg repo to s3
	printf "\n\n ** Syncing to AWS bucket ${BORG_S3_BACKUP_BUCKET}...\n"
	borg with-lock ${BORG_REPO} ${SYNC_COMMAND}

	# We do care about s3 sync succeeding though
	OPERATION_STATUS=$?
fi

if [ $OPERATION_STATUS == 0 ]; then
	STATUS_MESSAGE="Backup successful"
else
	STATUS_MESSAGE="Backup failed because reasons - see output"
fi

if hash notify-send 2>/dev/null; then
	if [ $OPERATION_STATUS == 0 ]; then
		notify-send -t 0 "Home folder backup" "${STATUS_MESSAGE}" --urgency=normal --icon=dialog-information
	else
		notify-send -t 0 "Home folder backup" "${STATUS_MESSAGE}" --urgency=critical --icon=dialog-error
	fi
fi

if hash terminal-notifier 2>/dev/null; then
	if [ $OPERATION_STATUS == 0 ]; then
		terminal-notifier -message Finished  -title "Borg backup"  -sound default
	else
		terminal-notifier -message Failed  -title "Borg backup"  -sound default
	fi
fi
printf "\n ** ${STATUS_MESSAGE}\n"
exit ${OPERATION_STATUS}
