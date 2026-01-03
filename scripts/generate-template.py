#!/usr/bin/env python3
"""
Azure DevOps Work Item 생성을 위한 Logic App ARM 템플릿 생성 스크립트
HTTP 액션으로 REST API 직접 호출 방식
"""

import json
from datetime import datetime

# 기존 템플릿 로드
with open('deploy-test-24h.json', 'r', encoding='utf-8-sig') as f:
    template = json.load(f)

# HTTP 액션으로 DevOps Work Item 생성 (Managed Identity 인증)
devops_action_http = {
    "type": "Http",
    "inputs": {
        "method": "POST",
        "uri": "https://dev.azure.com/azure-mvp/prj-ticketGEN-demo-20260103/_apis/wit/workitems/$Issue?api-version=7.0",
        "headers": {
            "Content-Type": "application/json-patch+json"
        },
        "authentication": {
            "type": "ManagedServiceIdentity"
        },
        "body": [
            {
                "op": "add",
                "path": "/fields/System.Title",
                "value": "@{concat('APIM 에러 감지 - ', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[4], ' 에러 발생')}"
            },
            {
                "op": "add",
                "path": "/fields/System.Description",
                "value": "@{concat('<h2>🔴 APIM 에러 알림</h2><table border=\"1\" cellpadding=\"5\"><tr><th>항목</th><th>값</th></tr><tr><td><b>발생 시간 (KST)</b></td><td>', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[0], '</td></tr><tr><td><b>Response Code</b></td><td>', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[4], '</td></tr><tr><td><b>URL</b></td><td>', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[9], '</td></tr><tr><td><b>CorrelationId</b></td><td>', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[2], '</td></tr><tr><td><b>Caller IP</b></td><td>', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[7], '</td></tr><tr><td><b>Error Message</b></td><td>', body('Query_APIM_Logs')?['tables']?[0]?['rows']?[0]?[10], '</td></tr></table><br/><h3>총 감지된 에러: ', length(body('Query_APIM_Logs')?['tables']?[0]?['rows']), ' 건</h3>')}"
            },
            {
                "op": "add",
                "path": "/fields/System.AssignedTo",
                "value": "azure-mvp@zerobig.kr"
            },
            {
                "op": "add",
                "path": "/fields/Microsoft.VSTS.Common.Priority",
                "value": 2
            },
            {
                "op": "add",
                "path": "/fields/Microsoft.VSTS.Common.Severity",
                "value": "2 - High"
            }
        ]
    },
    "runAfter": {
        "Condition_Check_Errors": ["Succeeded"]
    }
}

# Logic App 리소스에서 actions 섹션 찾기
logic_app_resource = template['resources'][3]
actions = logic_app_resource['properties']['definition']['actions']

# 기존 Create_DevOps_Work_Item 액션 삭제 (중복 방지)
if 'Create_DevOps_Work_Item' in actions:
    del actions['Create_DevOps_Work_Item']

# 새로운 HTTP 기반 DevOps Work Item 액션 추가
actions['Create_DevOps_Work_Item_HTTP'] = devops_action_http

# 저장
output_file = 'deploy-devops-http.json'
with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(template, f, indent=2, ensure_ascii=False)

print(f"✅ DevOps HTTP 액션 템플릿 생성 완료!")
print(f"   파일: {output_file}")
print(f"   - HTTP 액션 (Managed Identity 인증)")
print(f"   - Organization: azure-mvp")
print(f"   - Project: prj-ticketGEN-demo-20260103")
print(f"   - Work Item Type: Issue")
print(f"   - AssignedTo: azure-mvp@zerobig.kr")
print(f"   - Priority: 2, Severity: 2 - High")
