# 🎯 APIM 자동 모니터링 & DevOps 통합

[![Azure](https://img.shields.io/badge/Azure-Logic_Apps-0078D4?logo=microsoftazure)](https://azure.microsoft.com/ko-kr/products/logic-apps)
[![DevOps](https://img.shields.io/badge/Azure-DevOps-0078D7?logo=azuredevops)](https://dev.azure.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)

Azure Logic Apps를 활용하여 **API Management 자동 모니터링** 및 **DevOps 통합** 구현  
🔧 배포 준비 완료 | 📖 한글 문서 완비 | ✅ 프로덕션 검증 완료

---

## ✨ 주요 기능

| 기능 | 설명 |
|------|------|
| 🔍 **자동 에러 감지** | 24시간 APIM 로그 모니터링 및 에러 자동 수집 |
| 🔔 **멀티채널 알림** | Teams / 이메일 / DevOps 워크 아이템 자동 생성 |
| 🔐 **보안** | Managed Identity (Log Analytics) + PAT (DevOps) |
| ⏰ **자동 스케줄** | 매일 오전 7시 KST 자동 실행 |
| 🚀 **배포 간편** | ARM 템플릿 기반 (1회 배포로 완성) |

---

## 📁 프로젝트 구조 (정리됨)

```
📦 azure-secops-automation-demo/
│
├── 📖 docs/                          ← 한글 문서 시작점
│   ├── 가이드.md                     ← 문서 네비게이션 (읽기!!)
│   ├── ko/                           ← 한글 상세 문서
│   │   ├── 아키텍처.md              (설계 원칙 & 구성 요소)
│   │   ├── 구현가이드.md            (Logic App 상세 설정)
│   │   ├── 운영가이드.md            (배포 & 문제 해결)
│   │   └── 빠른참조.md              (일일 체크리스트)
│   └── en/                           ← English docs (참고용)
│
├── 🔧 배포 파일
│   ├── logicapp-deployment.json      ← ARM 템플릿
│   ├── parameters.json               ← 프로덕션 설정
│   └── parameters.example.json       ← 설정 예제
│
├── 🛠️ scripts/                       ← 유틸리티
│   ├── generate-template.py
│   └── upload-wiki.ps1
│
├── templates/                        ← 추가 템플릿 (참고용)
├── .env.example                      ← 환경 변수 예제
├── config.example.json               ← 설정 예제
├── LICENSE.txt                       ← MIT 라이선스
└── README.md                         ← 이 파일
```

---

## 🚀 빠른 시작 (5분)

### 1️⃣ 리포지토리 복제
```bash
git clone https://github.com/zer0big/azure-secops-automation-demo.git
cd azure-secops-automation-demo
```

### 2️⃣ 파라미터 설정
```bash
cp parameters.example.json parameters.json

# 텍스트 에디터로 본인 환경에 맞게 수정
# 아래 6가지는 필수!
```

| 파라미터 | 설명 | 예시 |
|---------|------|------|
| `logicAppName` | Logic App 이름 | `logicapp-apim-monitoring` |
| `lawWorkspaceId` | Log Analytics ID (GUID) | `7368ebd0-a658-4099-a5c3-...` |
| `emailRecipient` | 알림 받을 이메일 | `admin@company.com` |
| `devOpsOrganization` | DevOps 조직명 | `azure-mvp` |
| `devOpsProject` | DevOps 프로젝트명 | `prj-ticketGEN-demo` |
| `devOpsAssignee` | 워크아이템 담당자 | `user@organization.microsoft.com` |
| `devOpsPat` | DevOps PAT 토큰 | `(Base64 인코딩된 PAT)` |

### 3️⃣ 배포 (Azure CLI)
```bash
# Azure 로그인
az login

# 구독 선택
az account set --subscription "구독-ID-또는-이름"

# 배포 실행
az deployment group create \
  --resource-group "RG-ZBHO-DW9-APIM-AOAI-DEMO" \
  --template-file templates/logicapp-deployment.json \
  --parameters @parameters.json \
  --name "LogicApp-$(date +%Y%m%d%H%M%S)"
```

### 4️⃣ 배포 후 인증 설정 (수동, 3분)
Azure Portal에서:
1. **리소스 그룹** → 배포된 Logic App 선택
2. **API 연결** 탭에서:
   - `outlook` 연결 → "편집" → "권한 부여"
   - `teams` 연결 → "편집" → "권한 부여"
3. 각각 계정으로 로그인하여 권한 부여

---

## 📚 문서 안내

**어디서부터 시작할까?**

| 상황 | 문서 | 시간 |
|------|------|------|
| 프로젝트 처음 알아보기 | [가이드.md](docs/가이드.md) | 5분 |
| 시스템 아키텍처 이해 | [아키텍처.md](docs/ko/아키텍처.md) | 20분 |
| Logic App 액션별 상세 설명 | [구현가이드.md](docs/ko/구현가이드.md) | 30분 |
| 배포부터 운영까지 | [운영가이드.md](docs/ko/운영가이드.md) | 30분 |
| 일일 체크리스트 | [빠른참조.md](docs/ko/빠른참조.md) | 5분 |

**한글 문서 위치**: `docs/ko/` 또는 위의 링크 클릭

---

## 🧪 테스트 (배포 후)

### 수동 실행
```bash
az rest --method POST \
  --uri "https://management.azure.com/subscriptions/{SUBSCRIPTION}/resourceGroups/{RESOURCE_GROUP}/providers/Microsoft.Logic/workflows/{LOGIC_APP_NAME}/triggers/Recurrence/run?api-version=2016-06-01" \
  --headers "Authorization=Bearer {TOKEN}"
```

### Azure Portal에서 확인
1. **Logic App** 선택
2. **개요** → **실행 기록** 탭
3. 최근 실행 클릭하여 각 액션 성공 여부 확인

---

## ⚙️ 주요 설정

### 실행 스케줄 변경 (기본값: 매일 7시 KST)
[parameters.json](parameters.json)에서:
```json
{
  "scheduleHour": {"value": "7"},
  "scheduleTimeZone": {"value": "Korea Standard Time"}
}
```

### 쿼리 범위 변경 (기본값: 24시간)
[logicapp-deployment.json](logicapp-deployment.json)에서 KQL 수정:
```kusto
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)  // ← 여기 변경
| where ResponseCode != 200
```

---

## 🔐 보안 특징

✅ **비밀 키 최소화**
- Log Analytics: Managed Identity 사용
- DevOps: PAT (Personal Access Token) 사용 (Basic Auth)

✅ **역할 기반 접근 (RBAC)**  
- Logic App에만 필요한 최소 권한 할당

✅ **Git에 민감정보 미포함**  
- parameters.json은 gitignore 처리됨

---

## 💰 예상 비용 (월간)

| 항목 | 사용량 | 비용 |
|------|--------|------|
| Logic App 실행 | 30회/월 | ~₩3 |
| API 연결 (3개) | - | ~₩300 |
| Log Analytics 쿼리 | ~30회 | 포함 |
| **총계** | | **~₩300/월** |

---

## ❓ 자주 묻는 질문

**Q: 배포 후 아무것도 나오지 않습니다**  
→ 배포 후 **인증 설정**을 완료했는지 확인  
→ [운영가이드.md](docs/ko/운영가이드.md#배포-후-인증-설정) 참고

**Q: Teams에 메시지가 안 와요**  
→ Teams 연결 권한 부여 확인  
→ 그룹ID/채널ID 정확성 확인  
→ [빠른참조.md](docs/ko/빠른참조.md) 참고

**Q: ADO 워크아이템이 생성 안 됩니다**  
→ PAT 토큰 유효성 확인  
→ [구현가이드.md](docs/ko/구현가이드.md#azure-devops-통합) 참고

**Q: 에러 로그를 직접 조회하고 싶어요**  
→ Log Analytics로 직접 쿼리  
→ [빠른참조.md](docs/ko/빠른참조.md#로그-직접-조회) 참고

더 많은 Q&A는 [문서 가이드](docs/가이드.md#faq--문제-해결) 참고

---

## 🛠️ 문제 해결

| 문제 | 원인 | 해결책 |
|------|------|--------|
| API 연결 오류 | 권한 부여 미완료 | Portal에서 연결 → 권한 부여 |
| 데이터 없음 | Log Analytics 쿼리 실패 | Workspace ID 확인 |
| 알림 미수신 | Teams/Email 설정 오류 | [운영가이드](docs/ko/운영가이드.md) 참고 |
| 배포 실패 | 권한 부족 | Subscription Owner 권한 필요 |

**상세 가이드**: [운영가이드.md](docs/ko/운영가이드.md#문제-해결)

---

## 📊 프로덕션 상태

✅ **검증 완료**
- Logic App: 8개 액션 모두 정상 작동
- 이메일: UTF-8 인코딩 완벽 지원
- Teams: 이모지 및 포맷팅 완벽 지원
- DevOps: 워크 아이템 자동 생성 완벽 작동 (PAT 인증)
- 테스트 실행: 2026-01-03 성공 ✅

✅ **프로덕션 준비 완료**
- 문서: 한글 완비
- 템플릿: 검증됨
- 배포: 1회 명령어로 완성

---

## 📞 지원

- 📖 **문서**: [docs/가이드.md](docs/가이드.md) 먼저 읽기
- 🐛 **버그 리포팅**: GitHub Issues에 등록
- 💬 **질문**: 존재하는 Issue 검색 후 없으면 새로 작성

---

## 📝 버전 정보

| 버전 | 릴리스 | 상태 |
|------|--------|------|
| **v1.0** | 2026-01-03 | ✅ 프로덕션 |

**최종 업데이트**: 2026년 1월 4일

---

## 📜 라이선스

[MIT License](LICENSE.txt) - 자유롭게 사용하세요!

---

**다음 단계**:
1. ✅ 이 README 읽음
2. 👉 [docs/가이드.md](docs/가이드.md) 읽기 (문서 네비게이션)
3. 🚀 배포 시작!

Happy monitoring! 🎉
