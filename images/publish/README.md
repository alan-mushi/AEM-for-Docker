# Env variables

Required:
* `WEBCONF_AEM_ADMIN_PASSWORD` The current password to access the AEM web UI

Automatic:
* `CQ_PORT` The port on which AEM is listening
* `CQ_RUNMODE` The runmode of this AEM instance

Optional:
* `WEBCONF_CHANGE_AEM_ADMIN_PASSWORD` Set to true if you want to change the AEM admin password (see `WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD`)
* `WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD` The new password for AEM admin
* `WEBCONF_INSTALL_BUNDLES` Set to true if you want to install the bundles at startup
* `WEBCONF_SET_AEM_SECURITY_CONF` Set to true if you want to enable the advised security configuration
* `WEBCONF_SET_RIGHTS` Set to true if you want to set ACLs (visitors & anonymous)
* `WEBCONF_SIGNAL_END` Set to true if you want to signal the end of configuration hence AEM is available (defaults to true, see `WEBCONF_SIGNAL_END_{FILE,DIR}`)
* `WEBCONF_SIGNAL_END_DIR` The path in which we want to create `WEBCONF_SIGNAL_END_FILE` (defaults to '/signals')
* `WEBCONF_SIGNAL_END_FILE` The file to create when the configuration ended (defaults to `flag_${CQ_RUNMODE}.ready`)
* `CONF2RUN_OVERWRITE_SEGMENTSTORE` Set to true to remove the segmentstore files stored in the mounted volume and replace them with the ones in "/segmentstore/" (usefull if first run)
