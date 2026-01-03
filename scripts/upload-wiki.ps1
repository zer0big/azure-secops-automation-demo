# Wiki 업로드 스크립트
$ErrorActionPreference = "Continue"

Write-Host "=================================================="
Write-Host "Wiki 업로드 스크립트 시작"
Write-Host "=================================================="

# 파일 읽기
$filePath = 'E:\Azure\2026\Azure-HandsOn\20260101-APIMangement\ticketGEN-Demo-20260103\logicapp-plan.md'
$content = Get-Content $filePath -Raw

Write-Host "파일 읽음: $filePath"
Write-Host "파일 크기: $($content.Length) bytes"

# 마크다운 래퍼 제거
if ($content.StartsWith('````markdown')) {
    $content = $content.Substring('````markdown'.Length)
    $content = $content.TrimStart("`r", "`n")
}

if ($content.EndsWith('````')) {
    $content = $content.Substring(0, $content.Length - 4)
    $content = $content.TrimEnd("`r", "`n")
}

Write-Host "정제 후 크기: $($content.Length) bytes"
Write-Host "Azure DevOps 포함: $(if ($content -match 'Azure DevOps') { '✓' } else { '✗' })"

# Wiki 업로드
$org = "azure-mvp"
$project = "prj-ticketGEN-demo-20260103"
$wiki = "$project.wiki"
$path = "/APIM-LogicApp"
$uri = "https://dev.azure.com/$org/$project/_apis/wiki/wikis/$wiki/pages?path=$([Uri]::EscapeDataString($path))&api-version=7.0"

Write-Host "`n업로드 정보:"
Write-Host "  조직: $org"
Write-Host "  프로젝트: $project"
Write-Host "  Wiki: $wiki"
Write-Host "  경로: $path"
Write-Host "  URI: $uri"

$body = @{
    content = $content
} | ConvertTo-Json -Depth 100 -Compress:$false

Write-Host "`nJSON 바디 크기: $($body.Length) bytes"
Write-Host "업로드 중..."

try {
    $response = Invoke-RestMethod `
        -Uri $uri `
        -Method Put `
        -ContentType "application/json; charset=utf-8" `
        -Body $body `
        -TimeoutSec 120 `
        -ErrorAction Stop
    
    Write-Host ""
    Write-Host "=================================================="
    Write-Host "✅ 성공! Wiki 페이지 업로드 완료"
    Write-Host "=================================================="
    Write-Host "페이지 ID: $($response.id)"
    Write-Host "경로: $($response.path)"
    Write-Host ""
    Write-Host "🔗 링크:"
    Write-Host "https://dev.azure.com/$org/$project/_wiki/wikis/$wiki.wiki?pagePath=$([Uri]::EscapeDataString($path))"
    Write-Host "=================================================="
    
} catch {
    Write-Host ""
    Write-Host "=================================================="
    Write-Host "❌ 오류 발생!"
    Write-Host "=================================================="
    Write-Host "유형: $($_.GetType().FullName)"
    Write-Host "메시지: $($_.Exception.Message)"
    Write-Host "응답: $($_)"
    Write-Host "=================================================="
    exit 1
}

exit 0
