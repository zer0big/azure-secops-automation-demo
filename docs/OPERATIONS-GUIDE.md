# 유지보수 및 운영 가이드

## 목차
- [일일 운영](#일일-운영)
- [모니터링 및 알림](#모니터링-및-알림)
- [문제 해결](#문제-해결)
- [업데이트 절차](#업데이트-절차)
- [백업 및 복구](#백업-및-복구)
- [성능 튜닝](#성능-튜닝)
- [보안 유지보수](#보안-유지보수)
- [비용 관리](#비용-관리)

## 일일 운영

### 예약된 실행
**빈도**: 매일 오전 7시 (KST)  
**예상 소요 시간**: 5-15초  
**성공 기준**: 실행 상태 "Succeeded"

### 상태 확인 루틴
```bash
# 마지막 실행 상태 확인
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs?api-version=2016-06-01" \
  | jq '.value[0] | {status: .properties.status, startTime: .properties.startTime, endTime: .properties.endTime}'
```

**예상 출력**:
```json
{
  "status": "Succeeded",
  "startTime": "2026-01-03T22:00:00Z",
  "endTime": "2026-01-03T22:00:12Z"
}
```

### 액션 확인
```bash
# 각 액션 상태 확인
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs/{run-id}/actions?api-version=2016-06-01" \
  | jq '.value[] | {name: .name, status: .properties.status}'
```

**예상 액션**:
- ✅ Query_APIM_Logs: Succeeded
- ✅ Condition_Check_Errors: Succeeded
- ✅ Post_Teams_Notification: Succeeded (오류 감지 시)
- ✅ Send_Email_Alert: Succeeded (오류 감지 시)
- ✅ Create_DevOps_Work_Item_HTTP: Succeeded (오류 감지 시)

## 모니터링 및 알림

### Azure Monitor 통합

#### 실행 실패 알림 구성
```bash
# 알림을 위한 작업 그룹 생성
az monitor action-group create \
  --name "LogicApp-Alerts" \
  --resource-group "{rg}" \
  --short-name "LA-Alert" \
  --email ops ops@example.com

# 경고 규칙 생성
az monitor metrics alert create \
  --name "LogicApp-Failed-Runs" \
  --resource-group "{rg}" \
  --scopes "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}" \
  --condition "count RunsFailed > 0" \
  --window-size 1h \
  --evaluation-frequency 15m \
  --action "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Insights/actionGroups/LogicApp-Alerts"
```

### Application Insights (선택사항)

#### 진단 설정 활성화
```bash
az monitor diagnostic-settings create \
  --name "LogicApp-Diagnostics" \
  --resource "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}" \
  --workspace "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{law-name}" \
  --logs '[{"category": "WorkflowRuntime", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

#### 실행 추세 쿼리
```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.LOGIC"
| where Category == "WorkflowRuntime"
| where status_s == "Failed"
| summarize FailureCount = count() by bin(TimeGenerated, 1d)
| render timechart
```

### 핵심 성능 지표 (KPI)

| 지표 | 목표 | 경고 임계값 |
|------|------|------------|
| 성공률 | >95% | <90% |
| 실행 시간 | <30초 | >60초 |
| 쿼리 지연 시간 | <5초 | >10초 |
| 오류 감지율 | N/A | 오탐 모니터링 |

## 문제 해결

### 일반적인 문제 및 해결 방법

#### 문제 1: Logic App 실행 실패
**증상**: 실행 상태가 "Failed"로 표시됨

**진단**:
```bash
# 오류 세부 정보 가져오기
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs/{run-id}?api-version=2016-06-01" \
  | jq '.properties.outputs'
```

**일반적인 원인**:
1. API 연결 만료됨 (Teams, Outlook)
2. 관리 ID 권한 취소됨
3. 쿼리 구문 오류
4. 시간 초과

**해결 방법**:
- API 연결 재인증
- 관리 ID 역할 할당 확인
- Log Analytics에서 쿼리 테스트
- 필요시 시간 초과 증가

#### 문제 2: 오류가 감지되지 않음 (오류가 존재하는데도)
**증상**: 워크플로우가 성공적으로 실행되지만 오류가 있을 때 작업 항목을 생성하지 않음

**진단**:
```bash
# 쿼리 액션 출력 확인
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs/{run-id}/actions/Query_APIM_Logs?api-version=2016-06-01" \
  | jq '.properties.outputs.body.tables[0].rows | length'
```

**일반적인 원인**:
1. 쿼리 시간 범위가 너무 좁음
2. Log Analytics 데이터가 아직 수집되지 않음
3. 쿼리 필터링이 너무 공격적임
4. 작업 영역 ID가 잘못됨

**해결 방법**:
- 시간 범위 확장: `ago(24h)` → `ago(48h)`
- 수집을 위해 5-10분 대기
- WHERE 절 필터 검토
- 매개변수에서 작업 영역 ID 확인

#### 문제 3: DevOps 작업 항목이 생성되지 않음
**증상**: Logic App은 성공하지만 작업 항목이 나타나지 않음

**진단**:
```bash
# HTTP 액션 응답 확인
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs/{run-id}/actions/Create_DevOps_Work_Item_HTTP?api-version=2016-06-01" \
  | jq '.properties.outputs'
```

**일반적인 원인**:
1. 관리 ID에 DevOps 권한이 부여되지 않음
2. 인증에서 잘못된 audience
3. DevOps 프로젝트/조직 이름 오타
4. API 버전 비호환성

**해결 방법**:
```bash
# 관리 ID에 권한이 있는지 확인
# DevOps 포털에서 수동 확인 필요

# audience가 올바른지 확인
# 다음이어야 함: 499b84ac-1321-427f-aa17-267ca6975798

# 직접 API 호출 테스트
TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv)
curl -H "Authorization: Bearer $TOKEN" \
  "https://dev.azure.com/{org}/{project}/_apis/wit/workitems?api-version=7.0"
```

#### 문제 4: Teams/이메일이 전송되지 않음
**증상**: 알림 액션이 건너뛰거나 실패함

**진단**:
```bash
# 액션 상태 확인
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs/{run-id}/actions?api-version=2016-06-01" \
  | jq '.value[] | select(.name | contains("Teams") or contains("Email")) | {name: .name, status: .properties.status, error: .properties.error}'
```

**일반적인 원인**:
1. API 연결이 인증되지 않음
2. Teams 채널 ID가 변경됨
3. 이메일 수신자가 유효하지 않음
4. 연결이 만료됨

**해결 방법**:
- Azure Portal에서 연결 재인증
- 채널 ID 확인: Teams → 채널 → 링크 가져오기 → ID 추출
- 이메일 주소 형식 확인
- 필요시 연결 재생성

## 시행착오 및 인사이트 (Lessons Learned)

### 1. Azure DevOps 인증 방식
**문제**: Managed Identity를 사용하여 ADO API를 호출할 때 401/403 오류 발생.
**원인**: ADO 조직 정책 또는 권한 전파 지연으로 인해 MSI 인증이 불안정함.
**해결**: **PAT (Personal Access Token)** 기반의 Basic Auth로 전환.
- 헤더: `Authorization: Basic {Base64-PAT}`
- 안정성: 100% 성공률 보장
- **교훈**: ADO 통합 시 복잡한 MSI 설정보다 PAT가 초기 구축 및 디버깅에 훨씬 효율적임.

### 2. 메시지 인코딩 및 이모지
**문제**: Teams 및 이메일 발송 시 한글이 깨지거나 이모지가 `??`로 표시됨.
**원인**: `az rest` 명령어로 배포 시 로컬 쉘의 인코딩 설정이 JSON 본문에 영향을 줌.
**해결**: 
- ARM 템플릿 파일 자체를 **UTF-8**로 저장.
- 이모지는 HTML 엔티티 코드 사용 (예: `🚨` → `&#128680;`).
- **교훈**: 크로스 플랫폼 배포 시 특수문자는 반드시 이스케이프 처리하거나 HTML 엔티티를 사용해야 함.

### 3. 배포 방식의 중요성
**문제**: 복잡한 Logic App 워크플로우를 `az rest`로 직접 업데이트하면 JSON 파싱 오류 발생.
**해결**: `az deployment group create` (ARM 템플릿 배포) 사용.
- **교훈**: 워크플로우 정의가 복잡해질수록 명령형(Imperative) 방식보다 선언형(Declarative) ARM 템플릿 배포가 훨씬 안정적임.

## 업데이트 절차

### 일정 수정
```bash
# 매개변수 파일 업데이트
cat > schedule-update.json << EOF
{
  "scheduleHour": {
    "value": "9"
  }
}
EOF

# 업데이트된 일정으로 배포
az deployment group create \
  --resource-group "{rg}" \
  --template-file logicapp-deployment.json \
  --parameters @parameters.json \
  --parameters @schedule-update.json \
  --mode Incremental \
  --name "Schedule-Update-$(date +%Y%m%d%H%M%S)"
```

### 쿼리 로직 업데이트
```bash
# 템플릿 파일 편집
# 다음에서 KQL 쿼리 수정:
# resources[3].properties.definition.actions.Query_APIM_Logs.inputs.body.query

# 업데이트 배포
az deployment group create \
  --resource-group "{rg}" \
  --template-file logicapp-deployment.json \
  --parameters @parameters.json \
  --mode Incremental
```

### 새 알림 채널 추가
1. ARM 템플릿 편집
2. `actions` 섹션에 새 액션 추가
3. `runAfter` 종속성 업데이트
4. Azure CLI를 통해 배포

### DevOps 담당자 변경
```bash
# 매개변수 파일 업데이트
{
  "devOpsAssignee": {
    "value": "new-assignee@example.com"
  }
}

# 재배포
az deployment group create \
  --resource-group "{rg}" \
  --template-file logicapp-deployment.json \
  --parameters @parameters.json \
  --mode Incremental
```

## 백업 및 복구

### 백업 전략

#### 1. ARM 템플릿 백업
```bash
# 현재 구성 내보내기
az logic workflow show \
  --name "{logic-app-name}" \
  --resource-group "{rg}" \
  > backup-$(date +%Y%m%d).json
```

#### 2. Git 저장소
- 모든 템플릿이 GitHub에 저장됨
- Git 태그를 통한 버전 제어
- 브랜치 보호 활성화됨

#### 3. 매개변수 백업
```bash
# 매개변수 파일 암호화 (민감한 데이터 포함)
gpg --encrypt --recipient ops@example.com parameters.json

# 암호화된 파일을 안전하게 저장 (Azure Key Vault 등)
az keyvault secret set \
  --vault-name "{keyvault-name}" \
  --name "logicapp-parameters" \
  --file parameters.json.gpg
```

### 복구 절차

#### 시나리오 1: 실수로 삭제
```bash
# Git에서 재배포
git clone https://github.com/zer0big/azure-secops-automation-demo.git
cd azure-secops-automation-demo

# 배포
az deployment group create \
  --resource-group "{rg}" \
  --template-file logicapp-deployment.json \
  --parameters @parameters.json
```

#### 시나리오 2: 구성 손상
```bash
# 백업에서 복원
az deployment group create \
  --resource-group "{rg}" \
  --template-file backup-20260103.json \
  --mode Complete  # 주의: 기존 항목을 덮어씁니다
```

#### 시나리오 3: 지역 장애
```bash
# 대체 지역에 배포
az deployment group create \
  --resource-group "{rg-dr}" \
  --template-file logicapp-deployment.json \
  --parameters location="westus2" \
  --parameters @parameters.json
```

## 성능 튜닝

### 쿼리 성능 최적화
```kusto
-- 현재 쿼리 (기준선)
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| where ResponseCode != 200
| take 50

-- 최적화된 쿼리 (인덱싱 힌트 포함)
ApiManagementGatewayLogs
| where TimeGenerated > ago(24h)
| where ResponseCode >= 400  -- 더 구체적인 필터
| project-away Cache, Errors  -- 데이터 전송 감소
| take 50
```

### 실행 시간 단축
1. **쿼리 결과 제한**: `take 100` 대신 `take 50` 사용
2. **병렬 액션**: 알림이 병렬로 실행되도록 보장
3. **시간 초과 설정**: 느린 쿼리의 경우 증가

### 확장 고려사항
- **현재 부하**: 1회 실행/일 = 무시 가능
- **시간별로 확장**: 24회 실행/일 = 여전히 낮음
- **다중 지역으로 확장**: 지역당 별도의 Logic App 배포

## 보안 유지보수

### 월간 보안 검토

#### 1. 관리 ID 권한 검토
```bash
# 역할 할당 나열
az role assignment list \
  --assignee $(az logic workflow show --name "{logic-app-name}" --resource-group "{rg}" --query "identity.principalId" -o tsv) \
  --all -o table
```

**예상 역할**:
- Log Analytics Reader (작업 영역 범위)
- (수동) Work Item Writer (DevOps 범위)

#### 2. API 연결 권한 검토
- 이동: Azure Portal → 연결
- 각 연결(teams, outlook)에 유효한 인증이 있는지 확인
- "Unauthorized"로 표시되면 재인증

#### 3. 실행 기록 감사
```bash
# 비정상적인 패턴 확인
az rest --method GET \
  --uri "https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Logic/workflows/{logic-app-name}/runs?api-version=2016-06-01&\$top=100" \
  | jq '.value | group_by(.properties.status) | map({status: .[0].properties.status, count: length})'
```

### 분기별 보안 작업
- 수동으로 관리되는 비밀 순환 (해당하는 경우)
- DevOps 작업 항목 권한 검토
- 이메일 수신자 목록 감사
- Teams 채널 액세스 확인

## 비용 관리

### 현재 비용 프로필
**예상 월간 비용** (2026년 1월 기준):

| 구성요소 | 사용량 | 단가 | 월간 비용 |
|---------|--------|------|----------|
| Logic App 실행 | 30회/월 | $0.000025 | $0.00075 |
| Log Analytics 쿼리 | 30개 쿼리 | 포함됨 | $0 |
| API 연결 | 3개 연결 | $0.05/연결 | $0.15 |
| **합계** | | | **~$0.15/월** |

### 비용 최적화 팁
1. **빈번한 실행 방지**: 일일 실행이 최적
2. **쿼리 결과 제한**: `take 50`으로 데이터 전송 감소
3. **관리 ID 사용**: Key Vault 비용 없음
4. **API 연결 사용량 모니터링**: 사용하지 않는 커넥터 연결 해제

### 비용 모니터링
```bash
# Logic App 비용 보기
az consumption usage list \
  --start-date 2026-01-01 \
  --end-date 2026-01-31 \
  --query "[?contains(instanceName, 'logicapp-apim-aoai-monitoring')]" \
  -o table
```

## 유지보수 체크리스트

### 일일
- [ ] 예약된 실행이 성공적으로 완료되었는지 확인
- [ ] DevOps에서 오류 작업 항목 확인

### 주간
- [ ] 실패에 대한 실행 기록 검토
- [ ] 알림 수신 확인 (Teams/이메일)

### 월간
- [ ] 관리 ID 권한 검토
- [ ] API 연결 인증 확인
- [ ] 쿼리 성능 감사
- [ ] 비용 대시보드 검토

### 분기별
- [ ] 보안 검토 (권한, 액세스)
- [ ] 변경 사항이 있는 경우 문서 업데이트
- [ ] 성능 최적화 검토
- [ ] 재해 복구 테스트

### 연간
- [ ] 전체 백업 및 복구 테스트
- [ ] 경고 임계값 검토 및 업데이트
- [ ] 최적화를 위한 새 Azure 기능 평가

---

**문서 버전**: 1.0  
**최종 업데이트**: 2026년 1월 3일  
**관리**: Azure SecOps 팀
