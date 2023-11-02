#!/bin/bash

# https://cookbook.geuer-pollmann.de/azure/workload-identity-federation

private_key_file="key.pem"
public_key_file="key.pub"
idpCfg="fakeIdpCfg.json"

openssl genrsa -out "${private_key_file}" 2048
openssl rsa -in "${private_key_file}" -pubout > "${public_key_file}"

# echo "https://$( jq -r '.storageAccount.name' "${idpCfg}" ).blob.core.windows.net/$( jq -r '.storageAccount.container' "${idpCfg}" )"
# echo "$( jq -r '.token_details.iss' ../setup/informationForTheISV.json )"

storage_account="$( cat ../setup/informationForTheISV.json | jq -r '.token_details.iss' | sed 's|^https://\([^\.]*\).*|\1|' )"
container_name="$(  cat ../setup/informationForTheISV.json | jq -r '.token_details.iss' | sed 's|^https://[^\/]*/\(.*\)|\1|' )"

echo "https://${storage_account}.blob.core.windows.net/${container_name}"


issuer_path="https://${storage_account}.blob.core.windows.net/${container_name}"
jwks_keys="${issuer_path}/jwks_uri/keys"

openid_config_json="$( \
  echo '{"issuer":"","token_endpoint":"","jwks_uri":"","id_token_signing_alg_values_supported":["RS256"],"token_endpoint_auth_methods_supported":["client_secret_post"],"response_modes_supported":["form_post"],"response_types_supported":["id_token"],"scopes_supported":["openid"],"claims_supported":["sub","iss","aud","exp","iat","name"]}' | \
  jq --arg x "${issuer_path}"  '.issuer=$x'         | \
  jq --arg x "${issuer_path}"  '.token_endpoint=$x' | \
  jq --arg x "${jwks_keys}"    '.jwks_uri=$x'       | \
  jq -c -M "."                                      | \
  iconv --from-code=ascii --to-code=utf-8 )"

echo "${openid_config_json}" > openid-configuration.json

az storage blob upload                       \
   --account-name "${storage_account}"       \
   --container-name "${container_name}"      \
   --content-type "application/json"         \
   --file openid-configuration.json          \
   --name ".well-known/openid-configuration"