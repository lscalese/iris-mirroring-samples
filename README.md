# IRIS Mirroring samples

In this repository we can find a sample to create mirroring fully scripted without manual intervention.  

We use IRIS, ZPM Package manager and docker.  


## Prerequisites

 * [Mirroring knowledge](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GHA_mirror).  
 * WRC Access.  

## Instructions

Create users and groups :

```bash
sudo useradd --uid 51773 --user-group irisowner
sudo useradd --uid 52773 --user-group irisuser
sudo groupmod --gid 51773 irisowner
sudo groupmod --gid 52773 irisuser
sudo chgrp irisowner ./backup
```

Login to Intersystems Containers Registry.  
Remember the ICR password is not your WRC password, you can show your password login to https://wrc.intersystems.com and then  
open this page https://login.intersystems.com/login/SSO.UI.User.ApplicationTokens.cls


```bash
docker login -u="YourWRCLogin" -p="YourPassWord" containers.intersystems.com
```

Connect to https://wrc.interystems.com and get a docker License, copy it in the repository directory.  


## Build and run containers

```
docker-compose up
```

After a `docker-compose down` delete IRIS.DAT file in backup directory to avoid a permission denied error on the next try.

```
rm -vf ./backup/IRIS.DAT
```

## Access to portals

Master : http://localhost:81/csp/sys/utilhome.csp
Failover backup member : http://localhost:82/csp/sys/utilhome.csp
Read-Write report asyinc member : http://localhost:83/csp/sys/utilhome.csp
