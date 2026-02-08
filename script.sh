#!/usr/bin/env bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin/

SCRIPT_DIR=$(dirname "$0")

BACKUP_VERSION=$(date +%Y-%m-%dT%H.%M)
${SCRIPT_DIR}/script_backup.sh $BACKUP_VERSION

OPERATION_STATUS=$?

if [ $OPERATION_STATUS == 0 ]; then
	${SCRIPT_DIR}/script_sync.sh
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
