# Azure SecOps 자동화 데모

[![Azure](https://img.shields.io/badge/Azure-Logic_Apps-0078D4?logo=microsoftazure)](https://azure.microsoft.com/ko-kr/products/logic-apps)
[![DevOps](https://img.shields.io/badge/Azure-DevOps-0078D7?logo=azuredevops)](https://dev.azure.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)

Azure Logic Apps를 활용한 API Management 자동 모니터링 및 Azure DevOps 통합 솔루션

## 🎯 주요 기능

- ✅ **APIM 에러 자동 감지**: 24시간 단위 API Gateway 로그 모니터링
- ✅ **다채널 알림**: Microsoft Teams, 이메일, Azure DevOps 워크 아이템
- ✅ **제로 시크릿 보안**: Managed Identity 기반 인증
- ✅ **일일 스케줄 실행**: 시간대 인식 자동 실행 (기본값: 오전 7시 KST)
- ✅ **REST API 직접 통합**: HTTP 액션을 통한 DevOps API 호출
- ✅ **코드형 인프라**: ARM 템플릿 기반 배포

## 📋 사전 요구사항

- 리소스 생성 권한이 있는 Azure 구독
- Azure DevOps 조직 및 프로젝트
- APIM Gateway Logs가 활성화된 Log Analytics 워크스페이스
- Azure CLI 2.50.0 이상
- PowerShell 7.0 이상 (Windows) 또는 Bash (Linux/Mac)

## 🚀 빠른 시작

### 1. 리포지토리 복제
```bash
git clone https://github.com/zer0big/azure-secops-automation-demo.git
cd azure-secops-automation-demo
```

### 2. 파라미터 구성
```bash
# 예제 파일 복사
cp parameters.example.json parameters.json

# 본인 환경에 맞게 값 수정
notepad parameters.json  # Windows
nano parameters.json     # Linux/Mac
```

**필수 파라미터**:
- `logicAppName`: Logic App 이름
- `devOpsOrganization`: DevOps 조직명
- `devOpsProject`: DevOps 프로젝트명
- `lawWorkspaceId`: Log Analytics 워크스페이스 ID (GUID)
- `devOpsAssignee`: 워크 아이템 담당자 이메일
- `emailRecipient`: 알림 수신 이메일
- `teamsGroupId`: Microsoft Teams 그룹 ID
- `teamsChannelId`: Microsoft Teams 채널 ID

### 3. 배포
```bash
az login
az account set --subscription "구독-이름"

az deployment group create \
  --resource-group "리소스-그룹명" \
  --template-file logicapp-deployment.json \
  --parameters @parameters.json \
  --name "LogicApp-Deploy-$(date +%Y%m%d%H%M%S)"
```

### 4. 배포 후 구성

#### API 연결 인증
1. Azure Portal → 리소스 그룹 → 연결(Connections)로 이동
2. 각 연결(teams, outlook)에 대해:
   - 연결 이름 클릭 → API 연결 편집 → 권한 부여
   - 계정으로 로그인

#### Managed Identity 권한 구성
```bash
# Logic App Principal ID 확인
PRINCIPAL_ID=$(az logic workflow show \
  --name 로직앱이름 \
  --resource-group 리소스그룹 \
  --query "identity.principalId" -o tsv)

# Log Analytics Reader 역할 할당
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Log Analytics Reader" \
  --scope /subscriptions/{구독ID}/resourceGroups/{리소스그룹}/providers/Microsoft.OperationalInsights/workspaces/{워크스페이스명}
```

**Azure DevOps 권한** (수동 설정):
1. https://dev.azure.com/{조직}/{프로젝트}/_settings/security 이동
2. Logic App ID를 "Contributor" 또는 "Work Item Writer" 역할로 추가

## 📚 문서

상세 문서 제공:

- **[ARCHITECTURE.md](ARCHITECTURE.md)**: 시스템 설계 및 구성 요소 상세
- **[IMPLEMENTATION.md](IMPLEMENTATION.md)**: 개발 과정 및 배포 가이드
- **[MAINTENANCE.md](MAINTENANCE.md)**: 운영 및 문제 해결
- **[WIKI.md](WIKI.md)**: 빠른 참조 및 운영 가이드

## 🔧 구성

### 스케줄 변경
기본값: 매일 오전 7시 KST

변경 방법:
```json
{
  "scheduleTimeZone": {
    "value": "Pacific Standard Time"
  },
  "scheduleHour": {
    "value": "9"
  }
}
```

### 쿼리 커스터마이징
[logicapp-deployment.json](logicapp-deployment.json)에서 KQL 쿼리 수정:
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| extend KST = TimeGenerated + 9h
| where ResponseCode != 200
| take 50
```

## 🧪 테스트

### 수동 트리거
```bash
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/{구독ID}/resourceGroups/{리소스그룹}/providers/Microsoft.Logic/workflows/{로직앱명}/triggers/Recurrence/run?api-version=2016-06-01"
```

### 실행 상태 확인
```bash
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{구독ID}/resourceGroups/{리소스그룹}/providers/Microsoft.Logic/workflows/{로직앱명}/runs?api-version=2016-06-01" \
  | jq '.value[0] | {status: .properties.status, startTime: .properties.startTime}'
```

## 📊 모니터링

Azure Portal에서 Logic App 실행 기록 확인:
```
https://portal.azure.com → Logic Apps → 로직앱 선택 → 개요 → 실행 기록
```

주요 지표:
- 성공률: 목표 >95%
- 실행 시간: 목표 <30초
- 에러 감지: 오탐 모니터링

## 🔐 보안

### 인증
- **Managed Identity**: Log Analytics 및 DevOps API 호출에 사용
- **OAuth**: Teams 및 Outlook 연결에 사용

### 민감 데이터
다음 파일들은 gitignore 처리됨:
- `parameters.json` (배포 파라미터)
- `config.json` (런타임 구성)
- `.env` (환경 변수)

**절대 Git에 커밋하지 마세요.**

## 🛠 문제 해결

### 일반적인 문제

**Logic App 실행 실패**:
- API 연결 권한 부여 상태 확인
- Managed Identity 권한 확인
- 실행 기록에서 에러 상세 확인

**워크 아이템이 생성되지 않음**:
- DevOps 권한 확인 (수동 설정 필요)
- Managed Identity audience 확인: `499b84ac-1321-427f-aa17-267ca6975798`
- 토큰으로 직접 API 호출 테스트

**쿼리 결과가 없음**:
- Log Analytics 워크스페이스 ID 확인
- APIM 진단 설정 확인
- 필요시 시간 범위 확대

상세한 문제 해결은 [MAINTENANCE.md](MAINTENANCE.md) 참조.

## 💰 비용 예상

월간 예상 비용 (2026년 1월 기준):
- Logic App 실행 (30회/월): ~₩2
- API 연결 (3개): ~₩300
- **총계: ~₩300/월**

## 📝 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다 - [LICENSE.txt](LICENSE.txt) 파일 참조.

## 🤝 기여

기여를 환영합니다! 다음 절차를 따라주세요:
1. 리포지토리 Fork
2. 기능 브랜치 생성
3. 명확한 메시지로 커밋
4. Pull Request 제출

## 📞 지원

문제 및 질문:
- GitHub에 이슈 등록
- 기존 문서 검토
- [MAINTENANCE.md](MAINTENANCE.md)의 문제 해결 가이드 확인

## 🔄 버전 이력

- **v1.0** (2026-01-03): 프로덕션 초기 릴리스
  - ARM 템플릿 배포
  - Managed Identity 인증
  - 매일 오전 7시 KST 스케줄
  - HTTP 기반 DevOps 통합

---

**유지관리**: Azure SecOps Team  
**최종 업데이트**: 2026년 1월 3일
