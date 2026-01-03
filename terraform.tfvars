# Azure Resources Configuration
resource_group_name             = "rg-zbho-dw9-apim-aoai-demo"
location                        = "eastus"
logic_app_name                  = "logicapp-apim-aoai-monitoring"

# Log Analytics Configuration
log_analytics_workspace_id      = "7368ebd0-a658-4099-a5c3-2efb28733f5f"
log_analytics_workspace_name    = "zbho-dw9-law"

# Recurrence Configuration
recurrence_frequency            = "Minute"
recurrence_interval             = 5

# Teams Configuration
teams_group_id                  = "b9367993-aa6c-40f3-93c5-e173a5fba3df"
teams_channel_id                = "19:32df97df94214adfa36ab24db8a1a9dc@thread.tacv2"
teams_tenant_id                 = "067db808-c3ee-4430-8135-05f15d0d242f"

# Email Configuration
email_recipients                = ["alert@zerobig.kr", "ops@zerobig.kr"]

# Azure DevOps Configuration
azure_devops_project_name       = "prj-ticketGEN-demo-20260103"
azure_devops_organization       = "azure-mvp"
issue_assignee                  = "azure-mvp@zerobig.kr"

# Tags
tags = {
  Project     = "APIM-AOAI-Monitoring"
  Environment = "Demo"
  ManagedBy   = "Terraform"
  CreatedDate = "2026-01-03"
  Owner       = "ZEROBIG"
}
