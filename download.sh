#!/usr/bin/env bash

bold=$(tput bold)
normal=$(tput sgr0)
accent=$(tput setaf 99)
secondary_accent=$(tput setaf 12)

DOWNLOAD_FOLDER=$1
if [[ ! "$DOWNLOAD_FOLDER" ]]; then
  SCRIPT=$(basename "$0")
  printf "\n ** Please provide the folder we're downloading your backup files into. The folder must exist and be empty.\n"
  printf "\n Example: ${SCRIPT} /path/to/folder\n\n"
  exit 1
fi

if [[ ! -d "$DOWNLOAD_FOLDER" ]]; then
  printf "\n ** The folder ${DOWNLOAD_FOLDER} does not exist. Please create.\n\n"
  exit 1
fi

if [ "$(ls -A $DOWNLOAD_FOLDER)" ]; then
  printf "\n ** The folder ${DOWNLOAD_FOLDER} is not empty.\n\n"
  exit 1
fi

DOWNLOAD_FOLDER_AVAILABLE=$(BLOCKSIZE=1024 df ${DOWNLOAD_FOLDER} | tail -1 | awk '{print $4}')
DOWNLOAD_FOLDER_AVAILABLE=$((DOWNLOAD_FOLDER_AVAILABLE*1024))

printf "${bold}Computing bucket size...${normal}\n\n"


CLOUD_SERVICE_NAME="AWS S3"
NOW=$(date +%s)

BUCKET_URI="s3://${BORG_S3_BACKUP_BUCKET}"
BUCKET_SIZE=`aws s3 ls --summarize --recursive ${BUCKET_URI} | tail -1 | awk '{print \$3}'`
DOWNLOAD_COMMAND="aws s3 sync ${BUCKET_URI} ${DOWNLOAD_FOLDER}"

BUCKET_SIZE_GB=`numfmt --to iec --format "%8.4f" ${BUCKET_SIZE}`
DOWNLOAD_FOLDER_AVAILABLE_GB=`numfmt --to iec --format "%8.4f" ${DOWNLOAD_FOLDER_AVAILABLE}`

echo "${bold}Cloud service:${normal} ${accent}${CLOUD_SERVICE_NAME}${normal}"
echo "${bold}Bucket size:${normal} ${accent}${BUCKET_SIZE_GB}${normal}"
echo "${bold}Available space at ${secondary_accent}${DOWNLOAD_FOLDER}:${normal} ${accent}${DOWNLOAD_FOLDER_AVAILABLE_GB}${normal}"

if (( $BUCKET_SIZE > $DOWNLOAD_FOLDER_AVAILABLE )); then
  printf "\n ** There is not enough space to download your backup at ${secondary_accent}${DOWNLOAD_FOLDER}${normal}\n"

  exit 1
fi

printf "\n${bold}Starting download: ${secondary_accent}${BUCKET_URI} ${accent}--> ${secondary_accent}${DOWNLOAD_FOLDER}${normal}\n\n"

$DOWNLOAD_COMMAND

printf "\n\n${bold}Backup download success.\nSummary${normal}:\n\n"
echo "${bold}Cloud service:${normal} ${accent}${CLOUD_SERVICE_NAME}${normal}"
echo "${bold}Bucket size:${normal} ${accent}${BUCKET_SIZE_GB}${normal}"

echo "Running borg validation"
borg check $DOWNLOAD_FOLDER

printf "\n\n${bold}Before you can use it with borg, you need to move ${secondary_accent}${DOWNLOAD_FOLDER} ${normal}${bold}to ${secondary_accent}${BORG_REPO}${normal}\n\n"