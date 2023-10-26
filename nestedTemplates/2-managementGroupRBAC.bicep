targetScope = 'managementGroup'

@description('The client_id of the user-assigned managed identity')
param principalId string

@description('Management Group')
param managementGroupId string = tenant().tenantId

var roles = {
  Owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: managementGroup()
  name: guid('managementGroup', principalId, managementGroupId, roles.Owner)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', roles.Owner)    
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

// https://github.com/Azure/azure-quickstart-templates/blob/72c7217e3a2682e1065c642abf44c36da5d6b89c/tenant-deployments/tenant-role-assignment/main.bicep

output rbacDetails object = {
  managementGroupId: managementGroupId
  roleAssignmentId: roleAssignment.id
}
