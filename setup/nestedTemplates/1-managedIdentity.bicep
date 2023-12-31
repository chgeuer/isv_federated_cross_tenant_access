@description('The deployment location')
param location string = resourceGroup().location

@description('The name of the user-assigned managed identity')
param identityName string

@description('The issuer URL')
param issuerUrl string

@description('The subject name')
param sub string

@description('The audience')
param aud string

@description('A user-assigned managed identity to emit usage.')
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: {
    usage: 'Used to remotely sign-in from the ISV'
  }
  resource federatedCred 'federatedIdentityCredentials' = {
    name: 'fed'
    properties: {
      issuer: issuerUrl
      subject: sub
      audiences: [
        aud
      ]
      // description: 'The ISV/publisher will sign in via a federated credential'
    }
  }
}

resource lockFromDeletion 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${identityName}-deletion-lock'
  scope: identity
  properties: {
    level: 'CanNotDelete'
    notes: 'If you delete this UAMI, then the subscription cannot be managed by the ISV application.'
  }
} 

output uami object = {
  federated: {
    iss: issuerUrl
    aud: aud
    sub: sub
  }
  identityId: identity.id
  tenant_id: subscription().tenantId    
  client_id: identity.properties.clientId
  object_id: identity.properties.principalId
}
