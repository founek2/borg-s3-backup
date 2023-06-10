# Borg S3 storage backup

This is a script to backup your folders using borg into a local borg repository which is synced into an AWS S3  bucket.

Commands:
```
borg init --encryption=repokey-blake2 repository
```

## Features
- support for Mac notifications via [terminal-notifier](https://github.com/julienXX/terminal-notifier)
- support for Linux notifications via notify-send

## TODO
- recovery script

