# Azure SecOps Automation Demo - System Architecture

## Table of Contents
- [Overview](#overview)
- [System Components](#system-components)
- [Architecture Diagram](#architecture-diagram)
- [Data Flow](#data-flow)
- [Security Architecture](#security-architecture)
- [Integration Points](#integration-points)
- [Scalability & Performance](#scalability--performance)

## Overview

This solution implements automated security operations monitoring for Azure API Management (APIM) services using Azure Logic Apps, with automated incident creation in Azure DevOps.

### Key Features
- ✅ **Automated Error Detection**: 24-hour monitoring of APIM Gateway logs
- ✅ **Multi-Channel Alerting**: Teams, Email, and DevOps Work Items
- ✅ **Managed Identity Authentication**: Zero-secret security model
- ✅ **Daily Scheduled Execution**: Runs at 7 AM KST
- ✅ **REST API Direct Integration**: Bypasses connector limitations

### Architecture Principles
1. **Zero-Secret Design**: All authentication via Managed Identity
2. **Infrastructure as Code**: ARM template-based deployment
3. **Resilience**: Error handling with conditional logic
4. **Observability**: Comprehensive logging and monitoring
5. **Compliance**: Role-based access control (RBAC)

## System Components

### 1. Azure Logic App
**Resource Name**: `logicapp-apim-aoai-monitoring`  
**Purpose**: Orchestration engine for monitoring workflow

**Key Capabilities**:
- Scheduled trigger (Recurrence)
- HTTP actions for API calls
- Conditional branching
- Multi-channel notifications

**Identity**:
- System-Assigned Managed Identity
- Audience: `499b84ac-1321-427f-aa17-267ca6975798` (Azure DevOps)
- Audience: `https://api.loganalytics.io` (Log Analytics)

### 2. Log Analytics Workspace
**Purpose**: Central logging and query platform

**Query Capabilities**:
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

**Data Collected**:
- APIM Gateway Logs
- Response Codes (focusing on non-200)
- Error Messages
- Correlation IDs for tracing

### 3. Azure DevOps
**Purpose**: Incident management and tracking

**Work Item Creation**:
- **Type**: Issue
- **API Version**: 7.0
- **Authentication**: Managed Identity
- **Format**: JSON Patch (application/json-patch+json)

**Fields Populated**:
- System.Title
- System.Description (HTML formatted)
- System.AssignedTo
- Microsoft.VSTS.Common.Priority
- Microsoft.VSTS.Common.Severity

### 4. Microsoft Teams
**Purpose**: Real-time collaboration alerts

**Integration**:
- Channel-based posting
- Adaptive Card format (HTML)
- Group ID and Channel ID required

### 5. Email (Office 365)
**Purpose**: Email notification delivery

**Configuration**:
- SMTP via Office 365 connector
- HTML body support
- High importance flagging

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Logic App                          │
│                 (logicapp-apim-aoai-monitoring)                 │
│                                                                 │
│  ┌──────────────┐                                              │
│  │  Recurrence  │  Daily @ 7:00 AM KST                        │
│  │   Trigger    │                                              │
│  └──────┬───────┘                                              │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────┐                             │
│  │   Query_APIM_Logs (HTTP)    │                             │
│  │                              │                             │
│  │ • URI: Log Analytics API     │──────┐                     │
│  │ • Auth: Managed Identity     │      │                     │
│  │ • Query: 24h APIM errors     │      │                     │
│  └──────┬───────────────────────┘      │                     │
│         │                               │                     │
│         ▼                               │                     │
│  ┌─────────────────────┐               │                     │
│  │ Condition_Check_    │               │                     │
│  │ Errors              │               │                     │
│  │                     │               │                     │
│  │ length(rows) > 0?   │               │                     │
│  └──┬──────────────────┘               │                     │
│     │ YES                              │                     │
│     ├─────────────────┬────────────────┼─────────────┐      │
│     ▼                 ▼                ▼             ▼      │
│  ┌─────────┐    ┌──────────┐   ┌──────────┐  ┌──────────┐ │
│  │ Teams   │    │  Email   │   │ DevOps   │  │ DevOps   │ │
│  │ Alert   │    │  Alert   │   │ Connector│  │   HTTP   │ │
│  │         │    │          │   │ (Legacy) │  │  (NEW)   │ │
│  └─────────┘    └──────────┘   └──────────┘  └──────────┘ │
└─────────────────────────────────────────────────────────────────┘
         │                │               │            │
         ▼                ▼               ▼            ▼
   ┌─────────┐      ┌─────────┐    ┌──────────────────────┐
   │ Teams   │      │ Outlook │    │   Azure DevOps       │
   │ Channel │      │ Inbox   │    │   Work Items         │
   └─────────┘      └─────────┘    └──────────────────────┘
                                             │
                                             ▼
         ┌────────────────────────────────────────────────┐
         │  Log Analytics Workspace                      │
         │  • Query endpoint                             │
         │  • APIM Gateway Logs                          │
         │  • 24-hour retention query                    │
         └────────────────────────────────────────────────┘
```

## Data Flow

### 1. Trigger Phase
```
Time: Daily @ 07:00 AM KST
├─ Recurrence Trigger Fires
└─ Initiates Workflow Execution
```

### 2. Query Phase
```
Action: Query_APIM_Logs
├─ HTTP POST → https://api.loganalytics.io/v1/workspaces/{workspaceId}/query
├─ Authentication: Managed Identity (audience: https://api.loganalytics.io)
├─ Body: KQL query for 24h error logs
└─ Response: JSON table with error records
```

### 3. Evaluation Phase
```
Action: Condition_Check_Errors
├─ Expression: length(body('Query_APIM_Logs')?.tables?[0]?.rows) > 0
├─ TRUE Path: Execute all alert actions
└─ FALSE Path: Workflow completes (no errors)
```

### 4. Notification Phase (if errors detected)
```
Parallel Execution:
├─ Teams Alert
│  ├─ POST to Teams API
│  └─ Channel message with error count
│
├─ Email Alert
│  ├─ POST to Office 365 API
│  └─ HTML email with error details
│
└─ DevOps Work Item (HTTP)
   ├─ POST → https://dev.azure.com/{org}/{project}/_apis/wit/workitems/$Issue
   ├─ Authentication: Managed Identity (audience: 499b84ac-1321-427f...)
   ├─ Body: JSON Patch operations
   └─ Creates Issue with rich HTML description
```

## Security Architecture

### Authentication Model

#### 1. Managed Identity (Primary)
```
Logic App System-Assigned Identity
├─ Azure DevOps API
│  └─ Audience: 499b84ac-1321-427f-aa17-267ca6975798
│
└─ Log Analytics API
   └─ Audience: https://api.loganalytics.io
```

**Advantages**:
- ✅ No secrets to manage
- ✅ Automatic credential rotation
- ✅ Azure AD-integrated
- ✅ Auditable via Azure AD logs

#### 2. API Connections (Connectors)
- Teams: OAuth-based user delegation
- Outlook: OAuth-based user delegation
- DevOps (legacy): OAuth-based, deprecated in favor of HTTP

### Authorization Model

**Required Permissions**:
```
Log Analytics Workspace
├─ Logic App Identity
└─ Role: Log Analytics Reader

Azure DevOps Project
├─ Logic App Identity
└─ Role: Contributor or Work Item Writer

Teams Channel
├─ User Account (Connector)
└─ Permission: Post messages

Outlook
├─ User Account (Connector)
└─ Permission: Send mail
```

### Network Security
- All traffic over HTTPS/TLS 1.2+
- Azure backbone network (no internet exposure)
- Private endpoints (optional, for enhanced security)

## Integration Points

### 1. Log Analytics API
**Endpoint**: `https://api.loganalytics.io/v1/workspaces/{workspaceId}/query`  
**Method**: POST  
**Authentication**: Managed Identity  
**Content-Type**: application/json

**Request Body**:
```json
{
  "query": "ApiManagementGatewayLogs | where TimeGenerated > ago(24h) ..."
}
```

**Response Format**:
```json
{
  "tables": [
    {
      "name": "PrimaryResult",
      "columns": [...],
      "rows": [
        ["2026-01-03T16:00:00Z", "404", "GET", "/api/test", ...]
      ]
    }
  ]
}
```

### 2. Azure DevOps REST API
**Endpoint**: `https://dev.azure.com/{org}/{project}/_apis/wit/workitems/$Issue`  
**API Version**: 7.0  
**Method**: POST  
**Authentication**: Managed Identity  
**Content-Type**: application/json-patch+json

**Request Body (JSON Patch)**:
```json
[
  {
    "op": "add",
    "path": "/fields/System.Title",
    "value": "APIM Error - 404 detected"
  },
  {
    "op": "add",
    "path": "/fields/System.Description",
    "value": "<h2>Error Details</h2>..."
  }
]
```

### 3. Teams Webhook API
**Channel Posting**: Beta API  
**Authentication**: Connector OAuth  
**Format**: HTML message body

### 4. Office 365 Mail API
**Send Mail**: v2 API  
**Authentication**: Connector OAuth  
**Format**: HTML email body

## Scalability & Performance

### Current Configuration
- **Execution Frequency**: Daily (low load)
- **Query Window**: 24 hours
- **Result Limit**: Top 50 errors
- **Timeout**: Default Logic App timeout (PT1H)

### Performance Metrics
- **Average Execution Time**: 5-15 seconds
- **Query Latency**: 2-5 seconds
- **Notification Latency**: 1-3 seconds each

### Scaling Considerations

#### Horizontal Scaling
- Logic App: Auto-scales per execution
- No state management required
- Stateless workflow design

#### Vertical Scaling Options
1. **Increase Query Window**: Change `ago(24h)` to `ago(7d)`
2. **More Frequent Execution**: Change to hourly (not recommended for summary reports)
3. **Parallel Region Deployment**: Multi-region APIM monitoring

### Cost Optimization
- Daily execution minimizes action costs
- Single workflow for multiple notifications
- Managed Identity (no Key Vault costs)
- Query result limiting (top 50)

## Disaster Recovery

### Backup Strategy
- ARM template stored in Git (infrastructure)
- Query definition in template (configuration)
- Parameters file (environment-specific)

### Recovery Procedures
1. Re-deploy from ARM template
2. Re-authorize API connections (Teams, Outlook)
3. Assign Managed Identity permissions
4. Verify first run

### Monitoring & Alerts
- Logic App Run History (Azure Portal)
- Failed run alerts (Azure Monitor)
- Application Insights integration (optional)

## Compliance & Governance

### Audit Trail
- Logic App Run History: 30 days retention
- Azure Activity Log: 90 days retention
- DevOps Work Items: Permanent record
- Email/Teams: Per-organization retention policy

### Data Residency
- Logic App: East US
- Log Analytics: Korea Central (configurable)
- DevOps: Cloud region per organization

### GDPR Considerations
- Email addresses: Personal data
- IP addresses in logs: Personal data
- Retention policy enforcement required

---

**Document Version**: 1.0  
**Last Updated**: January 3, 2026  
**Maintained By**: Azure SecOps Team
