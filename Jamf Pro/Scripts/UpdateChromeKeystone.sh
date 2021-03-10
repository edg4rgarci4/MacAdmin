#!/bin/bash
# Detect console user
console_user=$(/usr/bin/stat -f %Su "/dev/console" 2> /dev/null)
keystone_update="/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle/Contents/Resources/CheckForUpdatesNow.command"
if [[ -n $console_user ]]; then
    su "$console_user" -c "$keystone_update"
else
    exit 1
fi
exit 0
