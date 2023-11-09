#!/bin/bash

trap "exit 1" TERM
export TOP_PID=$$
source "$( dirname "$( readlink -f "$0" )" )/dependencies/state-handling.sh"

put-value '.publisher.subscriptionId'  "$( az account show | jq -r '.id' )"
put-value '.publisher.aadTenantId'     "$( az account show | jq -r '.tenantId' )"
put-value '.publisher.resourceGroup'   "customer-connection"
