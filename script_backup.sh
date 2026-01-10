#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <BACKUP_VERSION>"
    exit 1
fi
BACKUP_VERSION=$1

if [[ ! "$BORG_REPO" ]]; then
  printf "\n ** Please provide with BORG_REPO on the environment\n"
  exit 1
fi

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

if [[ -z "$SKIP_EXPENSIVE_CHECK" ]]; then
	echo "Checking repository integrity..."
	borg check
fi

echo "Prunning and compacting..."
borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=3
borg compact