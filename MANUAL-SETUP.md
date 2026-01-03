# 🚨 Logic App 수동 구성 가이드 (긴급)

## 상황
- Terraform으로 Logic App이 생성되지 않음
- **해결**: Azure Portal에서 직접 Logic App을 생성하고 커넥터를 인증합니다

---

## 🔧 Step 1: Logic App 수동 생성

### 1-1. Azure Portal 접속
```
https://portal.azure.com
```

### 1-2. Logic App 생성
```
① 검색 → "Logic App" 입력
② "Logic App" 클릭
③ "만들기" 또는 "+ 추가" 클릭
```

### 1-3. Logic App 기본 정보 입력
```
- 리소스 그룹: RG-ZBHO-DW9-APIM-AOAI-DEMO ✓
- Logic App 이름: logicapp-apim-aoai-monitoring
- 위치: eastus ✓
- Log Analytics: 사용 안 함 (기존 LAW 사용)
```

### 1-4. "검토 및 생성" → "생성" 클릭

---

## 🔐 Step 2: Logic App Designer에서 워크플로우 구성

### 2-1. Logic App 리소스로 이동
```
생성 후 "리소스로 이동" 클릭
→ "Logic App Designer" 선택
```

### 2-2. Trigger 추가 (2가지)

#### Trigger 1: Recurrence (5분 마다 자동 실행)
```
① "Recurrence" 검색
② 설정:
   - Frequency: Minute
   - Interval: 5
```

#### Trigger 2: HTTP 요청 (Azure DevOps 웹훅)
```
① "HTTP 요청" 또는 "Request" 검색
② 스키마 설정:
{
  "type": "object",
  "properties": {
    "AlertName": { "type": "string" },
    "Severity": { "type": "string" },
    "Description": { "type": "string" }
  },
  "required": ["AlertName", "Severity", "Description"]
}
```

---

## 📊 Step 3: 각 Action 추가

### 3-1. Log Analytics 쿼리 (Recurrence 후)
```
Action: "Azure Monitor Logs" → "Run query"
설정:
- Subscription ID: 3864b016-4594-40ad-a96b-4a08ac96b537
- Resource Group: (비움)
- Resource Types: (비움)
- Query:
  ApiManagementGatewayLogs
  | where responseCode != "200"
  | project TimeGenerated, operationId, apiId, responseCode
  | order by TimeGenerated desc
  | take 100
- Time Range: Last 5 minutes (PT5M)
```

### 3-2. 조건 확인 (Log Analytics 결과 후)
```
Action: "Condition"
설정:
- 조건: length(body('Run_query')?['value']) is greater than 0
```

### 3-3. ForEach 루프 (조건 True일 때)
```
Action: "For Each"
설정:
- Select an output from previous step: body('Run_query')?['value']
```

### 3-4. Teams 메시지 (ForEach 내부)
```
Action: "Post message in a chat or channel" (Teams)
인증: Office 365 계정으로 로그인
설정:
- Team: zerobig korea (또는 실제 팀)
- Channel: azure-apim-alerts
- Message: 
  <h3>🚨 APIM Alert</h3>
  <p>Non-200 Response Detected</p>
  <p><strong>API:</strong> @{items('For_each')?['apiId']}</p>
  <p><strong>Status:</strong> @{items('For_each')?['responseCode']}</p>
```

### 3-5. 이메일 알림 (Teams 후)
```
Action: "Send an email" (Office 365 Outlook)
인증: 이메일 계정으로 로그인
설정:
- To: alert@zerobig.kr;ops@zerobig.kr
- Subject: APIM Alert - Non-200 Response
- Body:
  <h2>APIM Alert Notification</h2>
  <p>Non-200 response has been detected.</p>
```

### 3-6. Azure DevOps 이슈 생성 (DevOps Trigger 경로)
```
Action: "Create a work item" (Azure DevOps)
인증: Personal Access Token (PAT) 입력
설정:
- Organization: azure-mvp
- Project: prj-ticketGEN-demo-20260103
- Work Item Type: Issue
- Title: APIM Alert: @triggerBody()?['AlertName']
- Description: @triggerBody()?['Description']
- Assigned To: azure-mvp@zerobig.kr
```

### 3-7. 오류 처리 (Log Analytics 실패 시)
```
Action: "Send an email" (Error Handler)
설정:
- To: alert@zerobig.kr;ops@zerobig.kr
- Subject: ERROR: Logic App Execution Failed
- Body: Logic App failed to execute APIM monitoring...
```

---

## ✅ Step 4: 저장 및 테스트

### 4-1. 저장
```
상단 "저장" 클릭
```

### 4-2. 수동 테스트
```
① 상단 "실행" 클릭
② "Recurrence" 선택
③ "실행" 클릭
④ 결과 확인 (수 초 소요)
```

### 4-3. 자동 실행 확인
```
5분 후 자동으로 Log Analytics에 쿼리를 실행하고
- Teams에 메시지 발송
- 이메일 전송
- (해당 경우) Azure DevOps 이슈 생성
```

---

## 🔗 필요한 커넥터 (자동으로 추가됨)

- ✅ Azure Monitor Logs - Log Analytics 쿼리
- ✅ Teams - 메시지 포스팅
- ✅ Office 365 Outlook - 이메일
- ✅ Azure DevOps - 이슈 생성
- ✅ HTTP - 웹훅

---

## 📋 Terraform 정리 (선택사항)

Logic App을 수동으로 생성한 후, Terraform과 동기화하려면:

```bash
# 현재 Terraform 상태 제거
terraform state rm azurerm_logic_app_workflow.apim_aoai_monitoring

# Terraform으로 import (향후)
terraform import azurerm_logic_app_workflow.apim_aoai_monitoring \
  /subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring
```

---

## 🎯 완료 체크리스트

- [ ] Logic App 수동 생성
- [ ] Recurrence Trigger 추가 (5분)
- [ ] HTTP Request Trigger 추가
- [ ] Log Analytics Query Action 추가
- [ ] Condition Check 추가
- [ ] ForEach Loop 추가
- [ ] Teams Action 인증 및 추가
- [ ] Email Actions 인증 및 추가
- [ ] Azure DevOps Action 인증 및 추가
- [ ] 수동 테스트 실행 및 확인
- [ ] 5분 후 자동 실행 확인

---

## 🆘 문제 해결

### "계속" 진행 중...
- 잠시 대기 (최대 1분)
- 페이지 새로고침 (F5)
- 다시 시도

### "삭제되었습니다" 에러
- Logic App 리소스가 깨짐
- 리소스 그룹에서 삭제 후 다시 생성

### 커넥터 인증 실패
- Azure AD 계정 확인
- 권한 확인
- 관리자 계정으로 다시 시도

---

**예상 소요 시간**: 15-20분
**지원**: alert@zerobig.kr | ops@zerobig.kr
