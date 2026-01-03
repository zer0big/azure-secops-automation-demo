variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-zbho-dw9-apim-aoai-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Korea Central"
}

variable "logic_app_name" {
  description = "Name of the Logic App"
  type        = string
  default     = "logicapp-apim-aoai-monitoring"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
  default     = "7368ebd0-a658-4099-a5c3-2efb28733f5f"
}

variable "log_analytics_workspace_name" {
  description = "Log Analytics Workspace Name"
  type        = string
  default     = "zbho-dw9-law"
}

variable "recurrence_frequency" {
  description = "Recurrence frequency (Minute, Hour, Day, Week, Month)"
  type        = string
  default     = "Minute"
}

variable "recurrence_interval" {
  description = "Recurrence interval"
  type        = number
  default     = 5
}

variable "teams_group_id" {
  description = "Teams Group ID"
  type        = string
  default     = "b9367993-aa6c-40f3-93c5-e173a5fba3df"
}

variable "teams_channel_id" {
  description = "Teams Channel ID"
  type        = string
  default     = "19:32df97df94214adfa36ab24db8a1a9dc@thread.tacv2"
}

variable "teams_tenant_id" {
  description = "Teams Tenant ID"
  type        = string
  default     = "067db808-c3ee-4430-8135-05f15d0d242f"
}

variable "email_recipients" {
  description = "Email recipients for alerts"
  type        = list(string)
  default     = ["alert@zerobig.kr", "ops@zerobig.kr"]
}

variable "azure_devops_project_name" {
  description = "Azure DevOps Project Name"
  type        = string
  default     = "prj-ticketGEN-demo-20260103"
}

variable "azure_devops_organization" {
  description = "Azure DevOps Organization"
  type        = string
  default     = "azure-mvp"
}

variable "issue_assignee" {
  description = "Azure DevOps Issue Assignee"
  type        = string
  default     = "azure-mvp@zerobig.kr"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Project     = "APIM-AOAI-Monitoring"
    Environment = "Demo"
    ManagedBy   = "Terraform"
    CreatedDate = "2026-01-03"
  }
}
