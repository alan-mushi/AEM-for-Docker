#!/bin/bash

set -e

. /etc/default/cq-${CQ_RUNMODE}

export CQ_QUICKSTART=${CQ_ROOT}/crx-quickstart
export CQ_JARFILE=${CQ_ROOT}/crx-quickstart/app/cq-quickstart-6.0.0-standalone.jar
export CQ_FILE_SIZE_LIMIT=8192
export CQ_FOREGROUND=y
export CQ_VERBOSE=y
export CQ_NOBROWSER=y
export CQ_JVM_OPTS="-server -Djava.awt.headless=true -Xms4096m -Xmx4096m -XX:PermSize=256m -XX:MaxPermSize=256m -Dcom.sun.management.jmxremote.port=8463 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.ssl=false -Dsling.run.modes=${CQ_RUNMODE},nosamplecontent -Djava.security.auth.login.config=${CQ_JAAS_CONFIG}"
export START_OPTS="start -c $CQ_QUICKSTART -i launchpad -p $CQ_PORT -Dsling.properties=conf/sling.properties"
export CQ_PORT

if [ "${CONF2RUN_OVERWRITE_SEGMENTSTORE}" == "true" ] ; then
	rm -vf ${CQ_QUICKSTART}/repository/segmentstore/*
	cp -v /segmentstore/* ${CQ_QUICKSTART}/repository/segmentstore/
fi

# run extra conf in background
/web_conf.sh &

export PIDFILE=/var/run/aem/cq-${CQ_RUNMODE}.pid
java $CQ_JVM_OPTS -jar $CQ_JARFILE $START_OPTS | tee -a /var/log/stdout.log
