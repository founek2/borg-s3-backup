#!/usr/bin/env bash
set -e

if [[ ! "$BORG_REPO" ]]; then
  printf "\n ** Please provide with BORG_REPO on the environment\n"
  exit 1
fi

$MOUNT_PATH=$1

borg mount $BORG_REPO $MOUNT_PATH

$LATEST_ARCHIVE=$(ls -Art $MOUNT_PATH | tail -n 1)

FOLDERS="var/deploy
var/data"

for FOLDER in $FOLDERS; do
  DIRECTORY="$MOUNT_PATH/$LATEST_ARCHIVE/$FOLDER"
  if [ -d "$FOLDER" ]; then
    rsync -a --delete "$DIRECTORY/" "/$FOLDER/"
  else
    echo "Warning: $FOLDER does not exist on the system, skipping restore for this folder."
  fi
done

umount $MOUNT_PATH