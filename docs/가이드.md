# 🎯 APIM 에러 모니터링 - 문서 가이드

**프로젝트**: Azure API Management 자동 모니터링 및 DevOps 통합  
**버전**: v1.0 (2026-01-04)  
**언어**: 🇰🇷 한글 (English 지원)

---

## 📚 문서 구조

```
📦 Project Documentation
├── 🚀 시작하기
│   ├── ../README.md ..................... 프로젝트 개요 및 주요 기능
│   └── 빠른참조.md ...................... 일일 운영 체크리스트
│
├── 📖 상세 기술 문서
│   ├── 아키텍처.md ..................... 시스템 구조 및 설계 원칙
│   ├── 구현가이드.md ................... Logic App 상세 구성 설명
│   └── 운영가이드.md ................... 배포 및 모니터링 가이드
│
├── 🛠️ 배포 및 설정
│   ├── ../logicapp-deployment.json ..... ARM 템플릿 (배포용)
│   ├── ../parameters.json .............. 프로덕션 설정 파일
│   └── ../parameters.example.json ...... 설정 템플릿 (참고용)
│
└── 📋 참고자료
    ├── ../LICENSE.txt .................. MIT 라이선스
    ├── ../scripts/ ..................... 유틸리티 스크립트
    └── ../templates/ ................... 추가 ARM 템플릿 모음
```

---

## 🎯 상황별 가이드

### 🆕 **처음 시작하는 경우**
1. **[README.md](../README.md)** 읽기 → 프로젝트 전체 개요 파악
2. **[빠른참조.md](ko/빠른참조.md)** 검토 → 필요한 리소스 및 설정 확인
3. **[아키텍처.md](ko/아키텍처.md)** 학습 → 시스템 동작 원리 이해

### 🔧 **배포/설정하는 경우**
1. **[구현가이드.md](ko/구현가이드.md)** 참고 → 각 액션의 설정 방법
2. **[운영가이드.md](ko/운영가이드.md)** 따라하기 → 단계별 배포 절차
3. **[logicapp-deployment.json](../logicapp-deployment.json)** 수정 → 환경에 맞게 커스터마이징

### 📊 **모니터링/유지보수하는 경우**
1. **[빠른참조.md](ko/빠른참조.md)** 확인 → 일일 점검 항목
2. **[운영가이드.md](ko/운영가이드.md)** 참고 → 문제 해결 방법
3. **[아키텍처.md](ko/아키텍처.md)** 상담 → 기술 자료 검증

---

## 📖 각 문서 상세 설명

### 🚀 **빠른참조.md** (5분)
- 🎯 목적: 일일 운영 및 긴급 확인용
- 📌 내용
  - 리소스 위치 (Subscription, Resource Group)
  - 주요 설정값 (시간대, 알림 채널)
  - 에러 로그 조회 방법
  - 긴급 대응 체크리스트

### 🏗️ **아키텍처.md** (20분)
- 🎯 목적: 시스템 설계 및 구조 이해
- 📌 내용
  - 전체 데이터 흐름 다이어그램
  - 각 Azure 서비스의 역할
  - 보안 모델 (Managed Identity, 역할 기반 접근)
  - 확장성 및 성능 고려사항

### 🔨 **구현가이드.md** (30분)
- 🎯 목적: Logic App의 각 액션 상세 설명
- 📌 내용
  - Recurrence 트리거 설정
  - HTTP 액션으로 Log Analytics 쿼리
  - Parse JSON, 조건문 활용
  - Email, Teams, DevOps API 통합
  - 오류 처리 및 알림

### 📋 **운영가이드.md** (30분)
- 🎯 목적: 배포부터 운영까지 전체 프로세스
- 📌 내용
  - 사전 요구사항 (권한, 리소스)
  - ARM 템플릿 배포 절차
  - 연결(Connection) 인증 설정
  - 배포 후 검증 및 테스트
  - 문제 발생 시 로그 조회 방법

---

## 🔗 외부 자료 (필요 시)

- **Azure Logic Apps 공식 문서**: https://learn.microsoft.com/ko-kr/azure/logic-apps/
- **Log Analytics KQL**: https://learn.microsoft.com/ko-kr/azure/data-explorer/kusto/query/
- **Azure DevOps REST API**: https://learn.microsoft.com/en-us/rest/api/azure/devops/
- **APIM 모니터링**: https://learn.microsoft.com/ko-kr/azure/api-management/api-management-howto-log-to-loganalytics

---

## ❓ FAQ & 문제 해결

### Q: Logic App 배포 후 연결 오류가 발생합니다
→ **[운영가이드.md](ko/운영가이드.md#연결-인증-설정)** 의 "연결 인증 설정" 섹션 참고

### Q: Teams 또는 이메일로 알림을 받지 못했습니다
→ **[구현가이드.md](ko/구현가이드.md#알림-채널-설정)** 의 채널별 설정 확인

### Q: 24시간 데이터를 조회해야 하는데 오류가 적습니다
→ **[빠른참조.md](ko/빠른참조.md#로그-확인)** 의 Log Analytics 직접 쿼리 방법 참고

### Q: ADO 작업 항목 생성이 실패합니다
→ **[구현가이드.md](ko/구현가이드.md#azure-devops-통합)** 의 권한 및 PAT 설정 확인

---

## 📝 버전 이력

| 버전 | 날짜 | 내용 |
|------|------|------|
| 1.0 | 2026-01-04 | 초기 프로덕션 배포 완료 |

---

**다음 단계**: 좌측 문서 목록에서 필요한 가이드를 선택하여 읽어주세요! 🎉
