#!/bin/sh

# SET CRON WITH (for example, every friday)
# 0 0 * * 5 /usr/bin/sh /var/www/backup_scripts/backup_script.sh > /var/www/backup_scripts/backup_script.log 2>&1

# CONFIGURATION
    BACKUP_DESTINATION_FOLDER='/var/www/backups/project_dir/'

    BACKUP_DATABASE=true
    MYSQL_USERNAME='user'
    MYSQL_PASSWORD='lorem'
    MYSQL_DATABASE='ipsum'
    DATE=`date +%Y%m%d_%H%M%S`

    BACKUP_SPECIFIC_DIR=false
    DIR_TO_BACKUP='/var/www/html/project_dir'

    REMOVE_OLD_BACKUPS=false
    RETENTION_DAYS='+30'

    REMOTE_BACKUP=false
    REMOTE_BACKUP_FOLDER='remote_folder/'
    REMOTE_ADDRESS='10.20.30.40'
    REMOTE_USERNAME='remoteusername'
#END CONFIGURATION


zipAndMoveFolder() {
  FOLDER=$1
  # ZIP FOLDER
  zip -qr $FOLDER'.zip' $FOLDER
  # MOVE ZIP INTO BACKUP FOLDER
  mv $FOLDER'.zip' $BACKUP_DESTINATION_FOLDER$DATE
}

zipAndMoveDatabase() {
  DATABASE=$1
  # DUMP DATABASE
  mysqldump -u $MYSQL_USERNAME -p$MYSQL_PASSWORD $DATABASE | gzip > $DATABASE'.sql.gz'
  # MOVE GZIP INTO BACKUP FOLDER
  mv $DATABASE'.sql.gz' $BACKUP_DESTINATION_FOLDER$DATE
}

# REMOVE OLD BACKUPS
if [ "$REMOVE_OLD_BACKUPS" = true ]; then
    find $BACKUP_DESTINATION_FOLDER -maxdepth 1 -type d -mtime $RETENTION_DAYS -exec rm -rf {} \;
fi

if [ "$BACKUP_SPECIFIC_DIR" = true ]; then
    mkdir -p $BACKUP_DESTINATION_FOLDER$DATE
    zipAndMoveFolder $DIR_TO_BACKUP
fi

if [ "$BACKUP_DATABASE" = true ]; then
    mkdir -p $BACKUP_DESTINATION_FOLDER$DATE
    zipAndMoveDatabase $MYSQL_DATABASE
fi

if [ "$REMOTE_BACKUP" = true ]; then
    ssh $REMOTE_USERNAME@$REMOTE_ADDRESS "mkdir -p $REMOTE_BACKUP_FOLDER$DATE; find $REMOTE_BACKUP_FOLDER -maxdepth 1 -type d -mtime $RETENTION_DAYS -exec rm -rf {} \;"
    scp -r $BACKUP_DESTINATION_FOLDER$DATE'/'$DATABASE'.sql.gz' $REMOTE_USERNAME@$REMOTE_ADDRESS:$REMOTE_BACKUP_FOLDER$DATE'/'$DATABASE'.sql.gz'
    scp -r $BACKUP_DESTINATION_FOLDER$DATE'/app.zip' $REMOTE_USERNAME@$REMOTE_ADDRESS:$REMOTE_BACKUP_FOLDER$DATE'/app.zip'
fi
