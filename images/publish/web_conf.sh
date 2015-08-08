#!/bin/bash -x

set -e

# Makes sure that everything we (might) need is set
CQ_PORT=${CQ_PORT:?}
CQ_RUNMODE=${CQ_RUNMODE:?}
WEBCONF_AEM_ADMIN_PASSWORD=${WEBCONF_AEM_ADMIN_PASSWORD:?}

CURL_RETRY_NUM=${CURL_RETRY_NUM:-2}
CURL="curl --retry ${CURL_RETRY_NUM} -s -# -u admin:${WEBCONF_AEM_ADMIN_PASSWORD}"

# Waiting for AEM to start
/examine_log.sh /var/log/stdout.log "\[main\] Startup completed"

if [ "${WEBCONF_SET_AEM_SECURITY_CONF}" = true ] ; then
	# Some security conf
	$CURL http://localhost:${CQ_PORT}/system/console/bundles/org.apache.sling.jcr.webdav -F action=stop
	$CURL http://localhost:${CQ_PORT}/system/console/bundles/org.apache.sling.jcr.davex -F action=stop
fi

if [ "${WEBCONF_INSTALL_BUNDLES}" = "true" ] ; then
	cd /pkgs/
	echo "[*] Installing packages/bundles"

	for entry in $(cat list.${CQ_RUNMODE}); do
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
fi

# Change rights for anonymous and visitors
# May no try so set the rights for "/oak:index" because it doesn't work everytime
if [ "${WEBCONF_SET_RIGHTS}" = "true" ] ; then
	echo "[*] Setting appropriate rights"

	# Anonymous
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

	# Visitors
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

if [ "${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD}" = "true" ] ; then
	echo "[*] Changing default admin password"
	WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD=${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD:?AEM new password for admin not supplied}

	$CURL \
		--data-urlencode rep:password="${WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD}" \
		--data-urlencode :currentPassword="${WEBCONF_AEM_ADMIN_PASSWORD}" \
		--data-urlencode _charset="utf-8" \
		http://localhost:${CQ_PORT}/home/users/a/admin.rw.userprops.html
fi

# Signals that the configuration finished (hence this AEM is ready)
if [ "${WEBCONF_SIGNAL_END:-true}" = "true" ] ; then
	file=${WEBCONF_SIGNAL_END_DIR:-/signals}/${WEBCONF_SIGNAL_END_FILE:-flag_${CQ_RUNMODE}.ready}
	[ -e $file ] && rm $file
	touch $file
fi

echo -e "\n\n[+] Finished!\n"
