#!/bin/bash -x

set -e

# Makes sure that everything we (might) need is set
CQ_PORT=${CQ_PORT:?}
CQ_RUNMODE=${CQ_RUNMODE:?}
WEBCONF_AEM_ADMIN_PASSWORD=${WEBCONF_AEM_ADMIN_PASSWORD:?}

CURL_RETRY_NUM=${CURL_RETRY_NUM:-2}
CURL="curl --retry ${CURL_RETRY_NUM} -s -# -u admin:${WEBCONF_AEM_ADMIN_PASSWORD}"

############################ START functions ############################

# Install in order every bundle listed in the file supplied as argument
# arg:
#	the file list with lines formated like this: <bundle_name>:<complete_path_once_uploaded>
function install_bundles_from_file_list() {
	cd /pkgs/

	if [ ! -f $1 ] ; then
		echo "$1 is not a valid file"
		exit 1
	fi

	echo "[*] Installing packages/bundles from list '${1:?File list not defined}'"

	for entry in $(cat $1); do
		pkg=${entry%:*}
		pkg_path=${entry##*:}

		echo -en "\n\tUploading $pkg "
		$CURL -F package=@${pkg} http://localhost:${CQ_PORT}/crx/packmgr/service/.json/?cmd=upload
		echo -en "\n\tInstalling $pkg "
		ret=$($CURL -X POST http://localhost:${CQ_PORT}/crx/packmgr/service/.json${pkg_path}?cmd=install 2> /dev/null )

		if [ "$ret" != '{"success":true,"msg":"Package installed"}' ] ; then
			echo "FAILED install ${pkg}: $ret"
			exit 1
		fi
	done
}

# Add and configure a "flush agent" for AEM
# args:
#	$1	Flush agent title (e.g. "Dispatcher Flush F1")
#	$2	Flush agent name (e.g. "flush1"). Stick to alphanum for this one
#	$3	FLush agent host
#	$4	Flush agent port
function add_and_configure_aem_flush_agent() {
	flush_title="${1:?}"
	flush_name="${2:?}"
	flush_front_fqdn="${3:?}"
	flush_front_port=${4:?}

	# Create flush agent from template
	$CURL -X POST \
		--data-urlencode "cmd=createPage" \
		--data-urlencode "_charset_=utf-8" \
		--data-urlencode ":status=browser" \
		--data-urlencode "parentPath=/etc/replication/agents.author" \
		--data-urlencode "title=${flush_title}" \
		--data-urlencode "label=${flush_name}" \
		--data-urlencode "template=/libs/cq/replication/templates/agent" \
		http://localhost:${CQ_PORT}/bin/wcmcommand

	# Configure flush agent
	$CURL -X POST \
		--data-urlencode "./sling:resourceType=cq/replication/components/agent" \
		--data-urlencode "./jcr:lastModified=" \
		--data-urlencode "./jcr:lastModifiedBy=" \
		--data-urlencode "_charset_=utf-8" \
		--data-urlencode ":status=browser" \
		--data-urlencode "./jcr:title=${flush_title}" \
		--data-urlencode "./jcr:description=Agent that sends flush requests to the dispatcher." \
		--data-urlencode "./enabled=true" \
		--data-urlencode "./enabled@Delete=" \
		--data-urlencode "./serializationType=flush" \
		--data-urlencode "./retryDelay=60000" \
		--data-urlencode "./userId=" \
		--data-urlencode "./logLevel=error" \
		--data-urlencode "./reverseReplication@Delete=" \
		--data-urlencode "./transportUri=http://${flush_front_fqdn}:${flush_front_port}/dispatcher/invalidate.cache" \
		--data-urlencode "./transportUser=" \
		--data-urlencode "./transportPassword=" \
		--data-urlencode "./transportNTLMDomain=" \
		--data-urlencode "./transportNTLMHost=" \
		--data-urlencode "./ssl=" \
		--data-urlencode "./protocolHTTPExpired@Delete=" \
		--data-urlencode "./proxyHost=" \
		--data-urlencode "./proxyPort=" \
		--data-urlencode "./proxyUser=" \
		--data-urlencode "./proxyPassword=" \
		--data-urlencode "./proxyNTLMDomain=" \
		--data-urlencode "./proxyNTLMHost=" \
		--data-urlencode "./protocolInterface=" \
		--data-urlencode "./protocolHTTPMethod=" \
		--data-urlencode "./protocolHTTPHeaders@Delete=" \
		--data-urlencode "./protocolHTTPConnectionClose@Delete=true" \
		--data-urlencode "./protocolConnectTimeout=" \
		--data-urlencode "./protocolSocketTimeout=" \
		--data-urlencode "./protocolVersion=" \
		--data-urlencode "./triggerSpecific@Delete=" \
		--data-urlencode "./triggerModified@Delete=" \
		--data-urlencode "./triggerDistribute@Delete=" \
		--data-urlencode "./triggerOnOffTime@Delete=" \
		--data-urlencode "./triggerReceive@Delete=" \
		--data-urlencode "./noStatusUpdate@Delete=" \
		--data-urlencode "./noVersioning@Delete=" \
		--data-urlencode "./queueBatchMode@Delete=" \
		--data-urlencode "./queueBatchWaitTime=" \
		--data-urlencode "./queueBatchMaxSize=" \
		http://localhost:${CQ_PORT}/etc/replication/agents.author/${flush_name}/jcr:content

	# Flush agent test connexion
	$CURL http://localhost:${CQ_PORT}/etc/replication/agents.author/${flush_name}.test.html
}

# Add and configure a new replication agent for AEM
# args:
#	$1	Replication agent title (e.g. "Agent Publish P1")
#	$2	Replication agent name (e.g. "publish1"). Stick to alphanum for this one
#	$3	Replication agent host
#	$4	Replication agent port
#	$5	Replication agent user
#	$6	Replication agent password
function add_and_configure_aem_replication_agent() {
	agent_title="${1:?}"
	agent_name="${2:?}"
	agent_url="http://${3:?}:${4:?}/bin/receive?sling:authRequestLogin=1"
	agent_user=${5:?}
	agent_password=${6:?}

	$CURL -X POST \
		--data-urlencode "cmd=createPage" \
		--data-urlencode "_charset_=utf-8" \
		--data-urlencode ":status=browser" \
		--data-urlencode "parentPath=/etc/replication/agents.author" \
		--data-urlencode "title=${agent_title}" \
		--data-urlencode "label=${agent_name}" \
		--data-urlencode "template=/libs/cq/replication/templates/agent" \
		http://localhost:${CQ_PORT}/bin/wcmcommand

	$CURL -X POST \
		--data-urlencode "./sling:resourceType=cq/replication/components/agent" \
		--data-urlencode "./jcr:lastModified=" \
		--data-urlencode "./jcr:lastModifiedBy=" \
		--data-urlencode "_charset_=utf-8" \
		--data-urlencode ":status=browser" \
		--data-urlencode "./jcr:title=${agent_title}" \
		--data-urlencode "./jcr:description=" \
		--data-urlencode "./enabled=true" \
		--data-urlencode "./enabled@Delete=" \
		--data-urlencode "./serializationType=durbo" \
		--data-urlencode "./retryDelay=60000" \
		--data-urlencode "./userId=" \
		--data-urlencode "./logLevel=info" \
		--data-urlencode "./reverseReplication@Delete=" \
		--data-urlencode "./transportUri=${agent_url}" \
		--data-urlencode "./transportUser=${agent_user}" \
		--data-urlencode "./transportPassword=${agent_password}" \
		--data-urlencode "./transportNTLMDomain=" \
		--data-urlencode "./transportNTLMHost=" \
		--data-urlencode "./ssl=" \
		--data-urlencode "./protocolHTTPExpired@Delete=" \
		--data-urlencode "./proxyHost=" \
		--data-urlencode "./proxyPort=" \
		--data-urlencode "./proxyUser=" \
		--data-urlencode "./proxyPassword=" \
		--data-urlencode "./proxyNTLMDomain=" \
		--data-urlencode "./proxyNTLMHost=" \
		--data-urlencode "./protocolInterface=" \
		--data-urlencode "./protocolHTTPMethod=" \
		--data-urlencode "./protocolHTTPHeaders@Delete=" \
		--data-urlencode "./protocolHTTPConnectionClose@Delete=true" \
		--data-urlencode "./protocolConnectTimeout=" \
		--data-urlencode "./protocolSocketTimeout=" \
		--data-urlencode "./protocolVersion=" \
		--data-urlencode "./triggerSpecific@Delete=" \
		--data-urlencode "./triggerModified@Delete=" \
		--data-urlencode "./triggerDistribute@Delete=" \
		--data-urlencode "./triggerOnOffTime@Delete=" \
		--data-urlencode "./triggerReceive@Delete=" \
		--data-urlencode "./noStatusUpdate@Delete=" \
		--data-urlencode "./noVersioning@Delete=" \
		--data-urlencode "./queueBatchMode@Delete=" \
		--data-urlencode "./queueBatchWaitTime=" \
		--data-urlencode "./queueBatchMaxSize=" \
		http://localhost:${CQ_PORT}/etc/replication/agents.author/${agent_name}/jcr:content

	# Replication test
	curl ${agent_url}
}

# Variables are not expanded when sourced.
# It's a problem if you need to use variables created by docker link.
# Return the first string(s) that was/were match by the grep expression.
# If nothing was matched it return the first argument.
# args:
#	$1	The variable name (at least the beginning of it) to match in env
function link_string_from_env() {
	value=$(env | grep "$1" | grep -v "^WEBCONF" | head -n 1 | cut -d '=' -f 2)

	if [ "x$value" = "x" ] ; then
		value=$1
	fi

	echo $value
}

############################ END functions ############################

# Waiting for AEM to start
/examine_log.sh /var/log/stdout.log "\[main\] Startup completed"

if [ "${WEBCONF_SET_AEM_SECURITY_CONF}" = "true" ] ; then
	# Some security conf
	$CURL -u admin:admin http://localhost:${CQ_PORT}/system/console/bundles/org.apache.sling.jcr.webdav -F action=stop
fi

if [ "${WEBCONF_INSTALL_BUNDLES}" = "true" ] ; then
	install_bundles_from_file_list list.${CQ_RUNMODE}
fi

# Change rights for anonymous and visitors
# May no try so set the rights for "/oak:index" because it doesn't work everytime
if [ "${WEBCONF_SET_RIGHTS}" = "true" ] ; then
	echo "[*] Setting appropriate rights"

	$CURL -X POST \
		--data-urlencode "authorizableId=anonymous" \
		--data-urlencode "changelog=path:/,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/apps,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/content,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/etc,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/home,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/libs,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/oak:index,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/system,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/tmp,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/var,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		http://localhost:${CQ_PORT}/.cqactions.html \
	|| echo "[-] OAK:index seems to refuse the <read> property for anonymous, trying without..." && \
	$CURL -X POST \
		--data-urlencode "authorizableId=anonymous" \
		--data-urlencode "changelog=path:/,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/apps,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/content,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/etc,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/home,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/libs,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/system,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/tmp,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/var,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		http://localhost:${CQ_PORT}/.cqactions.html

	$CURL -X POST \
		--data-urlencode "authorizableId=visitors" \
		--data-urlencode "changelog=path:/,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/apps,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/content,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/etc,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/home,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/libs,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/oak:index,read:false,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/system,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/tmp,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/var,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		http://localhost:${CQ_PORT}/.cqactions.html \
	|| echo "[-] OAK:index seems to refuse the <read> property for visitors, trying without..." && \
	$CURL -X POST \
		--data-urlencode "authorizableId=visitors" \
		--data-urlencode "changelog=path:/,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/apps,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/content,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/etc,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/home,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/libs,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/system,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/tmp,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		--data-urlencode "changelog=path:/var,read:true,modify:false,create:false,delete:false,acl_read:false,acl_edit:false,replicate:false" \
		http://localhost:${CQ_PORT}/.cqactions.html
fi

if [ "${WEBCONF_CONFIG_GRANITE_AUTH_SSO}" = "true" ] ; then
	echo "[*] Configuration AEM Site RC (Granite Auth SSO)"
	$CURL \
		--data-urlencode "apply=true" \
		--data-urlencode "action=ajaxConfigManager" \
		--data-urlencode "path=/" \
		--data-urlencode "service.ranking=0" \
		--data-urlencode "jaas.controlFlag=sufficient" \
		--data-urlencode "jaas.realmName=jackrabbit.oak" \
		--data-urlencode "jaas.ranking=1000" \
		--data-urlencode "headers=uid" \
		--data-urlencode "cookies=" \
		--data-urlencode "parameters=" \
		--data-urlencode "usermap=" \
		--data-urlencode "format=AsIs" \
		--data-urlencode "trustedCredentialsAttribute=" \
		--data-urlencode "propertylist=path,service.ranking,jaas.controlFlag,jaas.realmName,jaas.ranking,headers,cookies,parameters,usermap,format,trustedCredentialsAttribute" \
		http://localhost:${CQ_PORT}/system/console/configMgr/com.adobe.granite.auth.sso.impl.SsoAuthenticationHandler
fi

# SSO Config
# curl -u admin:admin -v --data "apply=true&action=ajaxConfigManager&path=%2F&service.ranking=0&jaas.controlFlag=sufficient&jaas.realmName=jackrabbit.oak&jaas.ranking=1000&headers=uid&cookies=&parameters=&usermap=&format=AsIs&trustedCredentialsAttribute=&propertylist=path%2Cservice.ranking%2Cjaas.controlFlag%2Cjaas.realmName%2Cjaas.ranking%2Cheaders%2Ccookies%2Cparameters%2Cusermap%2Cformat%2CtrustedCredentialsAttribute" http://localhost:${CQ_PORT}/system/console/configMgr/com.adobe.granite.auth.sso.impl.SsoAuthenticationHandler

if [ "${WEBCONF_CONFIG_REPLICATION_AGENT}" = "true" ] ; then
	IFS=',' read -a repl_agent_title <<< "${WEBCONF_CONFIG_REPLICATION_AGENT_TITLE:?}"
	IFS=',' read -a repl_agent_name <<< "${WEBCONF_CONFIG_REPLICATION_AGENT_NAME:?}"
	IFS=',' read -a repl_agent_host <<< "${WEBCONF_CONFIG_REPLICATION_AGENT_HOST:?}"
	IFS=',' read -a repl_agent_port <<< "${WEBCONF_CONFIG_REPLICATION_AGENT_PORT:?}"
	IFS=',' read -a repl_agent_user <<< "${WEBCONF_CONFIG_REPLICATION_AGENT_USER:?}"
	IFS=',' read -a repl_agent_password <<< "${WEBCONF_CONFIG_REPLICATION_AGENT_PASSWORD:?}"

	echo -e "\t\ttitle = ${repl_agent_title[@]}"
	echo -e "\t\tname = ${repl_agent_name[@]}"
	echo -e "\t\thost = ${repl_agent_host[@]}"
	echo -e "\t\tport = ${repl_agent_port[@]}"
	echo -e "\t\tuser = ${repl_agent_user[@]}"
	echo -e "\t\tpassword = ${repl_agent_password[@]}"

	# We check that all arrays have the same length
	if [ ${#repl_agent_title[@]} -ne ${#repl_agent_name[@]} ] || \
		[ ${#repl_agent_title[@]} -ne ${#repl_agent_host[@]} ] || \
		[ ${#repl_agent_title[@]} -ne ${#repl_agent_port[@]} ] || \
		[ ${#repl_agent_title[@]} -ne ${#repl_agent_user[@]} ] || \
		[ ${#repl_agent_title[@]} -ne ${#repl_agent_password[@]} ] ; then

		echo -e "\t[-] Flush Agent Arrays are not of the same length"
		echo -e "\t\t#title = ${#repl_agent_title[@]}"
		echo -e "\t\t#name = ${#repl_agent_name[@]}"
		echo -e "\t\t#host = ${#repl_agent_host[@]}"
		echo -e "\t\t#port = ${#repl_agent_port[@]}"
		echo -e "\t\t#user = ${#repl_agent_user[@]}"
		echo -e "\t\t#password = ${#repl_agent_password[@]}"
		exit 1
	fi

	echo "[*] Configuration of replication to AEM Publish"
	for i in $(seq 0 $((${#repl_agent_title[@]} - 1))) ; do
		echo "i = $i"
		add_and_configure_aem_replication_agent "${repl_agent_title[$i]}" \
			${repl_agent_name[$i]} \
			$(link_string_from_env "${repl_agent_host[$i]}") \
			$(link_string_from_env "${repl_agent_port[$i]}") \
			${repl_agent_user[$i]} \
			${repl_agent_password[$i]}
	done

	# Disable default Replication Agent
	$CURL -X POST \
		--data-urlencode "./sling:resourceType=cq/replication/components/agent" \
		--data-urlencode "./jcr:lastModified=" \
		--data-urlencode "./jcr:lastModifiedBy=" \
		--data-urlencode "_charset_=utf-8" \
		--data-urlencode ":status=browser" \
		--data-urlencode "./jcr:title=Agent Publish" \
		--data-urlencode "./jcr:description=Agent that replicates to the default publish instance." \
		--data-urlencode "./enabled@Delete=" \
		--data-urlencode "./serializationType=durbo" \
		--data-urlencode "./retryDelay=60000" \
		--data-urlencode "./userId=" \
		--data-urlencode "./logLevel=info" \
		--data-urlencode "./reverseReplication@Delete=" \
		--data-urlencode "./transportUri=http://publish:4503/bin/receive?sling:authRequestLogin=1" \
		--data-urlencode "./transportUser=admin" \
		--data-urlencode "./transportPassword={2fe3a1bc231e172fce538a46c4eec7153f48c4c4266191643a634e41dd1b2543}" \
		--data-urlencode "./transportNTLMDomain=" \
		--data-urlencode "./transportNTLMHost=" \
		--data-urlencode "./ssl=" \
		--data-urlencode "./protocolHTTPExpired@Delete=" \
		--data-urlencode "./proxyHost=" \
		--data-urlencode "./proxyPort=" \
		--data-urlencode "./proxyUser=" \
		--data-urlencode "./proxyPassword=" \
		--data-urlencode "./proxyNTLMDomain=" \
		--data-urlencode "./proxyNTLMHost=" \
		--data-urlencode "./protocolInterface=" \
		--data-urlencode "./protocolHTTPMethod=" \
		--data-urlencode "./protocolHTTPHeaders@Delete=" \
		--data-urlencode "./protocolHTTPConnectionClose@Delete=true" \
		--data-urlencode "./protocolConnectTimeout=" \
		--data-urlencode "./protocolSocketTimeout=" \
		--data-urlencode "./protocolVersion=" \
		--data-urlencode "./triggerSpecific@Delete=" \
		--data-urlencode "./triggerModified@Delete=" \
		--data-urlencode "./triggerDistribute@Delete=" \
		--data-urlencode "./triggerOnOffTime@Delete=" \
		--data-urlencode "./triggerReceive@Delete=" \
		--data-urlencode "./noStatusUpdate@Delete=" \
		--data-urlencode "./noVersioning@Delete=" \
		--data-urlencode "./queueBatchMode@Delete=" \
		--data-urlencode "./queueBatchWaitTime=" \
		--data-urlencode "./queueBatchMaxSize=" \
		http://localhost:${CQ_PORT}/etc/replication/agents.author/publish/jcr:content
fi

if [ "${WEBCONF_CONFIG_FLUSH_AGENT}" = "true" ] ; then
	IFS=',' read -a flush_agent_title <<< "${WEBCONF_CONFIG_FLUSH_AGENT_TITLE:?}"
	IFS=',' read -a flush_agent_name <<< "${WEBCONF_CONFIG_FLUSH_AGENT_NAME:?}"
	IFS=',' read -a flush_agent_host <<< "${WEBCONF_CONFIG_FLUSH_AGENT_HOST:?}"
	IFS=',' read -a flush_agent_port <<< "${WEBCONF_CONFIG_FLUSH_AGENT_PORT:?}"

	echo -e "\t\ttitle = ${flush_agent_title[@]}"
	echo -e "\t\tname = ${flush_agent_name[@]}"
	echo -e "\t\thost = ${flush_agent_host[@]}"
	echo -e "\t\tport = ${flush_agent_port[@]}"

	# We check that all arrays have the same length
	if [ ${#flush_agent_title[@]} -ne ${#flush_agent_name[@]} ] || \
		[ ${#flush_agent_title[@]} -ne ${#flush_agent_host[@]} ] || \
		[ ${#flush_agent_title[@]} -ne ${#flush_agent_port[@]} ] ; then

		echo -e "\t[-] Flush Agent Arrays are not of the same length"
		echo -e "\t\t#title = ${#flush_agent_title[@]}"
		echo -e "\t\t#name = ${#flush_agent_name[@]}"
		echo -e "\t\t#host = ${#flush_agent_host[@]}"
		echo -e "\t\t#port = ${#flush_agent_port[@]}"
		exit 1
	fi

	echo "[*] Configuration of Flush Agent(s)"
	for i in $(seq 0 $((${#flush_agent_title[@]} - 1))) ; do
		add_and_configure_aem_flush_agent "${flush_agent_title[$i]}" \
			${flush_agent_name[$i]} \
			$(link_string_from_env "${flush_agent_host[$i]}") \
			$(link_string_from_env "${flush_agent_port[$i]}")
	done
fi

if [ "${WEBCONF_PUBLISH_TREE_ACTIVATION}" = "true" ] ; then
	echo "[*] Content (path) publication to AEM Publish"

	for path in ${WEBCONF_PUBLISH_TREE_ACTIVATION_PATHS} ; do
		$CURL -X POST \
			--data-urlencode "path=${path}" \
			--data-urlencode "cmd=activate" \
			http://localhost:${CQ_PORT}/etc/replication/treeactivation.html > /dev/null
	done
fi

if [ "${WEBCONF_WEBSERVICES_CALLS_CONFIGURATION}" = "true" ] ; then
	echo "[*] WebServices calls configuration"
	conf_webservices_file=$(mktemp /tmp/conf_webservices.XXXXXXXXXX)

	cat << __EOF__ > $conf_webservices_file
--crxde
Content-Disposition: form-data; name=":diff"
Content-Type: text/plain; charset=utf-8

^/apps/WEBSITE/config/com.website.config.WSConfiguration/webservices.baseurl : "${WEBCONF_WEBSERVICES_CALLS_CONFIGURATION_HOST}"
^/apps/WEBSITE/config/com.website.config.WSConfiguration/webservices.port : "${WEBCONF_WEBSERVICES_CALLS_CONFIGURATION_PORT}"
--crxde--
__EOF__

	unix2dos $conf_webservices_file

	$CURL -X POST \
		--header "Content-Type: multipart/form-data; charset=UTF-8; boundary=crxde" \
		--header "Referer: http://localhost:${CQ_PORT}/crx/de/index.jsp" \
		--data-binary @${conf_webservices_file} \
		http://localhost:${CQ_PORT}/crx/server/crx.default/jcr%3aroot

	rm $conf_webservices_file

	curl -u admin:admin1 -v -s -X POST \
		--data-urlencode "path=/apps/WEBSITE/config/com.website.config.WSConfiguration" \
		--data-urlencode "action=replicate" \
		--data-urlencode "_charset_=utf-8" \
		http://localhost:${CQ_PORT}/crx/de/replication.jsp
fi

if [ "${WEBCONF_SET_HOME_PAGE_RULE}" = "true" ] ; then
	echo "[*] Set home page rule"
	conf_accueil_file=$(mktemp /tmp/conf_accueil.XXXXXXXXXX)

	cat << __EOF__ > $conf_accueil_file
--crxde
Content-Disposition: form-data; name=":diff"
Content-Type: text/plain; charset=utf-8

^/content/sling:target : "/fr/accueil"
--crxde--
__EOF__

	unix2dos $conf_accueil_file

	$CURL -X POST \
		--header "Content-Type: multipart/form-data; charset=UTF-8; boundary=crxde" \
		--header "Referer: http://localhost:${CQ_PORT}/crx/de/index.jsp" \
		--data-binary @${conf_accueil_file} \
		http://localhost:${CQ_PORT}/crx/server/crx.default/jcr%3aroot

	rm $conf_accueil_file

	$CURL -X POST \
		--data-urlencode "path=/content" \
		--data-urlencode "action=replicate" \
		--data-urlencode "_charset_=utf-8" \
		http://localhost:${CQ_PORT}/crx/de/replication.jsp
fi

if [ "${WEBCONF_URL_MAPPING_CONFIG}" = "true" ] ; then
	WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT=${WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT:?Publish front not defined}
	echo "[*] URL mapping configuration"
	conf_url_file=$(mktemp /tmp/conf_url.XXXXXXXXXX)

	cat << __EOF__ > ${conf_url_file}
--crxde
Content-Disposition: form-data; name=":diff"
Content-Type: text/plain; charset=utf-8

^/etc/map/http/en_publish/sling:match : "${WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT}/en"
^/etc/map/http/fr_publish/sling:match : "${WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT}/fr"
^/etc/map/https/en_publish/sling:match : "${WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT}/en"
^/etc/map/https/fr_publish/sling:match : "${WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT}/fr"
--crxde--
__EOF__

	unix2dos ${conf_url_file}

	$CURL -X POST \
		--header "Content-Type: multipart/form-data; charset=UTF-8; boundary=crxde" \
		--header "Referer: http://localhost:${CQ_PORT}/crx/de/index.jsp" \
		--data-binary @${conf_url_file} \
		http://localhost:${CQ_PORT}/crx/server/crx.default/jcr%3aroot

	rm ${conf_url_file}
fi

if [ "${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD}" = "true" ] ; then
	echo "[*] Changing default admin password"
	WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD=${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD:?AEM new password for admin not supplied}

	$CURL \
		--data-urlencode rep:password="${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD}" \
		--data-urlencode :currentPassword="${WEBCONF_AEM_ADMIN_PASSWORD}" \
		--data-urlencode _charset="utf-8" \
		http://localhost:${CQ_PORT}/home/users/a/admin.rw.userprops.html
	
	export WEBCONF_AEM_ADMIN_PASSWORD="${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD}"
	export CURL="curl --retry ${CURL_RETRY_NUM} -s -# -u admin:${WEBCONF_AEM_ADMIN_PASSWORD}"
fi

# Bundles to install last (e.g. ACLs that modifies password)
if [ "${WEBCONF_INSTALL_BUNDLES_LAST}" = "true" ] ; then
	install_bundles_from_file_list list_last.${CQ_RUNMODE}
fi

# Signals that the configuration finished (hence this AEM is ready)
if [ "${WEBCONF_SIGNAL_END:-true}" = "true" ] ; then
	file=${WEBCONF_SIGNAL_END_DIR:-/signals}/${WEBCONF_SIGNAL_END_FILE:-flag_${CQ_RUNMODE}.ready}
	[ -e $file ] && rm $file
	touch $file
fi

echo -e "\n\n[+] Finished!\n"
