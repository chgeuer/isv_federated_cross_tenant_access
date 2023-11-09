#!/bin/bash

#
# Login as the ISV
#
az login --tenant "geuer-pollmann.de"
az account set --subscription "chgeuer-msdn-new"

./0-add-defaults.sh

read -p "Please edit the settings in ./isv-configuration/config.json, the press [Enter] key to deploy the ISV backend..."

./1-isv-setup.sh

subject="massdriver"

# keyId="$( cat ./isv-configuration/config.json | jq -r '.publisher.idp.keyId' )"
# rm ./idpkey.pem
# az keyvault key download \
#   --id "${keyId}" \
#   --encoding PEM \
#   --file ./idpkey.pem
# ./dependencies/extract_OIDC_pubkey_from_PEM.sh ./idpkey.pem "${keyId}" 

./2-create-federated-credential-config-and-arm-template.sh "${subject}" 


#
# Login as the customer
#
az login --tenant "chgeuerfte.aad.geuer-pollmann.de"
az account set --subscription "chgeuer-work"

customerRgLocation="westeurope"
customerSubscription="$( az account show | jq -r '.id' )"
customerResourceGroup="rg-demomassdriver"
customerManagedIdentityName="massdriver2"

echo "Customer deploying LightHouse permissions into subscription ${customerSubscription} in resource group ${customerResourceGroup} in location ${customerRgLocation}"

customerDeploymentResult="$( az \
  deployment tenant create \
  --location "${customerRgLocation}" \
  --parameters "location=${customerRgLocation}" \
  --parameters "subscriptionId=${customerSubscription}" \
  --parameters "resourceGroupName=${customerResourceGroup}" \
  --parameters "identityName=${customerManagedIdentityName}" \
  --template-file ./setup/main.bicep )"

echo "${customerDeploymentResult}" \
  | jq ".properties.outputs.informationForTheISV.value" \
  > ./informationForTheISV.json

token_file="./token.json"

./4-create-token-file.sh "${subject}" "${token_file}"

echo "Now ${token_file} contains a self-issued access token that allows us to sign-in to the customer side: "

cat "${token_file}" | jq -R 'split(".") | (.[0], .[1]) | @base64d | fromjson'

customer_tenant_id="$( cat ./informationForTheISV.json | jq -r '.uami_tenant_id' )"
uami_id="$( cat ./informationForTheISV.json | jq -r '.uami_client_id' )"

echo "The ISV now can use that token to try to fetch a token from the customer tenant ${customer_tenant_id}, signing-in to UAMI ${uami_id}"

./5-acquire-management-token.sh "${token_file}" "${customer_tenant_id}" "${uami_id}"

