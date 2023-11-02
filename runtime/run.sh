#!/bin/bash

customerCfg="../setup/informationForTheISV.json"

aud="$(            jq -r '.token_details.aud' "${customerCfg}" )"
iss="$(            jq -r '.token_details.iss' "${customerCfg}" )"
sub="$(            jq -r '.token_details.sub' "${customerCfg}" )"
uami_client_id="$( jq -r '.uami_client_id'    "${customerCfg}" )"
uami_tenant_id="$( jq -r '.uami_tenant_id'    "${customerCfg}" )"

