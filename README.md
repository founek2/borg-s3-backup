# Borg S3 storage backup

This is a script to backup your folders using borg into a local borg repository which is synced into an AWS S3  bucket.

Commands:
```
# Initialize repository
borg init --encryption=repokey-blake2 repository

# run backup
./run_backup.sh

# recovery 
./run_download.sh /home/martas/backup/repository/

borg list repository::work-2023-06-04T00.31 var/deploy
borg extract repository::work-2023-06-04T00.31 var/deploy /var/deploy
```

## Features
- support for Mac notifications via [terminal-notifier](https://github.com/julienXX/terminal-notifier)
- support for Linux notifications via notify-send
