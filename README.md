# APIM + AOAI 모니터링 Logic App - Terraform IaC

이 Terraform 프로젝트는 Azure API Management (APIM)와 Azure OpenAI (AOAI)의 모니터링을 위한 Logic App을 배포합니다.

## 📋 개요

- **목적**: APIM의 비정상 응답(200이 아닌 상태코드)을 모니터링하고, Teams/이메일 알림 및 Azure DevOps Issue 자동 생성
- **트리거**: 5분 주기 반복 실행
- **알림 채널**: Teams, Email, Azure DevOps
- **보안**: Managed Identity 기반 최소 권한 원칙

## 🏗️ 아키텍처

```
Logic App (Recurrence Trigger, 5분)
    ↓
Log Analytics Query (ApiManagementGatewayLogs)
    ↓
Condition Check (결과 > 0)
    ↓
ForEach Loop (각 결과 처리)
    ├── Teams 알림 전송
    ├── Email 알림 전송
    └── Azure DevOps Issue 생성 (고심각도 이벤트)
```

## 📁 파일 구조

```
.
├── main.tf                 # Logic App 리소스 정의
├── variables.tf            # 변수 정의
├── outputs.tf              # 출력값 정의
├── locals.tf               # 로컬 변수/상수
├── terraform.tfvars        # 실제 값 (민감정보 포함 주의)
├── .gitignore              # Git 무시 파일 목록
└── README.md               # 이 파일
```

## 🔧 필수 사전 조건

1. **Terraform**: v1.0 이상
2. **Azure CLI**: 최신 버전
3. **Azure Subscription**: 활성 구독
4. **Azure DevOps**: 프로젝트 생성 필요 (`prj-ticketGEN-demo-20260103`)
5. **Teams**: 채널 ID 확보 필요
6. **Log Analytics Workspace**: 기존 워크스페이스 필요

### Azure CLI 로그인
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

## 📦 리소스 배포

### 1. Terraform 초기화
```bash
cd ticketGEN-Demo-20260103
terraform init
```

### 2. 배포 계획 검토
```bash
terraform plan -out=logicapp.tfplan
```

### 3. 리소스 배포
```bash
terraform apply logicapp.tfplan
```

### 4. 배포 결과 확인
```bash
terraform output
```

## 🔑 주요 변수 설정

### terraform.tfvars 파일에서 설정:

| 변수명 | 설명 | 기본값 |
|--------|------|-------|
| `resource_group_name` | 리소스 그룹명 | `rg-zbho-dw9-apim-aoai-demo` |
| `location` | Azure 리전 | `Korea Central` |
| `logic_app_name` | Logic App 이름 | `logicapp-apim-aoai-monitoring` |
| `recurrence_interval` | 실행 주기 (분) | `5` |
| `log_analytics_workspace_id` | Log Analytics ID | `7368ebd0-a658-4099-a5c3-2efb28733f5f` |
| `email_recipients` | 이메일 수신자 목록 | `["alert@zerobig.kr", "ops@zerobig.kr"]` |
| `azure_devops_project_name` | Azure DevOps 프로젝트 | `prj-ticketGEN-demo-20260103` |

## 🔐 보안 고려사항

1. **terraform.tfvars**: 민감한 정보를 포함할 수 있으므로 버전 관리에서 제외
2. **Managed Identity**: Logic App에 System Assigned Managed Identity 자동 활성화
3. **RBAC**: 최소 권한 원칙에 따라 역할 할당:
   - Log Analytics Workspace: `Monitoring Reader`
   - Resource Group: `Contributor`

## 🧪 배포 후 검증

### 1. Logic App 상태 확인
```bash
az logicapp show \
  --name logicapp-apim-aoai-monitoring \
  --resource-group rg-zbho-dw9-apim-aoai-demo \
  --query "state"
```

### 2. 트리거 실행 테스트
Azure Portal에서 Logic App을 열고 "Run" 버튼으로 수동 실행

### 3. 실행 히스토리 확인
```bash
az logicapp workflow show \
  --name logicapp-apim-aoai-monitoring \
  --resource-group rg-zbho-dw9-apim-aoai-demo
```

## 📊 KQL 쿼리 테스트

Log Analytics에서 직접 쿼리 테스트:

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

## 🔄 리소스 업데이트/삭제

### 변수 수정 후 재배포
```bash
terraform plan -out=logicapp.tfplan
terraform apply logicapp.tfplan
```

### 모든 리소스 삭제
```bash
terraform destroy
```

## 📝 문제 해결

### 1. Logic App이 생성되지 않음
- Azure 구독 권한 확인
- Resource Group 존재 확인
- Terraform 상태 파일 확인: `terraform.tfstate`

### 2. Connector 오류
- Azure Portal에서 Logic App 커넥터 권한 확인
- Teams/Email 커넥터 인증 필요
- Azure DevOps 커넥터 PAT(Personal Access Token) 확인

### 3. Log Analytics 쿼리 오류
- Log Analytics Workspace ID 정확성 확인
- 워크스페이스 권한 확인
- Log Type `ApiManagementGatewayLogs` 확인

## 📚 참고 자료

- [Azure Logic Apps 공식 문서](https://learn.microsoft.com/azure/logic-apps)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [KQL Query Language](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)
- [Teams Adaptive Card Designer](https://adaptivecards.io/designer/)

## 🔗 Azure DevOps Wiki

자세한 구현 내용은 Azure DevOps Wiki 참조:
- [APIM + AOAI 모니터링 Logic App 구현 상세 계획](https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_wiki)

## 📄 라이선스

MIT License - 자유롭게 사용, 수정, 배포 가능

## ✍️ 작성자

- **Project**: ZEROBIG APIM + AOAI Monitoring
- **Created**: 2026-01-03
- **Team**: azure-mvp@zerobig.kr
