SINIC_BACKUP_PATH="/home/sinic/BACKUP/"
GitLab_BACKUP_PATH="/var/opt/gitlab/backups/*"
YouTrack_BACKUP_PATH="/home/youtrack/teamsysdata-backup/*"

rm -rf $SINIC_BACKUP_PATH"*"
#Backup gitlab and put it into /var/opt/gitlab/backups/
#must run as root or with sudo 
gitlab-rake gitlab:backup:create
mv $GitLab_BACKUP_PATH $SINIC_BACKUP_PATH
mv $YouTrack_BACKUP_PATH $SINIC_BACKUP_PATH
chown -R sinic:sinic $SINIC_BACKUP_PATH