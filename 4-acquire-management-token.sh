#!/bin/bash

trap "exit 1" TERM
export TOP_PID=$$
source "$( dirname "$( readlink -f "$0" )" )/dependencies/state-handling.sh"

if [ $# -ne 3 ]; then 
  echo "Specify the following parameters: 
  1: file where the local token is stored
     Example: ./token.json
  2: tenant id of the customer
  3: ID of the uami

      $0 subject ./token.json
  "
  exit 1
fi

file="$1"
customer_tenant_id="$2"
uami_id="$3"
                      
self_issued_jwt="$( cat "${file}" )"

echo "${self_issued_jwt}" | jq -R 'split(".") | (.[0], .[1]) | @base64d | fromjson'

audience="https://management.azure.com/"



customer_access_token="$( curl \
  --silent \
  --request POST \
  --url "https://login.microsoftonline.com/${customer_tenant_id}/oauth2/token" \
  --data-urlencode "resource=${audience}"         \
  --data-urlencode "response_type=token" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
  --data-urlencode "client_id=${uami_id}" \
  --data-urlencode "client_assertion=${self_issued_jwt}" \
  | jq -r ".access_token" )" 

echo "${customer_access_token}" | jq -R 'split(".") | (.[0], .[1]) | @base64d | fromjson'
