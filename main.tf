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

# User Assigned Identity for Logic App
resource "azurerm_user_assigned_identity" "logic_app_identity" {
  location            = data.azurerm_resource_group.rg.location
  name                = "${var.logic_app_name}-identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags
}

# Role Assignment - Log Analytics Reader
resource "azurerm_role_assignment" "logic_app_law_reader" {
  scope                = data.azurerm_log_analytics_workspace.law.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.logic_app_identity.principal_id

  depends_on = [
    azurerm_user_assigned_identity.logic_app_identity
  ]
}

# Role Assignment - Resource Group Contributor
resource "azurerm_role_assignment" "logic_app_rg_contributor" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.logic_app_identity.principal_id

  depends_on = [
    azurerm_user_assigned_identity.logic_app_identity
  ]
}

# Logic App Workflow - Minimal definition
resource "azurerm_logic_app_workflow" "apim_aoai_monitoring" {
  name                = var.logic_app_name
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags

  depends_on = [
    azurerm_user_assigned_identity.logic_app_identity,
    azurerm_role_assignment.logic_app_law_reader,
    azurerm_role_assignment.logic_app_rg_contributor
  ]
}
