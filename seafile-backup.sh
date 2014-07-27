#!/bin/bash
###############################
# Seafile server backup script (cold sqlite backup)
# Author: Nils Kuhnert
# Last change: 2014-07-27
# Website: 3c7.me
###############################

# Variables
DATE=`date +%F`
TIME=`date +%H%M`
BACKUPDIR=/backup
SEAFDIR=/home/sea
BACKUPFILE=$BACKUPDIR/seafile-$DATE-$TIME.tar
TEMPDIR=/tmp/seafile-$DATE-$TIME

# Shutdown seafile
$SEAFDIR/seafile-server-latest/seahub.sh stop
$SEAFDIR/seafile-server-latest/seafile.sh stop

# Create directories
if [ ! -d $BACKUPDIR ]
  then
  echo Creating Backupdirectory $BACKUPDIR...
  mkdir -pm 0600 $BACKUPDIR
fi
if [ ! -d $TEMPDIR ]
  then
  echo Create temporary directory $TEMPDIR...
  mkdir -pm 0600 $TEMPDIR
  mkdir -m 0600 $TEMPDIR/databases
  mkdir -m 0600 $TEMPDIR/data
fi

# Dump data / copy data
echo Dumping GroupMgr database...
sqlite3 $SEAFDIR/ccnet/GroupMgr/groupmgr.db .dump > $TEMPDIR/databases/groupmgr.db.bak
if [ -e $TEMPDIR/databases/groupmgr.db.bak ]; then echo ok.; else echo ERROR.; fi
echo Dumping UserMgr database...
sqlite3 $SEAFDIR/ccnet/PeerMgr/usermgr.db .dump > $TEMPDIR/databases/usermgr.db.bak
if [ -e $TEMPDIR/databases/usermgr.db.bak ]; then echo ok.; else echo ERROR.; fi
echo Dumping SeaFile database...
sqlite3 $SEAFDIR/seafile-data/seafile.sb .dump > $TEMPDIR/databases/seafile.db.bak
if [ -e $TEMPDIR/databases/seafile.db.bak ]; then echo ok.; else echo ERROR.; fi
echo Dumping SeaHub database...
sqlite3 $SEAFDIR/seahub.db .dump > $TEMPDIR/databases/seahub.db.bak
if [ -e $TEMPDIR/databases/seahub.db.bak ]; then echo ok.; else echo ERROR.; fi

echo Copying seafile directory...
rsync -az $SEAFDIR/* $TEMPDIR/data
if [ -d $TEMPDIR/data/seafile-data ]; then echo ok.; else echo ERROR.; fi

# Start the server
$SEAFDIR/seafile-server-latest/seafile.sh start
$SEAFDIR/seafile-server-latest/seahub.sh start-fastcgi

# compress data
echo Archive the backup...
cd $TEMPDIR
tar -cf $BACKUPFILE *
gzip $BACKUPFILE
if [ -e $BACKUPFILE.gz ]; then echo ok.; else echo ERROR.; fi

# Cleanup
echo Deleting temporary files...
rm -Rf $TEMPDIR
if [ ! -d $TEMPDIR ]; then echo ok.; else echo ERROR.; fi
