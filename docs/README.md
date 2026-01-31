# 📚 Azure SecOps 자동화 - 문서 가이드

**프로젝트**: Azure API Management 자동 모니터링 및 DevOps 통합  
**버전**: v2.0.0 (2026-01-31)  
**언어**: 🇰🇷 한글

---

## 📂 문서 구조

| 문서 | 설명 | 대상 독자 | 소요시간 |
|------|------|----------|---------|
| [HANDS-ON-GUIDE.md](HANDS-ON-GUIDE.md) | Step-by-Step 구축 가이드 | 초보자 | 1.5~2시간 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | 시스템 아키텍처 및 설계 원칙 | 중급 이상 | 20분 |
| [QUICK-REFERENCE.md](QUICK-REFERENCE.md) | 명령어 치트시트 / 빠른 참조 | 모든 수준 | 5분 |
| [OPERATIONS-GUIDE.md](OPERATIONS-GUIDE.md) | 운영 및 유지보수 가이드 | 운영자 | 30분 |

---

## 🎯 상황별 추천 문서

### 🆕 **처음 시작하는 경우**
1. **[../README.md](../README.md)** → 프로젝트 개요 파악
2. **[HANDS-ON-GUIDE.md](HANDS-ON-GUIDE.md)** → Step-by-Step 따라하기

### 🔧 **배포/설정하는 경우**
1. **[HANDS-ON-GUIDE.md](HANDS-ON-GUIDE.md)** → ARM 템플릿 배포 절차
2. **[../templates/](../templates/)** → 추가 ARM 템플릿 참조

### 📊 **모니터링/유지보수하는 경우**
1. **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** → 일일 점검 명령어
2. **[OPERATIONS-GUIDE.md](OPERATIONS-GUIDE.md)** → 문제 해결 방법

### 🏗️ **아키텍처 이해하려는 경우**
1. **[ARCHITECTURE.md](ARCHITECTURE.md)** → 시스템 구조 및 데이터 흐름

---

## 📖 각 문서 요약

### 📘 [HANDS-ON-GUIDE.md](HANDS-ON-GUIDE.md)
> **초보 Azure 클라우드 엔지니어를 위한 완전 가이드**

- ✅ 사전 조건 및 필수 도구 설치
- ✅ Azure DevOps 설정 (PAT 생성)
- ✅ Log Analytics Workspace 설정
- ✅ APIM 진단 설정
- ✅ ARM 템플릿 배포
- ✅ API Connection 인증
- ✅ E2E 테스트

### 🏛️ [ARCHITECTURE.md](ARCHITECTURE.md)
> **시스템 설계 및 기술 구조**

- 전체 데이터 흐름 다이어그램
- Azure 서비스별 역할
- 보안 모델 (Managed Identity)
- 확장성 고려사항

### ⚡ [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
> **자주 사용하는 명령어 모음**

- 리소스 위치 및 설정값
- Log Analytics 쿼리 예시
- Logic App 수동 트리거
- 긴급 대응 체크리스트

### 🔧 [OPERATIONS-GUIDE.md](OPERATIONS-GUIDE.md)
> **운영 및 유지보수**

- 일일/주간 점검 항목
- 알림 채널 설정
- 로그 조회 방법
- 트러블슈팅 가이드

---

## 🔗 외부 참고 자료

- [Azure Logic Apps 공식 문서](https://learn.microsoft.com/azure/logic-apps/)
- [Log Analytics KQL 쿼리](https://learn.microsoft.com/azure/azure-monitor/logs/get-started-queries)
- [Azure DevOps REST API](https://learn.microsoft.com/rest/api/azure/devops/)
- [APIM 모니터링](https://learn.microsoft.com/azure/api-management/api-management-howto-use-azure-monitor)

---

## 📝 버전 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 2.0.0 | 2026-01-31 | 문서 구조 표준화 및 HANDS-ON-GUIDE 추가 |
| 1.0.0 | 2026-01-04 | 초기 프로덕션 배포 |

---

**🎉 시작하기**: [HANDS-ON-GUIDE.md](HANDS-ON-GUIDE.md)로 이동하여 Step-by-Step 가이드를 따라해보세요!
