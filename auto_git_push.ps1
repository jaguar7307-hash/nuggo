# Nuggo 프로젝트 자동 Git 커밋 & 푸시 스크립트
# Windows 작업 스케줄러에서 30분마다 실행됨

$repoPath = "C:\Users\jagua\Desktop\nuggo"
$logFile  = "C:\Users\jagua\Desktop\nuggo\auto_git_push.log"

Set-Location $repoPath

# 변경사항 있는지 확인
$status = git status --porcelain
if ($status) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git add .
    git commit -m "auto: $timestamp"
    git push origin main

    $result = if ($LASTEXITCODE -eq 0) { "SUCCESS" } else { "PUSH FAILED" }
    Add-Content -Path $logFile -Value "[$timestamp] $result"
} else {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    Add-Content -Path $logFile -Value "[$timestamp] no changes"
}
