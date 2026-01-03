# APIM 에러 모니터링 및 자동 티켓 생성 시스템

## 📋 시스템 개요

Azure Logic App을 활용하여 APIM 에러를 자동으로 감지하고 Azure DevOps WorkItem을 생성하는 완전 자동화 솔루션입니다.

### 핵심 기능
- ✅ **자동 에러 감지**: 매일 오전 7시 (KST) APIM 에러 로그 조회
- ✅ **WorkItem 자동 생성**: HTTP + Managed Identity 방식으로 Azure DevOps Issue 생성
- ✅ **다중 알림**: Teams, Email 통합 알림
- ✅ **HTML 포맷**: 가독성 높은 에러 정보 표시

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│ Logic App Recurrence Trigger                               │
│ 매일 오전 7시 (Korea Standard Time)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Log Analytics 쿼리 (Query_APIM_Logs)                       │
│ - Workspace: zbho-dw9-law                                  │
│ - 범위: 최근 24시간                                         │
│ - 조건: ResponseCode >= 400                                │
│ - 출력: KST, ResponseCode, URL, CorrelationId, IP, Error  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│ Condition: 에러 존재 여부 체크                              │
│ @greater(length(body('Query_APIM_Logs')?['tables'][0]['rows']), 0)
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼ (YES)
┌─────────────────────────────────────────────────────────────┐
│ ForEach: 각 에러 항목 처리                                  │
│ @body('Query_APIM_Logs')?['tables'][0]['rows']             │
└─────────────────────┬───────────────────────────────────────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
         ▼            ▼            ▼
┌──────────────┐ ┌──────────┐ ┌──────────┐
│ DevOps Issue │ │  Teams   │ │  Email   │
│ HTTP POST    │ │ 메시지   │ │  알림    │
│ Managed ID   │ │ 전송     │ │  발송    │
└──────────────┘ └──────────┘ └──────────┘
```

## 📊 데이터 흐름

### 1. Log Analytics 쿼리
```kql
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| where ResponseCode >= 400
| extend KST = TimeGenerated + 9h
| project 
    KST,
    ResponseCode,
    Url,
    CorrelationId,
    CallerIpAddress,
    LastErrorMessage
| order by TimeGenerated desc
| take 10
```

**출력 예시**:
```json
[
  ["2026-01-03 15:30:45", 404, "/api/v1/users", "abc-123-def", "203.0.113.1", "Resource not found"],
  ["2026-01-03 15:25:12", 500, "/api/v1/orders", "xyz-456-uvw", "198.51.100.2", "Internal server error"]
]
```

### 2. WorkItem 생성 (HTTP POST)

**Endpoint**:
```
POST https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_apis/wit/workitems/$Issue?api-version=7.0
```

**Headers**:
```json
{
  "Authorization": "Bearer {ManagedIdentityToken}",
  "Content-Type": "application/json-patch+json"
}
```

**Body** (JSON Patch 형식):
```json
[
  {
    "op": "add",
    "path": "/fields/System.Title",
    "value": "APIM 에러 감지 - 404 에러 발생"
  },
  {
    "op": "add",
    "path": "/fields/System.Description",
    "value": "<h2>🚨 APIM 에러 상세 정보</h2><table border='1' cellpadding='5'><tr><th>발생 시각 (KST)</th><td>2026-01-03 15:30:45</td></tr><tr><th>Response Code</th><td>404</td></tr><tr><th>Request URL</th><td>/api/v1/users</td></tr><tr><th>Correlation ID</th><td>abc-123-def</td></tr><tr><th>Caller IP</th><td>203.0.113.1</td></tr><tr><th>Error Message</th><td>Resource not found</td></tr></table>"
  },
  {
    "op": "add",
    "path": "/fields/System.AssignedTo",
    "value": "azure-mvp@zerobig.kr"
  },
  {
    "op": "add",
    "path": "/fields/Microsoft.VSTS.Common.Priority",
    "value": 2
  },
  {
    "op": "add",
    "path": "/fields/Microsoft.VSTS.Common.Severity",
    "value": "2 - High"
  }
]
```

### 3. WorkItem 결과
![WorkItem Preview](https://via.placeholder.com/800x400?text=DevOps+WorkItem+Preview)

| 필드 | 값 |
|------|------|
| **ID** | Auto-generated (예: 1234) |
| **Title** | APIM 에러 감지 - 404 에러 발생 |
| **State** | New |
| **Assigned To** | azure-mvp@zerobig.kr |
| **Priority** | 2 (Medium) |
| **Severity** | 2 - High |
| **Description** | HTML 테이블 형식 |
| **Created Date** | 2026-01-03 07:00:00 KST |

## 🔐 인증 및 보안

### Managed Identity 인증
```json
{
  "authentication": {
    "type": "ManagedServiceIdentity",
    "audience": "499b84ac-1321-427f-aa17-267ca6975798"
  }
}
```

**장점**:
- ✅ PAT(Personal Access Token) 불필요
- ✅ 자동 토큰 갱신
- ✅ Azure AD 통합 인증
- ✅ 최소 권한 원칙 적용

### 필요 권한
Logic App의 System-Assigned Managed Identity에 다음 권한 필요:
- **Azure DevOps**: Contributor 또는 Work Item Writer
- **Log Analytics**: Reader

## 📅 스케줄 설정

### 현재 스케줄
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
  }
}
```

