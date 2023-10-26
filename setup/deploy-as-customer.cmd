
REM call az.cmd --tenant geuer-pollmann.de

call az.cmd ^
  deployment tenant create ^
  --location westeurope ^
  --parameters location="westeurope" ^
  --parameters subscriptionId="9838302b-c9ac-4e97-8b61-101b52f6b961" ^
  --parameters resourceGroupName="rg-bootstap2" ^
  --parameters identityName="massdriver2" ^
  --template-file main.bicep ^
  | jq ".properties.outputs.informationForTheISV.value" ^
  > informationForTheISV.json
