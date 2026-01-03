# APIM + AOAI 모니터링 Logic App 구현 상세 계획

---

## 1. 목적 및 시나리오

- **목적**: APIM(Managed Identity)과 AOAI 연동 환경에서, API 호출 결과 중 200이 아닌 응답을 Log Analytics에서 주기적으로 조회하고, Teams/이메일로 실시간 알림을 전파하며, 심각한 문제는 Azure DevOps Issue로 자동 생성하여 장애·이상 징후를 신속하게 감지·추적·대응
- **시나리오**:
  1. Logic App이 일정 주기(5분)로 Log Analytics에 쿼리 실행
  2. 200이 아닌 응답(에러/비정상) 발생 건 추출
  3. Teams 채널 및 이메일로 상세 알림 전송 (실시간 통지)
  4. 심각도(Severity)가 높은 이벤트는 Azure DevOps Issue로 자동 생성 (백로그 추적)
  5. 모든 단계의 예외 및 실패는 별도 로깅/진단 (감사 및 모니터링)

---

## 2. 아키텍처 및 구성요소

- **리소스 그룹**: `rg-zbho-dw9-apim-aoai-demo`
- **Logic App 이름**: `logicapp-apim-aoai-monitoring` (Consumption)
- **위치**: Korea Central (또는 조직 기본 위치)
- **트리거**: Recurrence (5분 주기)
- **Log Analytics Workspace ID**: `7368ebd0-a658-4099-a5c3-2efb28733f5f`
- **Workspace 이름**: `zbho-dw9-law`
- **Log Type**: `ApiManagementGatewayLogs`
- **쿼리 조건**: `responseCode != 200`
- **Teams 채널**: [https://teams.microsoft.com/l/channel/19%3A32df97df94214adfa36ab24db8a1a9dc%40thread.tacv2/%EC%9D%BC%EB%B0%98?groupId=b9367993-aa6c-40f3-93c5-e173a5fba3df&tenantId=067db808-c3ee-4430-8135-05f15d0d242f](https://teams.microsoft.com/l/channel/19%3A32df97df94214adfa36ab24db8a1a9dc%40thread.tacv2/%EC%9D%BC%EB%B0%98?groupId=b9367993-aa6c-40f3-93c5-e173a5fba3df&tenantId=067db808-c3ee-4430-8135-05f15d0d242f)
- **이메일 수신자**: 기존 `ghcp-demo-logic-entra-daily` Logic App과 동일하게 구성
- **보안**: Managed Identity 기반 최소 권한, 커넥터 권한 분리

---

## 3. Logic App 워크플로우 상세

### 3.1. 트리거
- Recurrence 트리거 (CRON/주기 설정)
- 예: 5분마다 실행

### 3.2. Log Analytics 쿼리
- **커넥터**: Azure Monitor Logs
- **KQL 쿼리 (ApiManagementGatewayLogs)**:
  ```kusto
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
  ```
- **파라미터화**:
  - 워크스페이스 ID: `7368ebd0-a658-4099-a5c3-2efb28733f5f`
  - 조회 기간: 마지막 5분 (Recurrence와 동일)
  - 응답코드 필터: `!= "200"`
  - 로그 타입: `ApiManagementGatewayLogs` (AzureDiagnostics 대신 사용)

### 3.3. 결과 처리 및 분기
- 쿼리 결과가 1건 이상일 때만 알림 전송
- 각 결과별로 반복(ForEach) 처리 가능

### 3.4. Teams/이메일 알림
- **Teams**: Adaptive Card/Plain Text, 주요 필드(시간, API, 상태, 상세 메시지, 링크)
- **이메일**: HTML 템플릿, 동일 정보 포함
- **참고**: 기존 Logic App(알림용) 워크플로우의 메시지 포맷/채널 참조

### 3.5. Azure DevOps Issue 자동생성 (보안 이벤트 기반)

- **트리거**: 보안 이벤트(JSON) 수신 (예: HTTP Request, Event Grid 등)
- **Parse JSON**: AlertName, Severity, Description 필드 추출
- **Azure DevOps - Create a work item** 액션 추가
  - Title: `@{triggerBody()?['AlertName']}`
  - Description: HTML 포맷 적용 (아래 예시 참고)
  - AssignedTo: `azure-mvp@zerobig.kr`
- **후속 알림/로깅**: Teams, 이메일, 진단 로그 등

#### [예시] Azure DevOps - Create a work item 액션(JSON)
```json
{
  "type": "OpenApiConnection",
  "inputs": {
    "host": {
      "connection": {
        "name": "@parameters('$connections')['azuredevops']['connectionId']"
      }
    },
    "method": "post",
    "path": "/v1.0/workitems",
    "body": {
      "project": "<YourProjectName>",
      "type": "Issue",
      "title": "@{triggerBody()?['AlertName']}",
      "assignedTo": "azure-mvp@zerobig.kr",
      "description": "<div><b>Severity:</b> @{triggerBody()?['Severity']}</div><div><b>Description:</b><br/>@{triggerBody()?['Description']}</div>"
    },
    "authentication": "@parameters('$authentication')"
  },
  "runAfter": {},
  "metadata": {
    "operationMetadataId": "<unique-guid>"
  }
}
```

**Description 필드(HTML 포맷 예시):**
```html
<div>
  <b>Severity:</b> @{triggerBody()?['Severity']}
</div>
<div>
  <b>Description:</b><br/>
  @{triggerBody()?['Description']}
</div>
```

---

## 4. 배포 및 운영

### 4.1. Terraform IaC 배포
```bash
# 배포 계획 확인
terraform plan -out=logicapp.tfplan

# Logic App 배포
terraform apply logicapp.tfplan
```

**배포 파일**: `logic-app.tf` (별도 파일)
- Logic App 리소스 정의
- Recurrence 트리거 (5분 주기, UTC 기준)
- Log Analytics 커넥터 설정
- Teams 채널 연동
- 이메일 수신자 설정
- Azure DevOps 커넥터 인증 설정

### 4.2. 버전 관리
- **git**: 모든 IaC 코드 및 워크플로우 JSON 버전 관리
- **변경 관리**: 주요 워크플로우 변경 시 PR 리뷰 필수
- **배포 기록**: Terraform state 파일로 추적

### 4.3. 운영 가이드
- **트리거 주기**: 5분 (필요 시 조정 가능)
- **KQL 쿼리**: Log Analytics에서 실시간 테스트 가능
- **알림 채널**: Teams 채널 URL, 이메일 수신자 목록 유지보수
- **DevOps Issue**: 보안 이벤트 감지 시 자동 생성

---

## 5. 보안 및 권장 정책

### 5.1. 인증 및 권한 부여
- **Managed Identity**: Logic App에 System Assigned Managed Identity 활성화
- **최소 권한 원칙**:
  - Log Analytics Workspace: `Monitoring Reader` 역할
  - Teams 채널: 제한된 사용자만 접근
  - Azure DevOps: 특정 프로젝트의 Work Item Creator 역할
  - APIM: 읽기 전용 권한

### 5.2. 데이터 보안
- **커넥터 비밀값**: Azure Key Vault 연동 (향후 구현)
  - Teams Webhook URL
  - SMTP 자격증명 (이메일)
  - Log Analytics 접근 키
- **감사 로그**: Logic App 실행 로그 모두 Log Analytics에 기록
- **진단 로그**: 모든 실패 및 예외는 Log Analytics 또는 Application Insights에 기록

### 5.3. 규정 준수
- **Azure Well-Architected Framework** 준수:
  - **운영 우수성**: 모니터링, 로깅, 자동화
  - **보안**: 최소 권한, 감사 로그, 비밀 관리
  - **신뢰성**: 재시도 정책, 오류 처리, 예외 알림
  - **성능 효율성**: Consumption 기반 Logic App (비용 효율)
  - **비용 최적화**: 매월 리뷰, 불필요한 알림 제거

---

## 6. 참고/추가 자료 및 배포 파일

### 6.1. 문서
- 기존 Logic App(`ghcp-demo-logic-entra-daily`) 워크플로우 JSON/설정 참조
- KQL 쿼리 튜닝 및 Log Analytics 공식 문서: https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/
- Teams Adaptive Card Designer: https://adaptivecards.io/designer/
- Azure Logic Apps 공식 문서: https://learn.microsoft.com/azure/logic-apps

### 6.2. 배포 파일 (Terraform)
```
logic-app-monitoring/
├── main.tf                    # Logic App 리소스 정의
├── variables.tf               # 변수 정의 (RG, 위치, 워크스페이스 ID 등)
├── outputs.tf                 # Logic App ID, 엔드포인트 출력
├── locals.tf                  # 로컬 변수 (내부 상수)
└── terraform.tfvars           # 실제 값 (민감정보 제외, 로컬만)
```

### 6.3. Logic App 워크플로우 정의
- **파일**: `logicapp-workflow.json`
- **포함 내용**:
  1. Recurrence 트리거 (5분)
  2. Log Analytics 쿼리 액션
  3. 조건부 분기 (결과 > 0)
  4. ForEach 반복 액션
  5. Teams 메시지 전송
  6. 이메일 발송
  7. Azure DevOps Issue 자동 생성
  8. 예외 처리 (Try/Catch)
