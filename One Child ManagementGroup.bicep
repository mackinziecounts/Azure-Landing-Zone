//create management groups
param mgNames array = [
  'Child2'
]
@description('Name of your Pseudo-Root Management Group')
param pseudoRootMGName string

resource FoundationMG 'Microsoft.Management/managementGroups@2021-04-01' = [for name in mgNames: {
  name: '${name}${pseudoRootMGName}'
  scope: tenant()
  properties: {
    displayName: '${name}${pseudoRootMGName}'
    details: {
      parent: {
        id: pseudoRootMGName
      }
    }
  }
}]
output FoundationMGIdOut array = [for name in mgNames: '${name}${pseudoRootMGName}']
