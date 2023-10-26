targetScope = 'tenant'

@description('The deployment location for the managed identity')
param location string = deployment().location

@description('The subscription ID to deploy the managed identity to')
param subscriptionId string = '9838302b-c9ac-4e97-8b61-101b52f6b961'

@description('The name of the resource group to put the managed identity in')
param resourceGroupName string = 'rg-identity'

@description('The name of the user-assigned managed identity')
param identityName string = 'federated-management-uami'

// @description('The OIDC issuer URL of the federated credential provider')
// param issuerUrl string

// @description('The OIDC subject name for the federated credential')
// param sub string

// @description('The audience for the federated credential')
// param aud string = 'api://AzureADTokenExchange'

var oidcConfiguration = loadJsonContent('../federatedIdentityCredentialConfiguration.json')

module resourceGroupModule './nestedTemplates/0-resourceGroup.bicep' = {
  name: 'resourceGroupDeployment'
  scope: subscription(subscriptionId)
  params: {
    location: location
    name: resourceGroupName
  }
}

module managedIdentityModule './nestedTemplates/1-managedIdentity.bicep' = {
  name: 'managedIdentityDeployment'
  dependsOn: [
    resourceGroupModule
  ]
  scope: resourceGroup(subscriptionId, resourceGroupName)
  params: {
    location: location
    identityName: identityName
    aud: oidcConfiguration.audience
    issuerUrl: oidcConfiguration.issuer
    sub: oidcConfiguration.subject
  }
}

module rbacModule './nestedTemplates/2-managementGroupRBAC.bicep' = {
   name: 'rbacDeploymentToTenantRootManagementGroup'
   scope: managementGroup(tenant().tenantId)
   params: {
    managementGroupId: tenant().tenantId
    principalId: managedIdentityModule.outputs.uami.object_id
   }
}

output managedIdentityId string = managedIdentityModule.outputs.uami.identityId
output managementGroup string = rbacModule.outputs.rbacDetails.managementGroupId
output informationForTheISV object = {
  uami_client_id: managedIdentityModule.outputs.uami.client_id
  uami_tenant_id: managedIdentityModule.outputs.uami.tenant_id
  token_details: managedIdentityModule.outputs.uami.federated
}
