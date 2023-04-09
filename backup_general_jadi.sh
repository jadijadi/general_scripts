#!/bin/bash

#
# Key things to remember, no spaces in pathnames, and try to use full paths (beginning with / )
#
# now fill in these few variables for me
# change to use

# FTP username and Pass

# this is a list of directories you want backed up. No trailing / needed.
INCLUDES="/home/user/public_html /etc/ /home/user/logs"

# I added a mysql user called backup with permissions to SELECT and LOCKING only for this backup
# CREATE USER backup@'localhost' IDENTIFIED BY 'backuppassword';
# GRANT SELECT,LOCKING ON *.* TO backup@'localhost'  WITH GRANT OPTION;
#
# change this variable to anything but 1 to disable mysql backups ( some prefer to backup the binlog )
MYSQLBACKUP=1
MYSQLDBUSER=root
MYSQLDBPASS=rootpassword


PSTGRBACKUP=0
PSTGRDBUSER=postgres
PSTGRDBPASS=backuppassword

DRUSHBACKUP=0
DRUPALROOT=/home/html/www/mydrupalsite/

# this stuff is probably not needs to be changed
TMPDIR=/tmp/backup
DAYOFWEEK=`date +%a`
DATESTAMP=`date +%d%m%y`
cd /
# remove all older files
rm -rf ${TMPDIR}/* # dangerous... needs testing! 

# create directory structure
/bin/mkdir -p ${TMPDIR}/files &&
/bin/mkdir -p ${TMPDIR}/db &&
/bin/mkdir -p ${TMPDIR}/archives &&

if [ $MYSQLBACKUP = 1 ];then
nice /usr/bin/mysqldump -u${MYSQLDBUSER} -p${MYSQLDBPASS} -A | gzip -c > ${TMPDIR}/db/${HOSTNAME}_mysql_backup-${DATESTAMP}-${DAYOFWEEK}.sql.gz
fi

# PSQL backups
if [ $PSTGRBACKUP = 1 ];then
nice /usr/bin/pg_dumpall -U${PSTGRDBUSER} | gzip -c > ${TMPDIR}/db/${HOSTNAME}_psql_backup-${DATESTAMP}-${DAYOFWEEK}.psql.gz
fi

# Drush
if [ $DRUSHBACKUP = 1 ];then
    drush  --root=$DRUPALROOT --destination=${TMPDIR}/drupal/${HOSTNAME}_drush-${DATESTAMP}-${DAYOFWEEK}.tar.gz ard
fi



for ITEMI in ${INCLUDES} ; do
/bin/mkdir -p ${TMPDIR}/files/${ITEMI}/
/usr/bin/rsync -aq ${ITEMI}/* ${TMPDIR}/files/${ITEMI}/
done

nice /bin/tar jcf ${TMPDIR}/archives/${HOSTNAME}_file-backup-${DATESTAMP}-${DAYOFWEEK}.tar.bz2 ${TMPDIR}/files/ ${TMPDIR}/db/ > /tmp/backup.log 2>&1 && mv ${TMPDIR}/archives/${HOSTNAME}_file-backup-${DATESTAMP}-${DAYOFWEEK}.tar.bz2 /home/user/Dropbox/backups/

#/usr/bin/lftp -u "${FTPUSER},${FTPPASS}" $FTPADDR -e "put ${TMPDIR}/archives/${HOSTNAME}_file-backup-${DATESTAMP}-${DAYOFWEEK}.tar.bz2; put ${TMPDIR}/db/${HOSTNAME}_psql_backup-${DATESTAMP}-${DAYOFWEEK}.psql.gz ; exit" >/dev/null

# remove all older files
#rm -rf ${TMPDIR}/*c

mv ${TMPDIR}/archives/${HOSTNAME}_file-backup-${DATESTAMP}-${DAYOFWEEK}.tar.bz2 /home/user/Dropbox/backups/
