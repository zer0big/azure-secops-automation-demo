terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
}

# Get current Azure client config
data "azurerm_client_config" "current" {}

# Get existing Resource Group (data source only - not managed by Terraform)
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Get existing Log Analytics Workspace
data "azurerm_log_analytics_workspace" "law" {
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group_name
}

# Logic App Workflow
resource "azurerm_logic_app_workflow" "apim_aoai_monitoring" {
  name                = var.logic_app_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags

  depends_on = [
    data.azurerm_resource_group.rg
  ]
}

# User Assigned Identity for Logic App
resource "azurerm_user_assigned_identity" "logic_app_identity" {
  location            = data.azurerm_resource_group.rg.location
  name                = "${var.logic_app_name}-identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags
}

# Role Assignment - Log Analytics Reader
resource "azurerm_role_assignment" "logic_app_law_reader" {
  scope              = data.azurerm_log_analytics_workspace.law.id
  role_definition_name = "Log Analytics Reader"
  principal_id       = azurerm_user_assigned_identity.logic_app_identity.principal_id

  depends_on = [
    azurerm_user_assigned_identity.logic_app_identity
  ]
}

# Role Assignment - Resource Group Contributor
resource "azurerm_role_assignment" "logic_app_rg_contributor" {
  scope              = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id       = azurerm_user_assigned_identity.logic_app_identity.principal_id

  depends_on = [
    azurerm_user_assigned_identity.logic_app_identity
  ]
}

# Recurrence Trigger
resource "azurerm_logic_app_trigger_recurrence" "monitor_trigger" {
  name         = "Recurrence"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  frequency    = var.recurrence_frequency
  interval     = var.recurrence_interval

  depends_on = [
    azurerm_logic_app_workflow.apim_aoai_monitoring
  ]
}

# Log Analytics Query Action
resource "azurerm_logic_app_action_custom" "log_analytics_query" {
  name         = "QueryLogAnalytics"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "ApiConnection"
    "inputs" = {
      "host" = {
        "connection" = {
          "name" = "@parameters('$connections')['azuremonitorlogs']['connectionId']"
        }
      }
      "method" = "post"
      "path"   = "/queryAction"
      "body" = {
        "query"          = local.kql_query
        "subscriptionId" = data.azurerm_client_config.current.subscription_id
        "resourcegroups" = ""
        "resourcetypes"  = ""
        "timerange"      = "PT5M"
      }
    }
    "runAfter" = {}
  })

  depends_on = [
    azurerm_logic_app_trigger_recurrence.monitor_trigger
  ]
}

# Condition Check
resource "azurerm_logic_app_action_custom" "condition_check" {
  name         = "ConditionCheckResults"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "If"
    "expression" = {
      "and" = [
        {
          "greater" = [
            "@length(body('QueryLogAnalytics')?['value'])",
            0
          ]
        }
      ]
    }
    "actions" = {}
    "runAfter" = {
      "QueryLogAnalytics" = ["Succeeded"]
    }
  })

  depends_on = [
    azurerm_logic_app_action_custom.log_analytics_query
  ]
}

# For Each Loop
resource "azurerm_logic_app_action_custom" "foreach_results" {
  name         = "ForEachResult"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "Foreach"
    "foreach" = "@body('QueryLogAnalytics')?['value']"
    "actions" = {}
    "runAfter" = {
      "ConditionCheckResults" = ["Succeeded"]
    }
  })

  depends_on = [
    azurerm_logic_app_action_custom.condition_check
  ]
}

# Teams Alert Action
resource "azurerm_logic_app_action_custom" "send_teams_message" {
  name         = "SendTeamsAlert"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "ApiConnection"
    "inputs" = {
      "host" = {
        "connection" = {
          "name" = "@parameters('$connections')['teams']['connectionId']"
        }
      }
      "method" = "post"
      "path"   = "/beta/teams/@{encodeURIComponent('${var.teams_group_id}')}/channels/@{encodeURIComponent('${var.teams_channel_id}')}/messages"
      "body" = {
        "body" = {
          "contentType" = "html"
          "content" = "<h3>APIM Alert</h3><p>Non-200 Response Detected</p>"
        }
      }
    }
    "runAfter" = {}
  })

  depends_on = [
    azurerm_logic_app_action_custom.foreach_results
  ]
}

# Email Alert Action
resource "azurerm_logic_app_action_custom" "send_email_alert" {
  name         = "SendEmailAlert"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "ApiConnection"
    "inputs" = {
      "host" = {
        "connection" = {
          "name" = "@parameters('$connections')['office365']['connectionId']"
        }
      }
      "method" = "post"
      "path"   = "/Mail"
      "body" = {
        "to"      = join(";", var.email_recipients)
        "subject" = "APIM Alert - Non-200 Response"
        "body"    = "<h2>APIM Alert Notification</h2><p>A non-200 response has been detected in your API Management logs.</p>"
      }
    }
    "runAfter" = {
      "SendTeamsAlert" = ["Succeeded"]
    }
  })

  depends_on = [
    azurerm_logic_app_action_custom.send_teams_message
  ]
}

# HTTP Trigger for DevOps
resource "azurerm_logic_app_trigger_http_request" "devops_alert" {
  name         = "HTTPTriggerDevOpsAlert"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  schema = jsonencode({
    "type" = "object"
    "properties" = {
      "AlertName" = {
        "type" = "string"
      }
      "Severity" = {
        "type" = "string"
      }
      "Description" = {
        "type" = "string"
      }
    }
    "required" = ["AlertName", "Severity", "Description"]
  })

  depends_on = [
    azurerm_logic_app_workflow.apim_aoai_monitoring
  ]
}

# Azure DevOps Issue Creation
resource "azurerm_logic_app_action_custom" "create_devops_issue" {
  name         = "CreateDevOpsIssue"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "ApiConnection"
    "inputs" = {
      "host" = {
        "connection" = {
          "name" = "@parameters('$connections')['azuredevops']['connectionId']"
        }
      }
      "method" = "post"
      "path"   = "/v1.0/workitems/@{encodeURIComponent('Issue')}"
      "queries" = {
        "account" = var.azure_devops_organization
        "project" = var.azure_devops_project_name
      }
      "body" = {
        "fields" = {
          "System.Title"       = "APIM Alert: @{triggerBody()?['AlertName']}"
          "System.Description" = "@{triggerBody()?['Description']}"
          "System.AssignedTo"  = var.issue_assignee
        }
      }
    }
    "runAfter" = {}
  })

  depends_on = [
    azurerm_logic_app_trigger_http_request.devops_alert
  ]
}

# Error Handler
resource "azurerm_logic_app_action_custom" "error_handler" {
  name         = "ErrorHandler"
  logic_app_id = azurerm_logic_app_workflow.apim_aoai_monitoring.id
  body = jsonencode({
    "type" = "ApiConnection"
    "inputs" = {
      "host" = {
        "connection" = {
          "name" = "@parameters('$connections')['office365']['connectionId']"
        }
      }
      "method" = "post"
      "path"   = "/Mail"
      "body" = {
        "to"      = join(";", var.email_recipients)
        "subject" = "ERROR: Logic App Execution Failed"
        "body"    = "<h2>Logic App Error</h2><p>The APIM monitoring Logic App failed to execute.</p>"
      }
    }
    "runAfter" = {
      "QueryLogAnalytics" = ["Failed"]
    }
  })

  depends_on = [
    azurerm_logic_app_action_custom.log_analytics_query
  ]
}
