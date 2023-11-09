#!/bin/bash

trap "exit 1" TERM
export TOP_PID=$$
source "$( dirname "$( readlink -f "$0" )" )/dependencies/state-handling.sh"

if [ $# -ne 2 ]; then 
  echo "Specify the following parameters: 
  1: file where to store the token
     Example: ./token.json

      $0 subject ./token.json
  "
  exit 1
fi

subject="$1"
file="$2"

function create_base64_url {
    local base64text="$1"
    echo -n "${base64text}" | sed -E s%=+$%% | sed s%\+%-%g | sed -E s%/%_%g 
}

function json_to_base64 {
    local jsonText="$1"
    create_base64_url "$( echo -n "${jsonText}" | base64 --wrap=0 )"
}

function date_readable {
  local dateTime="$1"
  dateTime="${dateTime//:/-}"
  dateTime="${dateTime/T/--}"
  dateTime="${dateTime/Z/}"
  echo "${dateTime}"
}

# `jq -c -M` gives a condensed/Monochome(no ANSI codes) representation
header="$( echo "{}"                                                   | \
  jq --arg x "JWT"                                           '.typ=$x' | \
  jq --arg x "RS256"                                         '.alg=$x' | \
  jq --arg x "$( get-value-or-fail '.publisher.idp.keyId' )" '.kid=$x' | \
  jq -c -M "." | iconv --from-code=ascii --to-code=utf-8 )"

token_validity_duration="+60 minute"

audience="api://AzureADTokenExchange"

payload="$( echo "{}" | \
  jq --arg x "$( get-value-or-fail '.publisher.idp.issuer' )"    '.iss=$x'              | \
  jq --arg x "${audience}"                             '.aud=$x'              | \
  jq --arg x "${subject}"                                 '.sub=$x'              | \
  jq --arg x "$( date +%s )"                                     '.iat=($x | fromjson)' | \
  jq --arg x "$( date --date="${token_validity_duration}" +%s )" '.exp=($x | fromjson)' | \
  jq -c -M "." | iconv --from-code=ascii --to-code=utf-8 )"

# echo "$(echo "${header}" | jq . ).$(echo "${payload}" | jq . )"

toBeSigned="$( echo -n "$( json_to_base64 "${header}" ).$( json_to_base64 "${payload}" )" | iconv --to-code=ascii )"

hash="$( echo -n "${toBeSigned}" | openssl dgst -sha256 --binary | base64 --wrap=0 )"    

kvAccessToken="$( az account get-access-token --resource "https://vault.azure.net" | jq -r .accessToken )"

# RSASSA-PKCS1-v1_5 using SHA-256 
signature="$( curl \
  --request POST \
  --silent \
  --url "$( get-value-or-fail '.publisher.idp.keyId' )/sign?api-version=7.3" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer ${kvAccessToken}" \
  --data "$( echo "{}" \
       | jq --arg x "RS256" '.alg=$x' \
       | jq --arg x "${hash}" '.value=$x' 
     )" \
  | jq -r '.value' )"
                      
self_issued_jwt="${toBeSigned}.${signature}"

echo "${self_issued_jwt}" | jq -R 'split(".") | (.[0], .[1]) | @base64d | fromjson'

echo "${self_issued_jwt}" > "${file}"

# audience="20e940b3-4c77-4b0b-9a53-9e16a1b010a7"

# customer_access_token="$( curl \
#   --silent \
#   --request POST \
#   --url "https://login.microsoftonline.com/${customer_tenant_id}/oauth2/token" \
#   --data-urlencode "resource=${audience}"         \
#   --data-urlencode "response_type=token" \
#   --data-urlencode "grant_type=client_credentials" \
#   --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
#   --data-urlencode "client_id=${uami_id}" \
#   --data-urlencode "client_assertion=${self_issued_jwt}" \
#   | jq -r ".access_token" )" 

#echo "${isv_metering_access_token}" | jq -R 'split(".") | (.[0], .[1]) | @base64d | fromjson'

#marketplace_metering_response="$( curl \
#  --include --no-progress-meter \
#  --request POST \
#  --url "https://marketplaceapi.microsoft.com/api/usageEvent?api-version=2018-08-31" \
#  --header "Content-Type: application/json" \
#  --header "Authorization: Bearer ${isv_metering_access_token}" \
#  --data "${marketplace_metering_request}" )" 
