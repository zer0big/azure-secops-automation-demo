# 🚀 Logic App Terraform → 수동 구성 전환 안내

## 📊 현재 상황

### 문제점
- ❌ Terraform `azurerm_logic_app_workflow`로 Logic App 리소스만 생성
- ❌ Logic App **Definition (워크플로우 정의)** 없음 → Designer에서 아무것도 표시 안 됨
- ❌ Terraform으로는 복잡한 Logic App 정의 관리가 비효율적

### 해결책
✅ **Azure Portal에서 직접 Logic App 생성 & 구성**
✅ 시각적 Designer로 트리거 및 액션 추가
✅ 커넥터 자동 인증
✅ 테스트 기능 활용

---

## ✨ 왜 수동 구성인가?

| 방식 | 장점 | 단점 |
|------|------|------|
| **Terraform** | IaC 버전 관리 | 복잡한 JSON 정의, 커넥터 인증 어려움 |
| **Azure Portal** | ✅ 시각적, ✅ 커넥터 자동, ✅ 테스트 가능 | 수동 구성 |

**결론**: Logic App은 **Azure Portal에서 구성 후, 필요시 Terraform으로 import하는 것이 best practice** ✅

---

## 🎯 다음 단계 (15-20분)

### 1단계: Azure Portal에서 Logic App 생성
```
https://portal.azure.com
→ "Logic App" 검색
→ Resource Group: RG-ZBHO-DW9-APIM-AOAI-DEMO
→ Name: logicapp-apim-aoai-monitoring
→ Location: eastus
```

### 2단계: Designer에서 워크플로우 구성
[MANUAL-SETUP.md 참고 - Step 1-4 → Step 2-3]

### 3단계: 커넥터 인증 (자동)
- Teams, Email, Azure DevOps
- 각 Action 추가 시 자동 프롬프트

### 4단계: 테스트 & 저장
```
상단 "실행" → "Recurrence" 선택
→ 5초 대기 후 결과 확인
```

---

## 📁 현재 Terraform 상태

### 유지되는 것
```
✅ main.tf - 간단한 Logic App + Identity 정의
✅ variables.tf - 모든 설정값
✅ outputs.tf - 배포 정보
✅ locals.tf - KQL 쿼리
✅ terraform.tfvars - 환경 변수
```

### 제거된 것
```
❌ connections.tf - 커넥터 정의 (수동으로 Portal에서 관리)
❌ main_complex.tf - 복잡한 Logic App 정의
```

### 새로 추가된 것
```
✨ MANUAL-SETUP.md - 상세 수동 구성 가이드
✨ CONNECTOR-SETUP.md - 커넥터 인증 가이드
```

---

## 🔄 향후 Terraform 동기화 (선택사항)

Logic App을 수동으로 완성한 후:

```bash
# 방법 1: Terraform Import
terraform import azurerm_logic_app_workflow.apim_aoai_monitoring \
  "/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring"

# 방법 2: Export → Terraform 변환
# Azure Portal에서 "자동화" → "템플릿 내보내기"
# → Azure Bicep/JSON → Terraform로 변환
```

---

## 📞 지원

**상세 가이드**: [MANUAL-SETUP.md](MANUAL-SETUP.md)
**커넥터 문제**: [CONNECTOR-SETUP.md](CONNECTOR-SETUP.md)

---

## ⏱️ 예상 일정

| 단계 | 소요 시간 | 상태 |
|------|----------|------|
| Logic App 생성 | 2분 | 👤 수동 |
| Triggers 추가 | 3분 | 👤 수동 |
| Actions 추가 | 10분 | 👤 수동 |
| 커넥터 인증 | 3분 | 👤 수동 |
| 테스트 | 2분 | 👤 수동 |
| **총합** | **~20분** | ✅ |

---

## ✅ 체크리스트

- [ ] [MANUAL-SETUP.md](MANUAL-SETUP.md) 읽기
- [ ] Azure Portal에서 Logic App 생성
- [ ] Step 1-4의 기본 정보 입력
- [ ] Step 2-3의 Triggers 추가
- [ ] Step 3-7의 Actions 추가
- [ ] Step 4의 저장 및 테스트
- [ ] 자동 실행 확인 (5분 후)

---

**준비 완료! 이제 시작하세요! 🚀**
