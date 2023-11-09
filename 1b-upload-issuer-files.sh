#!/bin/bash

# curl --silent --get --url https://gist.githubusercontent.com/chgeuer/3f1260cc555732a437aed8249a7b84ab/raw/2359f18c591b97e640736b9fce2a51c76f2c5f84/metering.sh > metering.sh

trap "exit 1" TERM
export TOP_PID=$$
source "$( dirname "$( readlink -f "$0" )" )/dependencies/state-handling.sh"



idp_storage_account_name="$( get-value   '.publisher.optional.storageAccountName' )"
idp_storage_container_name="$( get-value '.publisher.optional.containerName' )"
keyVaultName="$( get-value               '.publisher.optional.keyVaultName' )"
issuer_path="$( get-value                '.publisher.idp.issuer' )"
keyUri="$( get-value                     '.publisher.idp.keyUri' )"
keyJson="$( get-value                    '.publisher.idp.keyJson' )"
keyId="$( get-value                      '.publisher.idp.keyId' )"





# private_key_file="key.pem"
# openssl genrsa -out "${private_key_file}" 2048
# modulus="$( openssl rsa -in "${private_key_file}" -modulus -pubout -noout | sed 's/Modulus=//' | sed 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf | base64 --wrap=0 )"
# exponent="AQAB"
# key_id="key1"

jwks_keys_name="jwks_uri/keys"
openid_config_name=".well-known/openid-configuration"
jwks_keys="${issuer_path}/${jwks_keys_name}"

jwks_keys_json="$( echo "{}"                          | \
  jq --arg x "${issuer_path}"                        '.keys[0].issuer=$x' | \
  jq --arg x "${keyId}"                              '.keys[0].kid=$x'    | \
  jq --arg x "$( echo "${keyJson}" | jq -r '.kty' )" '.keys[0].kty=$x'    | \
  jq --arg x "$( echo "${keyJson}" | jq -r '.e' )"   '.keys[0].e=$x'      | \
  jq --arg x "$( echo "${keyJson}" | jq -r '.n' )"   '.keys[0].n=$x'      | \
  jq -c -M "." | iconv --from-code=ascii --to-code=utf-8 )"

openid_config_json="$( \
  echo '{"issuer":"","token_endpoint":"","jwks_uri":"","id_token_signing_alg_values_supported":["RS256"],"token_endpoint_auth_methods_supported":["client_secret_post"],"response_modes_supported":["form_post"],"response_types_supported":["id_token"],"scopes_supported":["openid"],"claims_supported":["sub","iss","aud","exp","iat","name"]}' | \
  jq --arg x "${issuer_path}"  '.issuer=$x'         | \
  jq --arg x "${issuer_path}"  '.token_endpoint=$x' | \
  jq --arg x "${jwks_keys}"    '.jwks_uri=$x'       | \
  jq -c -M "." | iconv --from-code=ascii --to-code=utf-8 )"

az storage blob upload \
  --overwrite --no-progress \
  --account-name "${idp_storage_account_name}" --container-name "${idp_storage_container_name}" \
  --content-type "application/json" \
  --name "${jwks_keys_name}" --data "${jwks_keys_json}"

az storage blob upload \
  --overwrite \
  --account-name "${idp_storage_account_name}" --container-name "${idp_storage_container_name}" \
  --content-type "application/json" \
  --name "${openid_config_name}" --data "${openid_config_json}"
