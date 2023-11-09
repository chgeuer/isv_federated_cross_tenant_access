#!/bin/bash


subject="$1"
idp="$( cat ./isv-configuration/config.json | jq -r '.publisher.idp.issuer' )"

echo "{}"                                  | \
  jq --arg x "${subject}"                  '.subject=$x'      | \
  jq --arg x "${idp}"                      '.issuer=$x'       | \
  jq --arg x "api://AzureADTokenExchange"  '.audience=$x'     | \
  jq -c -M "." | iconv --from-code=ascii --to-code=utf-8      | \
  jq . > ./federatedIdentityCredentialConfiguration.json

cd setup && ./build.sh