### 실행 예정 시각
| 날짜 | 실행 시각 (KST) |
|------|------------------|
| 2026-01-04 | 07:00:00 |
| 2026-01-05 | 07:00:00 |
| 2026-01-06 | 07:00:00 |
| ... | ... |

## 🚀 배포 가이드

### 사전 준비
1. ✅ Azure CLI 설치 및 로그인
2. ✅ Azure Subscription 접근 권한
3. ✅ Resource Group 생성 (RG-ZBHO-DW9-APIM-AOAI-DEMO)
4. ✅ Log Analytics Workspace 생성 (zbho-dw9-law)
5. ✅ Azure DevOps 프로젝트 생성 (prj-ticketGEN-demo-20260103)

### 배포 명령
```powershell
# 1. Azure 로그인
az login
az account set --subscription "3864b016-4594-40ad-a96b-4a08ac96b537"

# 2. Logic App 배포
az deployment group create `
  --resource-group "RG-ZBHO-DW9-APIM-AOAI-DEMO" `
  --template-file logicapp-deployment.json `
  --name "LogicApp-Deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"

# 3. 배포 확인
az resource show `
  -g "RG-ZBHO-DW9-APIM-AOAI-DEMO" `
  --resource-type "Microsoft.Logic/workflows" `
  -n "logicapp-apim-aoai-monitoring" `
  --query "properties.state"
```

### 배포 검증
```powershell
# Trigger 정보 확인
az resource show `
  -g "RG-ZBHO-DW9-APIM-AOAI-DEMO" `
  --resource-type "Microsoft.Logic/workflows" `
  -n "logicapp-apim-aoai-monitoring" `
  --query "properties.definition.triggers.Recurrence.recurrence"

# Managed Identity 확인
az resource show `
  -g "RG-ZBHO-DW9-APIM-AOAI-DEMO" `
  --resource-type "Microsoft.Logic/workflows" `
  -n "logicapp-apim-aoai-monitoring" `
  --query "identity.{type:type, principalId:principalId}"
```

## 🧪 테스트 시나리오

### 1. 수동 트리거 테스트
```powershell
# Logic App 수동 실행
az rest --method POST `
  --uri "https://management.azure.com/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/triggers/Recurrence/run?api-version=2016-06-01"

# 대기 (15초)
Start-Sleep -Seconds 15

# 실행 결과 확인
az rest --method GET `
  --uri "https://management.azure.com/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/runs?api-version=2016-06-01&`$top=1" `
  --query "value[0].properties.{status:status, startTime:startTime}"
```

