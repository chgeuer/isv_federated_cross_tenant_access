#!/bin/bash


az login --tenant "geuer-pollmann.de"
az account set --subscription "chgeuer-msdn-new"

./0-add-defaults.sh

read -p "Please edit the settings in ./isv-configuration/config.json, the press [Enter] key to deploy the ISV backend..."

./1-isv-setup.sh

subject="massdriver"

./2-create-federated-credential-config-and-arm-template.sh "${subject}" 

token_file="./token.json"
customer_tenant_id="chgeuerfte.onmicrosoft.com"
uami_id="8159cab2-06f2-4098-9fbd-5410ab8f4137"


./3-create-token-file.sh "${subject}" "${token_file

./4-acquire-management-token.sh "${token_file}" "${customer_tenant_id}" "${uami_id}"

