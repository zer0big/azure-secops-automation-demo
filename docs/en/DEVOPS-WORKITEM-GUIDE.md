# Azure DevOps Work Item 생성 액션 - 완성 가이드

## 📋 개요

APIM 에러 로그를 Azure DevOps Issue로 자동 생성하는 Logic App 액션입니다.

## ✅ 핵심 요구사항

- **Organization**: azure-mvp
- **Project**: prj-ticketGEN-demo-20260103  
- **Work Item Type**: Issue
- **AssignedTo**: azure-mvp@zerobig.kr
- **Priority**: 2 (Medium)
- **Severity**: 2 - High
- **URL**: https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_workitems/recentlyupdated/

## 🔧 구현 방식

### 1. HTTP 액션 (REST API 직접 호출)

기존 `visualstudioteamservices` 커넥터의 한계를 우회하기 위해 HTTP 액션으로 DevOps REST API를 직접 호출합니다.

**에러 분석**:
```
"code": "NotFound",
"message": "Unable to initialize operation details for swagger based operation - Create_DevOps_Work_Item. 
            Error details - Operation Id cannot be determined from definition and swagger...."
```

**해결책**: Managed Identity 인증으로 HTTP POST 요청

### 2. 인증 방식

- **Managed Identity 인증**: PAT (Personal Access Token) 불필요!
- Logic App의 System Assigned Identity 사용
- DevOps 프로젝트에 Identity 권한 부여 필요

### 3. API 스펙

```
POST https://dev.azure.com/{organization}/{project}/_apis/wit/workitems/$Issue?api-version=7.0
Content-Type: application/json-patch+json
```

## 📊 데이터 매핑

### Title 필드
```
APIM 에러 감지 - {ResponseCode} 에러 발생
```

**Expression**:
```json
"@{concat('APIM 에러 감지 - ', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[4], ' 에러 발생')}"
```

### Description 필드 (HTML 포맷)

**데이터 포함**:
- 발생 시간 (KST): `body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[0]`
- Response Code: `body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[4]`
- URL: `body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[9]`
- CorrelationId: `body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[2]`
- Caller IP: `body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[7]`
- Error Message: `body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[10]`
- 총 에러 건수: `length(body('Query_APIM_Logs')?['tables']?[0]?['rows'])`

**HTML 템플릿**:
```html
<h2>🔴 APIM 에러 알림</h2>
<table border="1" cellpadding="5">
  <tr><th>항목</th><th>값</th></tr>
  <tr><td><b>발생 시간 (KST)</b></td><td>{KST}</td></tr>
  <tr><td><b>Response Code</b></td><td>{ResponseCode}</td></tr>
  <tr><td><b>URL</b></td><td>{URL}</td></tr>
  <tr><td><b>CorrelationId</b></td><td>{CorrelationId}</td></tr>
  <tr><td><b>Caller IP</b></td><td>{CallerIP}</td></tr>
  <tr><td><b>Error Message</b></td><td>{ErrorMessage}</td></tr>
</table>
<br/>
<h3>총 감지된 에러: {ErrorCount} 건</h3>
```

## 💻 완성 JSON 스니펫

파일: [DevOps-WorkItem-Action.json](DevOps-WorkItem-Action.json)

```json
{
  "Create_DevOps_Work_Item_HTTP": {
    "type": "Http",
    "inputs": {
      "method": "POST",
      "uri": "https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_apis/wit/workitems/$Issue?api-version=7.0",
      "headers": {
        "Content-Type": "application/json-patch+json"
      },
      "authentication": {
        "type": "ManagedServiceIdentity"
      },
      "body": [
        {
          "op": "add",
          "path": "/fields/System.Title",
          "value": "@{concat('APIM 에러 감지 - ', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[4], ' 에러 발생')}"
        },
        {
          "op": "add",
          "path": "/fields/System.Description",
          "value": "@{concat('<h2>🔴 APIM 에러 알림</h2>...')}"
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
    },
    "runAfter": {
      "Condition_Check_Errors": ["Succeeded"]
    }
  }
}
```

## 🚀 배포 방법

### 옵션 1: ARM 템플릿 배포 (자동화)

```powershell
az deployment group create \
  --resource-group "RG-ZBHO-DW9-APIM-AOAI-DEMO" \
  --template-file deploy-devops-http.json \
  --name "LogicApp-DevOpsHTTP-Final"
```

