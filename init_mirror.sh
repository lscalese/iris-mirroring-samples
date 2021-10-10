#!/bin/bash

# Database used to test the mirror.
DATABASE=/usr/irissys/mgr/myappdata

# Directory contain myappdata backuped by the master to restore on other nodes and making mirror.
BACKUP_FOLDER=/opt/backup

# Mirror configuration file in json config-api format for the master node.
MASTER_CONFIG=/opt/demo/mirror-master.json

# Mirror configuration file in json config-api format for the backup node.
BACKUP_CONFIG=/opt/demo/mirror-backup.json

# Mirror configuration file in json config-api format for the report async node.
REPORT_CONFIG=/opt/demo/mirror-report.json

# Initial configuration (Before create mirror).
INITIAL_CONFIG=/opt/demo/simple-config.json

# The mirror name...
MIRROR_NAME=DEMO

# Mirror Member list.
MIRROR_MEMBERS=BACKUP,REPORT

# Performed on the master.
# Configure Public Key Infrastructure Server on this instance and generate certificate in order to configure a mirror using SSL.
#   See article https://community.intersystems.com/post/creating-ssl-enabled-mirror-intersystems-iris-using-public-key-infrastructure-pki
#   and the related tools https://openexchange.intersystems.com/package/PKI-Script
# Load the mirror configuration using config-api with /opt/demo/simple-config.json file.
# Start a Job to auto-accept other members named "backup" and "report" to join the mirror (avoid manuel validation in portal management).
master() {
rm -rf $BACKUP_FOLDER/IRIS.DAT
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS <<- END
Do ##class(lscalese.pki.Utils).MirrorMaster(,"")
Set sc = ##class(Api.Config.Services.Loader).Load("${MASTER_CONFIG}")
Set ^log.mirrorconfig(\$i(^log.mirrorconfig)) = \$SYSTEM.Status.GetOneErrorText(sc)
Job ##class(Api.Config.Services.SYS.MirrorMaster).AuthorizeNewMembers("${MIRROR_MEMBERS}","${MIRROR_NAME}")
Hang 2
Halt
END
}

# Performed by the master, make a backup of /usr/irissys/mgr/myappdata/
make_backup() {
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).DismountDatabase(\"${DATABASE}\")"
md5sum ${DATABASE}/IRIS.DAT
cp ${DATABASE}/IRIS.DAT ${BACKUP_FOLDER}/IRIS.DAT
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).MountDatabase(\"${DATABASE}\")"
}

# Restore the mirrored database "myappdata".  This restore is performed on "backup" and "report" node.
restore_backup() {
sleep 5
while [ ! -f $BACKUP_FOLDER/IRIS.DAT ]; do sleep 1; done
sleep 2
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).DismountDatabase(\"${DATABASE}\")"
cp $BACKUP_FOLDER/IRIS.DAT $DATABASE/IRIS.DAT
md5sum $DATABASE/IRIS.DAT
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS "##class(SYS.Database).MountDatabase(\"${DATABASE}\")"
}

# Configure the "backup" member
#  - Configure Public Key Infrastructure client to install certificate and use SSL with the mirror.
#      PKI-Script tools is used for this operation.
#  - Configure this instance as a failover node on mirror "DEMO" using config-api tools 
#    with this configuration file /opt/demo/mirror-failover.json 
backup() {
sleep 5
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS <<- END
Do ##class(lscalese.pki.Utils).MirrorBackup("master:52773","")
Set sc = ##class(Api.Config.Services.Loader).Load("${BACKUP_CONFIG}")
Set ^log.mirrorconfig(\$i(^log.mirrorconfig)) = \$SYSTEM.Status.GetOneErrorText(sc)
Halt
END
}

# Configure the "backup" member
#  - Configure Public Key Infrastructure client to install certificate and use SSL with the mirror.
#  - Configure this instance as an async report read\write node on mirror "DEMO" using config-api tools 
#    with this configuration file /opt/demo/mirror-async.json 
report() {
iris session $ISC_PACKAGE_INSTANCENAME -U %SYS <<- END
Set sc = ##class(lscalese.pki.Utils).MirrorBackup("master:52773","")
Set sc = ##class(Api.Config.Services.Loader).Load("${REPORT_CONFIG}")
Set ^log.mirrorconfig(\$i(^log.mirrorconfig)) = \$SYSTEM.Status.GetOneErrorText(sc)
Halt
END
}

if [ "$IRIS_MIRROR_ROLE" == "master" ]
then
  master $IRIS_MIRROR_ARBITER
  make_backup
elif [ "$IRIS_MIRROR_ROLE" == "backup" ]
then
  restore_backup
  backup
else
  restore_backup
fi

exit 0

# elif [ "$IRIS_MIRROR_ROLE" == "backup" ]; then 
#  restore_backup
#  backup
# else 
#  restore_backup
#  backup