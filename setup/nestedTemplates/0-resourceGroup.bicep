targetScope = 'subscription'

param name string

param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
  properties: {}
}

output rgid string = resourceGroup.id