### 옵션 2: Logic App Designer (수동)

1. Logic App Designer 열기:
   https://portal.azure.com/#resource/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/logicDesigner

2. **Condition_Check_Errors** 액션 후에 새 액션 추가

3. **HTTP** 액션 선택

4. 설정 입력:
   - **Method**: POST
   - **URI**: `https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_apis/wit/workitems/$Issue?api-version=7.0`
   - **Headers**: 
     - `Content-Type`: `application/json-patch+json`
   - **Authentication**: Managed Identity
   - **Body**: JSON Patch 배열 (위 스니펫 참조)

## ⚙️ Managed Identity 권한 설정

### 1. Logic App Identity 확인

```powershell
$identity = az logic workflow show \
  -g "RG-ZBHO-DW9-APIM-AOAI-DEMO" \
  -n "logicapp-apim-aoai-monitoring" \
  --query "identity.principalId" -o tsv

echo "Identity: $identity"
```

### 2. DevOps 프로젝트에 권한 부여

**Azure Portal**:
1. Azure DevOps 프로젝트: https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103
2. Project Settings → Permissions
3. Logic App Managed Identity 추가
4. Role: "Contributor" 또는 "Work Item Writer"

**Azure CLI** (Optional):
```powershell
# DevOps PAT로 인증 후
az devops security permission update \
  --namespace-id "..." \
  --subject "..." \
  --token "..." \
  --allow-bit 8  # Work Item 생성 권한
```

## 🧪 테스트 방법

### 1. 수동 실행

```powershell
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/triggers/Recurrence/run?api-version=2016-06-01"
```

### 2. 실행 결과 확인

```powershell
# 최신 실행 조회
$runs = az rest --method GET \
  --uri "https://management.azure.com/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring/runs?api-version=2016-06-01" | ConvertFrom-Json

$latestRun = $runs.value[0]
echo "Status: $($latestRun.properties.status)"
```

### 3. DevOps Work Item 확인

https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_workitems/recentlyupdated/

## 📁 생성된 파일

- **deploy-devops-http.json**: 완전한 ARM 템플릿 (11,982 bytes)
- **DevOps-WorkItem-Action.json**: JSON 스니펫 (재사용 가능)
- **create_devops_template.py**: 템플릿 생성 스크립트

## 🐛 Troubleshooting

### 문제 1: "NotFound" 에러 (기존 visualstudioteamservices 커넥터)

**원인**: Swagger 기반 operationId를 찾을 수 없음

**해결**: HTTP 액션으로 전환 (이 문서의 솔루션)

### 문제 2: "Unauthorized" 401 에러

**원인**: Managed Identity 권한 부족

**해결**: DevOps 프로젝트에 Identity 추가 (위 권한 설정 참조)

### 문제 3: "BadRequest" 400 에러

**원인**: JSON Patch 형식 오류

**해결**: Content-Type이 `application/json-patch+json`인지 확인

### 문제 4: 중복 액션 이름 에러

**원인**: 템플릿에 같은 이름의 액션이 2개 존재

**해결**: 기존 액션 삭제 후 새 액션 추가 (Python 스크립트 참조)

## 📚 참고 문서

- [Azure DevOps REST API - Work Items](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/create)
- [Logic Apps HTTP Connector](https://learn.microsoft.com/en-us/azure/connectors/connectors-native-http)
- [Managed Identity in Logic Apps](https://learn.microsoft.com/en-us/azure/logic-apps/create-managed-service-identity)
- [JSON Patch Format (RFC 6902)](https://tools.ietf.org/html/rfc6902)

## ✅ 최종 체크리스트

- [x] HTTP 액션으로 DevOps REST API 호출
- [x] Managed Identity 인증 설정
- [x] Title 필드 데이터 매핑
- [x] Description HTML 포맷팅
- [x] AssignedTo 필드 설정 (azure-mvp@zerobig.kr)
- [x] Priority/Severity 설정
- [x] runAfter 조건 설정 (Condition_Check_Errors 성공 시)
- [ ] Managed Identity 권한 부여 (수동 설정 필요)
- [ ] 테스트 실행 및 검증

---

**작성일**: 2026-01-03  
**버전**: 1.0 (Final)  
**배포 템플릿**: deploy-devops-http.json
