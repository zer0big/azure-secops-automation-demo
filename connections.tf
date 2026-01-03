# Logic App 커넥터 연결 리소스

# Teams 커넥터 연결
resource "azurerm_resource_group_template_deployment" "teams_connection" {
  name                = "teams-connection-deploy"
  resource_group_name = data.azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"

  template_spec_version_id = null

  template_content = jsonencode({
    "$schema" = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    resources = [
      {
        type = "Microsoft.Web/connections"
        apiVersion = "2016-06-01"
        name = "teams-connection"
        location = data.azurerm_resource_group.rg.location
        properties = {
          displayName = "Teams"
          api = {
            id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.rg.location}/managedApis/teams"
          }
          parameterValues = {}
        }
      },
      {
        type = "Microsoft.Web/connections"
        apiVersion = "2016-06-01"
        name = "office365-connection"
        location = data.azurerm_resource_group.rg.location
        properties = {
          displayName = "Office 365 Outlook"
          api = {
            id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.rg.location}/managedApis/office365"
          }
          parameterValues = {}
        }
      },
      {
        type = "Microsoft.Web/connections"
        apiVersion = "2016-06-01"
        name = "azuredevops-connection"
        location = data.azurerm_resource_group.rg.location
        properties = {
          displayName = "Azure DevOps"
          api = {
            id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.rg.location}/managedApis/visualstudioteamservices"
          }
          parameterValues = {
            token = "" # 수동 입력 필요
          }
        }
      },
      {
        type = "Microsoft.Web/connections"
        apiVersion = "2016-06-01"
        name = "azuremonitorlogs-connection"
        location = data.azurerm_resource_group.rg.location
        properties = {
          displayName = "Azure Monitor Logs"
          api = {
            id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${data.azurerm_resource_group.rg.location}/managedApis/azuremonitorlogs"
          }
          parameterValues = {}
        }
      }
    ]
    outputs = {
      teamsConnectionId = {
        type = "string"
        value = "[resourceId('Microsoft.Web/connections', 'teams-connection')]"
      }
      office365ConnectionId = {
        type = "string"
        value = "[resourceId('Microsoft.Web/connections', 'office365-connection')]"
      }
      azureDevOpsConnectionId = {
        type = "string"
        value = "[resourceId('Microsoft.Web/connections', 'azuredevops-connection')]"
      }
      azureMonitorLogsConnectionId = {
        type = "string"
        value = "[resourceId('Microsoft.Web/connections', 'azuremonitorlogs-connection')]"
      }
    }
  })
}

# 커넥터 인증 권한 설정
resource "azurerm_role_assignment" "teams_connector_auth" {
  depends_on = [azurerm_resource_group_template_deployment.teams_connection]

  scope              = data.azurerm_resource_group.rg.id
  role_definition_name = "API Connection Operator"
  principal_id       = data.azurerm_client_config.current.object_id
}
