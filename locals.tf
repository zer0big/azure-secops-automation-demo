locals {
  kql_query = <<-EOT
ApiManagementGatewayLogs
| where responseCode != "200"
| project TimeGenerated, 
          operationId, 
          apiId, 
          operationName, 
          responseCode, 
          responseCodeReason, 
          requestUri, 
          clientIpAddress, 
          backendResponseCode, 
          backendResponseTime, 
          responseTime
| order by TimeGenerated desc
| take 100
EOT

  common_tags = merge(
    var.tags,
    {
      LastUpdated = timestamp()
    }
  )

  logic_app_workflow_name = "${var.logic_app_name}-flow"
  
  devops_api_url = "https://dev.azure.com/${var.azure_devops_organization}/${var.azure_devops_project_name}/_apis"
}
