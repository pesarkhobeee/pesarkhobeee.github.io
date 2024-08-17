#!/bin/bash

#Backup transfer from server to local computer
#Remember: you must add your ssh public key in server ssh's authorized_keys
SINIC_BACKUP_PATH="/home/sinic/BACKUP/"
LOCAL_BACKUP_PATH="/home/sinic/work/backup"

#Delete all files that older than one week
find $LOCAL_BACKUP_PATH  -cmin +10080  -exec /bin/rm -rf "{}" \;

rsync -aP sinic@192.168.112.2:$SINIC_BACKUP_PATH $LOCAL_BACKUP_PATH