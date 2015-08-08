# Env variables
Required:
* `WEBCONF_AEM_ADMIN_PASSWORD` The current password to access the AEM web UI

Automatic:
* `CQ_PORT` The port on which AEM is listening
* `CQ_RUNMODE` The runmode of this AEM instance

Optional:
* `CONF2RUN_OVERWRITE_SEGMENTSTORE` Set to true to remove the segmentstore files stored in the mounted volume and replace them with the ones in "/segmentstore/" (usefull if first run)
* `WEBCONF_CHANGE_AEM_ADMIN_PASSWORD` Set to true if you want to change the AEM admin password (requires `WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD`)
* `WEBCONF_CHANGE_AEM_ADMIN_PASSWORD_NEW_PASSWORD` The new password for AEM admin
* `WEBCONF_CONFIG_FLUSH_AGENT` Set to true if you want to configure AEM Flush Agents (requires `WEBCONF_CONFIG_FLUSH_AGENT_{HOST,NAME,PORT,TITLE}`)
* `WEBCONF_CONFIG_FLUSH_AGENT_HOST` Array of flush agents hosts (separated by ','). Accepts IPs and variable name that would be docker links (no leading '$' only the variable name!)
* `WEBCONF_CONFIG_FLUSH_AGENT_NAME` Array of flush agents names (separated by ',') _Only alphanum_
* `WEBCONF_CONFIG_FLUSH_AGENT_PORT` Array of flush agents ports (separated by ',') Accepts ports and variable name that would be docker links (no leading '$' only the variable name!)
* `WEBCONF_CONFIG_FLUSH_AGENT_TITLE` Array of flush agents titles (separated by ',')
* `WEBCONF_CONFIG_GRANITE_AUTH_SSO` Set to true if you want to configure _partly_ (only one task on two) the "AEM Granite Auth SSO" attribute
* `WEBCONF_CONFIG_REPLICATION_AGENT` Set to true if you want to configure AEM Replication Agents (requires `WEBCONF_CONFIG_REPLICATION_AGENT_{HOST,NAME,PASSWORD,PORT,TITLE,USER}`)
* `WEBCONF_CONFIG_REPLICATION_AGENT_HOST` Array of replication agents hosts (separated by ',') Accepts IPs and variable name that would be docker links (no leading '$' only the variable name!)
* `WEBCONF_CONFIG_REPLICATION_AGENT_NAME` Array of replication agents names (separated by ',') _Only alphanum_
* `WEBCONF_CONFIG_REPLICATION_AGENT_PASSWORD` Array of replication agents passwords (separated by ',')
* `WEBCONF_CONFIG_REPLICATION_AGENT_PORT` Array of replication agents ports (separated by ',') Accepts ports and variable name that would be docker links (no leading '$' only the variable name!)
* `WEBCONF_CONFIG_REPLICATION_AGENT_TITLE` Array of replication agents titles (separated by ',')
* `WEBCONF_CONFIG_REPLICATION_AGENT_USER` Array of replication agents user names (separated by ',')
* `WEBCONF_INSTALL_BUNDLES` Set to true if you want to install the bundles at startup
* `WEBCONF_INSTALL_BUNDLES_LAST` Set to true if you want to install the bundles at the very end of the `web_conf.sh` script
* `WEBCONF_PUBLISH_TREE_ACTIVATION` Set to true if you want to enable for publication the paths defined in `WEBCONF_PUBLISH_TREE_ACTIVATION_PATHS`
* `WEBCONF_PUBLISH_TREE_ACTIVATION_PATHS` The paths to publish
* `WEBCONF_SET_AEM_SECURITY_CONF` Set to true if you want to enable the advised security configuration
* `WEBCONF_SET_HOME_PAGE_RULE` Set to true if you want to set the sling rule to choose the home page
* `WEBCONF_SET_RIGHTS` Set to true if you want to set ACLs (visitors & anonymous)
* `WEBCONF_SIGNAL_END` Set to true if you want to signal the end of configuration hence AEM is available (defaults to true, see `WEBCONF_SIGNAL_END_{FILE,DIR}`)
* `WEBCONF_SIGNAL_END_DIR` The path in which we want to create `WEBCONF_SIGNAL_END_FILE` (defaults to '/signals')
* `WEBCONF_SIGNAL_END_FILE` The file to create when the configuration ended (defaults to `flag_${CQ_RUNMODE}.ready`)
* `WEBCONF_URL_MAPPING_CONFIG` Set to true if you want to modify the sling rules for URL mapping (requires `WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT`)
* `WEBCONF_URL_MAPPING_CONFIG_FQDN_FRONT` FQDN of the front of AEM publish
* `WEBCONF_WEBSERVICES_CALLS_CONFIGURATION` Set to true to configure the webservices calls (requires `WEBCONF_WEBSERVICES_CALLS_CONFIGURATION_{HOST,PORT}`)
* `WEBCONF_WEBSERVICES_CALLS_CONFIGURATION_HOST` Webservices host
* `WEBCONF_WEBSERVICES_CALLS_CONFIGURATION_PORT` Webservices port
