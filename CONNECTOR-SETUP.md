# Logic App 커넥터 인증 설정 가이드

## 📋 개요
배포된 Logic App이 다음 3가지 커넥터에 대해 인증이 필요합니다:
1. **Teams** - 알림 메시지 전송
2. **Office 365 Outlook** - 이메일 전송
3. **Azure DevOps** - 자동 이슈 생성

## 🔗 Logic App 접근 방법

### 옵션 1: Azure Portal에서 직접 접근
```
https://portal.azure.com
→ Resource Groups → RG-ZBHO-DW9-APIM-AOAI-DEMO
→ logicapp-apim-aoai-monitoring
→ Logic App Designer
```

### 옵션 2: 직접 URL (리소스 ID)
```
/subscriptions/3864b016-4594-40ad-a96b-4a08ac96b537/
resourceGroups/RG-ZBHO-DW9-APIM-AOAI-DEMO/
providers/Microsoft.Logic/workflows/logicapp-apim-aoai-monitoring
```

---

## 🛠️ 커넥터별 인증 설정

### 1️⃣ Teams 커넥터 인증

**위치**: Logic App Designer → SendTeamsAlert 액션

**설정 단계**:
1. SendTeamsAlert 액션의 연결 드롭다운 클릭
2. "새 연결 추가" 선택
3. Teams 계정으로 로그인
4. 다음 정보 입력:
   - **Team**: `zerobig korea` (또는 실제 팀 이름)
   - **Channel**: `azure-apim-alerts` (또는 실제 채널)
5. "저장" 클릭

**필요한 권한**: Teams 메시지 전송 권한

---

### 2️⃣ Office 365 Outlook 커넥터 인증

**위치**: Logic App Designer → SendEmailAlert, ErrorHandler 액션

**설정 단계**:
1. SendEmailAlert 액션의 연결 드롭다운 클릭
2. "새 연결 추가" 선택
3. Office 365 Outlook 계정으로 로그인
   - 기본: `@microsoft.onmicrosoft.com`
   - 또는 Gmail/Outlook 연결
4. "저장" 클릭

**필요한 권한**: 이메일 전송 권한

**수신자 설정**:
```
To: alert@zerobig.kr;ops@zerobig.kr
```

---

### 3️⃣ Azure DevOps 커넥터 인증

**위치**: Logic App Designer → CreateDevOpsIssue 액션

**설정 단계**:

#### Step 1: Personal Access Token (PAT) 생성
1. Azure DevOps 프로젝트로 이동:
   ```
   https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103
   ```

2. 우측 상단 사용자 아이콘 → "Personal access tokens" 클릭

3. "New Token" 클릭

4. Token 설정:
   - **Name**: `LogicApp-APIM-AOAI`
   - **Organization**: `azure-mvp`
   - **Expiration**: 1년
   - **Scopes**:
     - ✅ Work Items (Read & write)
     - ✅ Code (Read)
     - ✅ Build (Read)

5. "Create" 클릭

6. **Token 값을 복사 후 안전한 곳에 저장** (재표시 불가능!)

#### Step 2: Logic App에서 DevOps 연결 인증
1. Logic App Designer에서 CreateDevOpsIssue 액션 클릭
2. 연결 드롭다운 → "새 연결 추가"
3. 다음 정보 입력:
   - **연결 이름**: `Azure DevOps APIM`
   - **Personal Access Token**: 위에서 생성한 PAT 값 붙여넣기
   - **Organization**: `azure-mvp`
4. "저장" 클릭

---

### 4️⃣ Azure Monitor Logs 커넥터 인증

**위치**: Logic App Designer → QueryLogAnalytics 액션

**설정 단계**:
1. QueryLogAnalytics 액션의 연결 드롭다운 클릭
2. "새 연결 추가" 선택
3. Azure 계정으로 로그인
   ```
   계정: 현재 Azure 구독 계정
   ```
4. "저장" 클릭

**필수 권한**: 
- Log Analytics Workspace 읽기 권한 ✅ (이미 Terraform에서 설정됨)

---

## ✅ 인증 완료 확인 방법

### 1. Logic App Designer에서 확인
```
각 액션을 클릭했을 때:
- 빨간 느낌표(⚠️) 없음 = 정상
- 초록 체크(✅) 표시 = 연결됨
```

### 2. 수동 테스트 실행
```
Logic App Designer 상단 → "Run" 클릭
→ 수동 실행 테스트
→ 결과 확인
```

### 3. 실제 작동 확인
```
5분마다 자동 실행되어:
1. Log Analytics에서 non-200 응답 조회
2. Teams 채널에 메시지 발송
3. 이메일 알림 전송
4. Azure DevOps에 이슈 생성
```

---

## 🔑 Terraform을 통한 자동화 (선택사항)

현재 `connections.tf`에 템플릿이 있으나, 커넥터 인증은 **수동으로 진행**해야 합니다.

자동화하려면:

```bash
# connections.tf 배포
terraform apply -target=azurerm_resource_group_template_deployment.teams_connection

# 그 후 수동으로 각 연결 권한 부여 필요
```

---

## 🚨 트러블슈팅

### 문제: "권한 부족" 에러
**해결책**:
```
1. 커넥터 생성 사용자의 권한 확인
2. Logic App이 리소스 그룹에 대한 권한 보유 확인
3. 관리자 권한으로 다시 시도
```

### 문제: Teams 메시지 미수신
**확인 사항**:
1. Team ID 확인: `b9367993-aa6c-40f3-93c5-e173a5fba3df` ✓
2. Channel ID 확인: `19:32df97df94214adfa36ab24db8a1a9dc@thread.tacv2` ✓
3. 팀에 Logic App 서비스 주체 추가됨 확인

### 문제: Azure DevOps 이슈 미생성
**확인 사항**:
1. PAT 토큰 유효성 확인 (만료되지 않음)
2. PAT에 "Work Items (Read & write)" 권한 있는지 확인
3. 프로젝트 ID 확인: `prj-ticketGEN-demo-20260103` ✓

---

## 📊 최종 체크리스트

- [ ] Teams 커넥터 인증 완료
- [ ] Office 365 Outlook 커넥터 인증 완료
- [ ] Azure DevOps 커넥터 인증 완료
- [ ] Azure Monitor Logs 커넥터 인증 완료
- [ ] Logic App Designer에서 모든 액션이 에러 없음
- [ ] 수동 테스트 실행 성공
- [ ] 5분 후 자동 실행 확인

---

## 📞 지원 연락처

**문제 발생 시**:
- `alert@zerobig.kr` - APIM 팀
- `ops@zerobig.kr` - 운영팀
- Teams: `azure-mvp` 채널

---

**마지막 업데이트**: 2026년 1월 3일
**Logic App Name**: `logicapp-apim-aoai-monitoring`
**Resource Group**: `RG-ZBHO-DW9-APIM-AOAI-DEMO`
