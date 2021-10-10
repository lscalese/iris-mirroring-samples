ARG IMAGE=intersystems/iris:2021.1.0.215.0
FROM $IMAGE
#FROM containers.intersystems.com/intersystems/iris:2021.1.0.215.0

USER root

COPY session.sh /
COPY iris.key /usr/irissys/mgr/iris.key

# Install iputils-arping to have arping command.  It's required to configure Virtual IP.
# Download the latest ZPM version...
RUN mkdir /opt/demo && \
    chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/demo && \
    chmod 666 /usr/irissys/mgr/iris.key && \
    apt-get update && apt-get install iputils-arping && \
    wget -O /opt/demo/zpm.xml https://pm.community.intersystems.com/packages/zpm/latest/installer

USER ${ISC_PACKAGE_MGRUSER}

WORKDIR /opt/demo

# Set Default Miror role to master, will be override on docker-compose file.
ARG IRIS_MIRROR_ROLE=master

ADD config-files .

SHELL [ "/session.sh" ]

# Install ZPM, config-api and pki-script
# Load a simple configuration file in json config-api format to : 
#  - create "myappdata" database.
#  - add a global mapping in namespace "USER" for global "demo.*" on "myappdata" database.
RUN \
Do $SYSTEM.OBJ.Load("/opt/demo/zpm.xml", "ck") \
zpm "install config-api" \
zpm "install pki-script" \
Set sc = ##class(Api.Config.Services.Loader).Load("/opt/demo/simple-config.json")

COPY init_mirror.sh /

# Execute a post start script to configure mirroring.
CMD ["-a", "/init_mirror.sh"]