using './logicapp.bicep'

param location = 'eastus'
param logicAppName = 'logicapp-apim-aoai-monitoring'
param logAnalyticsWorkspaceName = 'zbho-dw9-law'
param userIdentityName = 'logicapp-apim-aoai-monitoring-identity'
param recurrenceFrequency = 'Minute'
param recurrenceInterval = 5
param commonTags = {
  environment: 'production'
  project: 'APIM-AOAI-Monitoring'
  createdDate: '2026-01-03'
}
