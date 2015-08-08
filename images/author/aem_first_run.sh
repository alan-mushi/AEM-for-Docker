#!/bin/bash -x

echo -e "\n\n[*] This step will take ~10 minutes\n\n"

cd /opt/aem/${CQ_RUNMODE}/

java -XX:MaxPermSize=256m -Xmx1024M -jar cq-${CQ_RUNMODE}-p${CQ_PORT}.jar -r ${CQ_RUNMODE},nosamplecontent -nobrowser -nofork &

/examine_log.sh /opt/aem/${CQ_RUNMODE}/crx-quickstart/logs/stdout.log "SUCCESSFULLY LOADED ESAPI.properties"
/examine_log.sh /opt/aem/${CQ_RUNMODE}/crx-quickstart/logs/stdout.log "SUCCESSFULLY LOADED validation.properties"

cd /hotfixes

echo "[*] Installing hotfixes"
for HOTFIX in $(cat hotfixes.${CQ_RUNMODE}) ; do
	cp $HOTFIX /opt/aem/${CQ_RUNMODE}/crx-quickstart/install/
	/examine_log.sh /opt/aem/${CQ_RUNMODE}/crx-quickstart/logs/error.log "${HOTFIX}.*content package installed"
done

# If we kill it right away we run into an issue : https://blogs.adobe.com/dmcmahon/2012/06/18/cq-5-5-update-1-service-unavailable-authenticationsupport-service-missing-cannot-authenticate-request/
sleep 30

ps ax | tee -a /tmp/processes
cat /tmp/processes | grep "java.*-jar.*cq-${CQ_RUNMODE}-p${CQ_PORT}.jar" | awk '{print $1}' | xargs kill -2
rm /tmp/processes