### 2. APIM 에러 발생 시뮬레이션
```powershell
# APIM Gateway URL 가져오기
$apim = az apim list -g "RG-ZBHO-DW9-APIM-AOAI-DEMO" --query "[0].gatewayUrl" -o tsv

# 404 에러 5회 발생
1..5 | ForEach-Object {
    try {
        Invoke-WebRequest -Uri "$apim/test-error-endpoint-$_" -Method GET -ErrorAction SilentlyContinue
    } catch {
        Write-Host "✅ 404 에러 $_회 발생" -ForegroundColor Green
    }
    Start-Sleep -Milliseconds 500
}

# Log Analytics 반영 대기 (30초)
Start-Sleep -Seconds 30

# Logic App 트리거
az rest --method POST --uri "https://management.azure.com/.../triggers/Recurrence/run?api-version=2016-06-01"
```

### 3. WorkItem 생성 확인
```powershell
# DevOps WorkItems 조회
az boards work-item list `
  --organization "https://dev.azure.com/azure-mvp" `
  --project "prj-ticketGEN-demo-20260103" `
  --query "[-1].{id:id, title:fields.'System.Title', state:fields.'System.State', assignedTo:fields.'System.AssignedTo'.displayName}"
```

## 📊 모니터링 및 로깅

### Logic App Run History
**URL**: [Azure Portal - Run History](https://portal.azure.com/#resource/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/runHistory)

**확인 항목**:
- ✅ 실행 시각
- ✅ 실행 상태 (Succeeded/Failed/Running)
- ✅ 실행 시간
- ✅ 각 액션 상태

### DevOps WorkItems
**URL**: [Azure DevOps - Work Items](https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_workitems/recentlyupdated/)

**확인 항목**:
- ✅ 생성된 Issue 목록
- ✅ 담당자 할당 상태
- ✅ Priority/Severity
- ✅ Description HTML 렌더링

### Log Analytics 쿼리
```kql
// 최근 실행된 쿼리 조회
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| where ResponseCode >= 400
| summarize Count=count() by ResponseCode
| order by Count desc
```

## 🛠️ 트러블슈팅

### 문제 1: WorkItem 생성 실패 (401 Unauthorized)
**원인**: Managed Identity 권한 부족

**해결**:
1. Azure Portal → Logic App → Identity
2. Principal ID 복사
3. Azure DevOps → Project Settings → Security
4. Add → 검색 (Principal ID) → Contributor 권한 부여

### 문제 2: 쿼리 결과 없음 (에러 발생했는데도)
**원인**: Log Analytics 반영 지연 (최대 5분)

**해결**:
- 쿼리 범위 확대: `ago(24h)` → `ago(48h)`
- 대기 시간 증가: 30초 → 1분

### 문제 3: Teams 알림 실패
**원인**: Teams Connection 권한 미부여

**해결**:
1. Azure Portal → API Connections → teams
2. Edit API connection
3. Authorize 클릭 → 로그인

## 📚 관련 리소스

### 문서
- [README.md](README.md) - 프로젝트 개요
- [DEVOPS-WORKITEM-GUIDE.md](DEVOPS-WORKITEM-GUIDE.md) - 구현 가이드
- [ADO-WORKITEM-FINAL-REPORT.md](ADO-WORKITEM-FINAL-REPORT.md) - 완료 보고서

### 코드
- [logicapp-deployment.json](logicapp-deployment.json) - ARM 템플릿
- [DevOps-WorkItem-Action.json](DevOps-WorkItem-Action.json) - 액션 스니펫
- [generate-template.py](generate-template.py) - 템플릿 생성 스크립트

### 링크
- [Logic App Designer](https://portal.azure.com/#resource/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/logicDesigner)
- [DevOps Project](https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103)
- [Log Analytics Workspace](https://portal.azure.com/#resource/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.OperationalInsights/workspaces/zbho-dw9-law)

## 📞 지원

- **담당자**: azure-mvp@zerobig.kr
- **Organization**: azure-mvp
- **Project**: prj-ticketGEN-demo-20260103

---

**마지막 업데이트**: 2026-01-03  
**문서 버전**: 2.0  
**배포 상태**: ✅ 프로덕션 운영 중
