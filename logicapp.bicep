metadata name = 'APIM AOAI Monitoring Logic App'

param location string = resourceGroup().location
param logicAppName string = 'logicapp-apim-aoai-monitoring'
param logAnalyticsWorkspaceName string = 'zbho-dw9-law'
param userIdentityName string = 'logicapp-apim-aoai-monitoring-identity'
param recurrenceFrequency string = 'Minute'
param recurrenceInterval int = 5

param commonTags object = {
  environment: 'production'
  project: 'APIM-AOAI-Monitoring'
  createdDate: utcNow('yyyy-MM-dd')
}

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userIdentityName
  location: location
  tags: commonTags
}

resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: commonTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentity.id}': {}
    }
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      'contentVersion': '1.0.0.0'
      'triggers': {
        'Recurrence': {
          'recurrence': {
            'frequency': recurrenceFrequency
            'interval': recurrenceInterval
          }
          'type': 'Recurrence'
        }
      }
      'actions': {}
    }
  }
}

output logicAppId string = logicApp.id
output logicAppName string = logicApp.name
output location string = location
output identityId string = userIdentity.id
