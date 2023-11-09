#!/bin/bash

readlink -f "$0"

dirname "$( readlink -f "$0" )" 

basedir="$( dirname "$( readlink -f "$0" )" )"
export basedir
if [[ -z $AZURE_HTTP_USER_AGENT ]]; then
   stateDir="${basedir}/../isv-configuration"
else
  # When running in Azure Cloudshell, the data should be stored in the file share.
  stateDir="${HOME}/clouddrive/isv-configuration"
fi
export stateDir
mkdir --parents "${stateDir}"
CONFIG_FILE="${stateDir}/config.json"

cat "${CONFIG_FILE}"