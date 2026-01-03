output "logic_app_id" {
  description = "The ID of the created Logic App"
  value       = azurerm_logic_app_workflow.apim_aoai_monitoring.id
}

output "logic_app_name" {
  description = "The name of the created Logic App"
  value       = azurerm_logic_app_workflow.apim_aoai_monitoring.name
}

output "logic_app_endpoint" {
  description = "The endpoint URL of the Logic App"
  value       = azurerm_logic_app_workflow.apim_aoai_monitoring.id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = data.azurerm_resource_group.rg.name
}

output "resource_group_id" {
  description = "The ID of the resource group"
  value       = data.azurerm_resource_group.rg.id
}

output "logic_app_access_endpoint" {
  description = "Logic App HTTP trigger endpoint"
  value       = try(azurerm_logic_app_trigger_http_request.devops_alert.callback_url, "")
  sensitive   = true
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    logic_app_name        = azurerm_logic_app_workflow.apim_aoai_monitoring.name
    resource_group        = data.azurerm_resource_group.rg.name
    location              = data.azurerm_resource_group.rg.location
    recurrence_frequency  = var.recurrence_frequency
    recurrence_interval   = var.recurrence_interval
    log_analytics_workspace_id = var.log_analytics_workspace_id
    azure_devops_project  = var.azure_devops_project_name
    teams_channel_id      = var.teams_channel_id
    email_recipients      = var.email_recipients
  }
}
