# Implementation Guide - Azure SecOps Automation

## Table of Contents
- [Project Timeline](#project-timeline)
- [Problem Statement](#problem-statement)
- [Solution Evolution](#solution-evolution)
- [Implementation Details](#implementation-details)
- [Troubleshooting Journey](#troubleshooting-journey)
- [Deployment Process](#deployment-process)
- [Testing & Validation](#testing--validation)
- [Lessons Learned](#lessons-learned)

## Project Timeline

### Phase 1: Initial Approach (Terraform)
**Duration**: Day 1  
**Goal**: Infrastructure as Code deployment

**Attempts**:
- Terraform configuration for Logic App
- Variable-based configuration
- State management setup

**Outcome**: ❌ Complexity with Logic App connector definitions

### Phase 2: Bicep Exploration
**Duration**: Day 1-2  
**Goal**: Native Azure template language

**Attempts**:
- Bicep module development
- Parameter file creation
- Azure CLI deployment

**Outcome**: ❌ Template validation errors

### Phase 3: ARM Template Direct Deployment
**Duration**: Day 2  
**Goal**: JSON-based ARM template

**Attempts**:
- Manual ARM template creation
- Azure Portal export as reference
- Python script for template generation

**Outcome**: ✅ Successful deployment

### Phase 4: DevOps Connector Debugging
**Duration**: Day 2-3  
**Goal**: Work Item creation via connector

**Issue Encountered**:
```
Code: NotFound
Message: The API 'visualstudioteamservices' operation 'CreateWorkItem' is not found.
```

**Root Cause**: API connector definition mismatch

**Outcome**: ❌ Connector approach abandoned

### Phase 5: HTTP Action Implementation
**Duration**: Day 3  
**Goal**: Direct REST API call

**Key Decision**: Replace connector with HTTP action  
**Authentication**: Managed Identity  
**Outcome**: ✅ Production deployment success

### Phase 6: Schedule Optimization
**Duration**: Day 3  
**Goal**: Adjust from 5-minute to daily execution

**Change**: Recurrence trigger with timezone  
**Outcome**: ✅ Daily 7 AM KST execution

### Phase 7: Project Cleanup & Documentation
**Duration**: Day 3  
**Goal**: Remove technical debt and modernize documentation

**Actions**:
- Deleted 30 obsolete files (Terraform, Bicep, intermediates)
- Standardized file names
- Created comprehensive documentation

**Outcome**: ✅ Production-ready repository

## Problem Statement

### Business Requirement
Monitor Azure API Management (APIM) gateway logs for errors and automatically create incident tickets in Azure DevOps with multi-channel notifications.

### Technical Challenges
1. **Connector Limitations**: Pre-built DevOps connector unreliable
2. **Authentication Complexity**: Avoid PAT tokens and secrets
3. **Scheduling Precision**: Timezone-aware daily execution
4. **Error Handling**: Conditional logic for error presence

### Success Criteria
- ✅ Automated error detection (24-hour window)
- ✅ DevOps Work Item creation without manual intervention
- ✅ Teams and Email notifications
- ✅ Secure authentication (Managed Identity)
- ✅ Daily execution at specific time (7 AM KST)

## Solution Evolution

### Approach 1: Terraform
**File Structure**:
```
main.tf
variables.tf
outputs.tf
locals.tf
terraform.tfvars
```

**Challenges**:
- Complex syntax for Logic App definition
- State management overhead
- Connector authorization manual step

**Why Abandoned**: Terraform not ideal for single-resource Logic App deployments

### Approach 2: Bicep
**File Structure**:
```
main.bicep
logicapp.bicep
main.bicepparam
logicapp.bicepparam
```

**Challenges**:
- Template validation errors
- API version compatibility
- Limited examples for Logic App connectors

**Why Abandoned**: Validation errors blocking deployment

### Approach 3: ARM Template (Final)
**File Structure**:
```
logicapp-deployment.json (parameterized template)
parameters.example.json (template for user config)
generate-template.py (Python build script)
```

**Advantages**:
- ✅ Native Azure format
- ✅ Portal-compatible
- ✅ Well-documented schema
- ✅ Proven deployment success

### Approach 4: Connector → HTTP Transition

#### Original (Connector-Based)
```json
{
  "type": "ApiConnection",
  "inputs": {
    "host": {
      "connection": {
        "name": "@parameters('$connections')['visualstudioteamservices']['connectionId']"
      }
    },
    "path": "/v3/workitems/create/..."
  }
}
```

**Issue**: Connector definition not found in Azure

#### Final (HTTP-Based)
```json
{
  "type": "Http",
  "inputs": {
    "method": "POST",
    "uri": "https://dev.azure.com/{org}/{project}/_apis/wit/workitems/$Issue?api-version=7.0",
    "headers": {
      "Content-Type": "application/json-patch+json"
    },
    "authentication": {
      "type": "ManagedServiceIdentity",
      "audience": "499b84ac-1321-427f-aa17-267ca6975798"
    },
    "body": [...]
  }
}
```

**Advantages**:
- ✅ Direct REST API control
- ✅ Managed Identity authentication
- ✅ No connector dependencies
- ✅ Predictable behavior

## Implementation Details

### Step 1: ARM Template Design

**Key Parameters**:
```json
{
  "logicAppName": "string",
  "devOpsOrganization": "string",
  "devOpsProject": "string",
  "lawWorkspaceId": "string (GUID)",
  "devOpsAssignee": "string (email)",
  "emailRecipient": "string (email)",
  "teamsGroupId": "string (GUID)",
  "teamsChannelId": "string",
  "scheduleTimeZone": "string",
  "scheduleHour": "string"
}
```

### Step 2: Query Development

**KQL Query**:
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| extend KST = TimeGenerated + 9h
| where ResponseCode != 200
| project KST, TimeGenerated, CorrelationId, ApiId, OperationId, 
          ResponseCode, BackendResponseCode, CallerIpAddress, Method, Url, LastErrorMessage
| order by TimeGenerated desc
| take 50
```

**Key Features**:
- 24-hour lookback window
- KST timezone conversion
- Non-200 response filtering
- Top 50 results (performance)

### Step 3: Managed Identity Configuration

**Logic App Identity**:
```bash
# Enable System-Assigned Identity
az logic workflow show --name logicapp-apim-aoai-monitoring \
  --resource-group RG-ZBHO-DW9-APIM-AOAI-DEMO \
  --query "identity.principalId" -o tsv
```

**Grant Permissions**:
```bash
# Log Analytics Reader
az role assignment create \
  --assignee <identity-principal-id> \
  --role "Log Analytics Reader" \
  --scope /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace}

# Azure DevOps (manual setup required)
# Navigate to: https://dev.azure.com/{org}/{project}/_settings/security
# Add Logic App identity with "Contributor" or "Work Item Writer" role
```

### Step 4: DevOps Work Item Creation

**HTTP Action Configuration**:
```json
{
  "method": "POST",
  "uri": "https://dev.azure.com/{org}/{project}/_apis/wit/workitems/$Issue?api-version=7.0",
  "headers": {
    "Content-Type": "application/json-patch+json"
  },
  "authentication": {
    "type": "ManagedServiceIdentity",
    "audience": "499b84ac-1321-427f-aa17-267ca6975798"
  },
  "body": [
    {
      "op": "add",
      "path": "/fields/System.Title",
      "value": "@{concat('APIM Error - ', body('Query_APIM_Logs')?.tables?[0]?.rows?[0]?[4])}"
    },
    {
      "op": "add",
      "path": "/fields/System.Description",
      "value": "<h2>Error Details</h2>..."
    },
    {
      "op": "add",
      "path": "/fields/System.AssignedTo",
      "value": "user@example.com"
    },
    {
      "op": "add",
      "path": "/fields/Microsoft.VSTS.Common.Priority",
      "value": 2
    }
  ]
}
```

**Critical Details**:
- Content-Type MUST be `application/json-patch+json`
- Audience MUST be `499b84ac-1321-427f-aa17-267ca6975798` (Azure DevOps resource ID)
- Body format: JSON Patch array

### Step 5: Schedule Configuration

**Recurrence Trigger**:
```json
{
  "recurrence": {
    "frequency": "Day",
    "interval": 1,
    "timeZone": "Korea Standard Time",
    "schedule": {
      "hours": ["7"],
      "minutes": [0]
    }
  },
  "type": "Recurrence"
}
```

**Supported Timezones**: [Microsoft timezone list](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones)

## Troubleshooting Journey

### Issue 1: Connector NotFound Error
**Symptom**:
```json
{
  "code": "NotFound",
  "message": "The API 'visualstudioteamservices' operation 'CreateWorkItem' is not found."
}
```

**Investigation**:
1. Checked API connection definition
2. Verified connector availability in region
3. Reviewed Azure Portal connector list

**Solution**: Switch to HTTP action with REST API

### Issue 2: UTF-8 BOM Encoding
**Symptom**:
```
json.decoder.JSONDecodeError: Unexpected UTF-8 BOM
```

**Root Cause**: Python script writing file with BOM

**Solution**:
```python
# Change encoding
with open('template.json', 'w', encoding='utf-8-sig') as f:
    json.dump(template, f, indent=2, ensure_ascii=False)
```

### Issue 3: Duplicate Action Name
**Symptom**:
```
InvalidTemplate: The template action 'Create_DevOps_Work_Item' is defined multiple times
```

**Root Cause**: Python script appending action without deleting old one

**Solution**:
```python
# Delete old action before adding new
if 'Create_DevOps_Work_Item' in template['resources'][3]['properties']['definition']['actions']:
    del template['resources'][3]['properties']['definition']['actions']['Create_DevOps_Work_Item']
```

### Issue 4: Managed Identity 401 Unauthorized
**Symptom**: HTTP 401 when calling DevOps API

**Root Cause**: Logic App identity not granted DevOps permissions

**Solution**:
```bash
# Manual step required
1. Navigate to: https://dev.azure.com/{org}/{project}/_settings/security
2. Add Logic App System-Assigned Identity
3. Grant "Contributor" or "Work Item Writer" role
```

## Deployment Process

### Prerequisites
```bash
# Azure CLI
az --version  # 2.50.0+

# PowerShell (Windows)
$PSVersionTable.PSVersion  # 7.0+

# Python (for template generation)
python --version  # 3.11+
```

### Step-by-Step Deployment

#### 1. Clone Repository
```bash
git clone https://github.com/zer0big/azure-secops-automation-demo.git
cd azure-secops-automation-demo
```

#### 2. Configure Parameters
```bash
# Copy example file
cp parameters.example.json parameters.json

# Edit with your values
notepad parameters.json  # Windows
nano parameters.json     # Linux/Mac
```

**Required Values**:
- `logicAppName`: Your Logic App name
- `devOpsOrganization`: Your DevOps org
- `devOpsProject`: Your DevOps project
- `lawWorkspaceId`: Log Analytics Workspace GUID
- `devOpsAssignee`: Email address
- `emailRecipient`: Alert email
- `teamsGroupId`: Teams Group GUID
- `teamsChannelId`: Teams Channel ID

#### 3. Deploy ARM Template
```bash
az login
az account set --subscription "YOUR-SUBSCRIPTION-NAME"

az deployment group create \
  --resource-group "YOUR-RESOURCE-GROUP" \
  --template-file logicapp-deployment.json \
  --parameters @parameters.json \
  --name "LogicApp-Deployment-$(date +%Y%m%d%H%M%S)"
```

**Expected Output**:
```json
{
  "properties": {
    "provisioningState": "Succeeded",
    "duration": "PT2.15S"
  }
}
```

#### 4. Authorize API Connections
```bash
# Open Azure Portal
# Navigate to: Resource Groups > YOUR-RG > Connections
# For each connection (teams, outlook):
#   - Click connection name
#   - Click "Edit API connection"
#   - Click "Authorize"
#   - Sign in with your account
```

#### 5. Configure Managed Identity Permissions

**Log Analytics**:
```bash
# Get Logic App Principal ID
PRINCIPAL_ID=$(az logic workflow show \
  --name YOUR-LOGICAPP-NAME \
  --resource-group YOUR-RG \
  --query "identity.principalId" -o tsv)

# Assign Log Analytics Reader role
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Log Analytics Reader" \
  --scope /subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}
```

**Azure DevOps** (manual):
1. Navigate to: https://dev.azure.com/{org}/{project}/_settings/security
2. Click "Add" > "Add Azure Active Directory user or group"
3. Search for Logic App name
4. Select and grant "Contributor" role

#### 6. Test Execution
```bash
# Manual trigger
az rest \
  --method POST \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/triggers/Recurrence/run?api-version=2016-06-01"

# Check run history
az rest \
  --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs?api-version=2016-06-01" \
  | jq '.value[0].properties | {status, startTime, endTime}'
```

## Testing & Validation

### Unit Tests

#### 1. Log Analytics Query Test
```bash
# Direct API call
curl -X POST "https://api.loganalytics.io/v1/workspaces/{workspace-id}/query" \
  -H "Authorization: Bearer $(az account get-access-token --resource=https://api.loganalytics.io --query accessToken -o tsv)" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ApiManagementGatewayLogs | where TimeGenerated > ago(24h) | take 10"
  }'
```

#### 2. DevOps Work Item Creation Test
```bash
# Direct API call with Managed Identity token
TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)

curl -X POST "https://dev.azure.com/{org}/{project}/_apis/wit/workitems/\$Issue?api-version=7.0" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json-patch+json" \
  -d '[
    {"op":"add","path":"/fields/System.Title","value":"Test Issue"},
    {"op":"add","path":"/fields/System.Description","value":"Test Description"}
  ]'
```

### Integration Tests

#### Generate Test Errors
```powershell
# Get APIM Gateway URL
$apim = az apim show --name YOUR-APIM-NAME --resource-group YOUR-RG | ConvertFrom-Json
$gateway = $apim.gatewayUrl

# Generate 5 x 404 errors
1..5 | ForEach-Object {
    Invoke-WebRequest -Uri "$gateway/non-existent-endpoint-$_" -Method GET -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

# Wait for Log Analytics ingestion
Start-Sleep -Seconds 60

# Trigger Logic App manually
az rest --method POST --uri "https://management.azure.com/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{name}/triggers/Recurrence/run?api-version=2016-06-01"
```

### Validation Checklist
- ✅ Query returns error logs
- ✅ Teams message posted
- ✅ Email received
- ✅ DevOps Work Item created with correct fields
- ✅ Logic App run status: Succeeded
- ✅ All actions show green checkmark

## Lessons Learned

### 1. Connectors Are Not Always Reliable
**Learning**: Pre-built connectors can have regional availability issues or API definition mismatches.  
**Recommendation**: For critical workflows, use HTTP actions with direct REST API calls.

### 2. Managed Identity > PAT Tokens
**Learning**: Managed Identity eliminates secret management and provides automatic rotation.  
**Recommendation**: Always prefer Managed Identity when available.

### 3. ARM Templates > Terraform/Bicep for Single Resources
**Learning**: For simple deployments (1-2 resources), ARM templates are faster and more reliable.  
**Recommendation**: Use IaC tools (Terraform/Bicep) for complex multi-resource deployments.

### 4. Timezone Awareness Matters
**Learning**: UTC-only schedules cause confusion for users in different timezones.  
**Recommendation**: Always specify timezone explicitly in Recurrence triggers.

### 5. JSON Patch Format is Strict
**Learning**: DevOps Work Item API requires exact `application/json-patch+json` content type.  
**Recommendation**: Read API documentation carefully; content-type matters.

### 6. Python UTF-8 Encoding Gotchas
**Learning**: Default UTF-8 encoding can include BOM, breaking JSON parsers.  
**Recommendation**: Use `encoding='utf-8-sig'` for JSON file generation.

### 7. Documentation is Critical
**Learning**: Complex integrations require comprehensive documentation for maintenance.  
**Recommendation**: Document architecture, implementation, and troubleshooting steps.

---

**Document Version**: 1.0  
**Last Updated**: January 3, 2026  
**Contributors**: Azure SecOps Team
