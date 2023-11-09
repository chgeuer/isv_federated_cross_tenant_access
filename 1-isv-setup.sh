#!/bin/bash

# curl --silent --get --url https://gist.githubusercontent.com/chgeuer/3f1260cc555732a437aed8249a7b84ab/raw/2359f18c591b97e640736b9fce2a51c76f2c5f84/metering.sh > metering.sh

trap "exit 1" TERM
export TOP_PID=$$
source "$( dirname "$( readlink -f "$0" )" )/dependencies/state-handling.sh"

az config set extension.use_dynamic_install=yes_without_prompt > /dev/null 2>&1

isvTenant="$(               get-value-or-fail '.publisher.aadTenantId' )" 
export isvTenant
isvSubscriptionId="$(       get-value-or-fail '.publisher.subscriptionId' )" 
export isvSubscriptionId
isvResourceGroup="$(        get-value-or-fail '.publisher.resourceGroup' )" 
export isvResourceGroup
isvLocation="$(             get-value-or-fail '.publisher.location' )" 
export isvLocation


echo "Trying to deploy ISV IdP to tenant ${isvTenant} in subscription ${isvSubscriptionId} in resource group ${isvResourceGroup} in location ${isvLocation}"

_ignore="$( az group create \
  --subscription   "$( get-value-or-fail '.publisher.subscriptionId' )" \
  --resource-group "$( get-value-or-fail '.publisher.resourceGroup' )" \
  --location       "$( get-value-or-fail '.publisher.location' )" )"
  
idpStorageDeploymentResult="$( az deployment group create \
  --subscription   "$( get-value-or-fail '.publisher.subscriptionId' )" \
  --resource-group "$( get-value-or-fail '.publisher.resourceGroup' )" \
  --template-file  "${basedir}/isv_setup/main.bicep" \
  --parameters \
    currentUserId="$(      az ad signed-in-user show | jq -r '.id' )" \
    location="$(           get-value '.publisher.location' )" \
    storageAccountName="$( get-value '.publisher.optional.storageAccountName' )" \
    containerName="$(      get-value '.publisher.optional.containerName' )" \
    keyVaultName="$(       get-value '.publisher.optional.keyVaultName' )" \
  --output json )"

creationResult="$( echo "${idpStorageDeploymentResult}" | jq -r '.properties.outputs' )"
issuer_path="$(                echo "${creationResult}" | jq -r '.storage.value.url' )"
idp_storage_account_name="$(   echo "${creationResult}" | jq -r '.storage.value.storageAccountName' )"
idp_storage_container_name="$( echo "${creationResult}" | jq -r '.storage.value.containerName' )"

keyVaultName="$( echo "${creationResult}" | jq -r '.keyvault.value.name' )"
keyUri="$( echo "${creationResult}" | jq -r '.keyvault.value.keyUri' )"
keyJson="$( az keyvault key show --id "${keyUri}" | jq '.key' )"
keyId="$( echo "${keyJson}" | jq -r '.kid' )"

put-value '.publisher.optional.storageAccountName'  "${idp_storage_account_name}"
put-value '.publisher.optional.containerName'       "${idp_storage_container_name}"
put-value '.publisher.optional.keyVaultName'        "${keyVaultName}"
put-value '.publisher.idp.issuer'                   "${issuer_path}"
put-value '.publisher.idp.keyUri'                   "${keyUri}"
put-json-value '.publisher.idp.keyJson'             "${keyJson}"
put-value '.publisher.idp.keyId'                    "${keyId}"
put-value '.publisher.idp.issuer'                   "$( echo "${creationResult}" | jq -r '.storage.value.url' )"

# private_key_file="key.pem"
# openssl genrsa -out "${private_key_file}" 2048
# modulus="$( openssl rsa -in "${private_key_file}" -modulus -pubout -noout | sed 's/Modulus=//' | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf | base64 --wrap=0 )"
# exponent="AQAB"
# key_id="key1"

./1b-upload-issuer-files.sh
