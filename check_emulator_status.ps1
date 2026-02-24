# 에뮬레이터 가상화 상태 확인 스크립트
Write-Host "`n=== Android 에뮬레이터 가상화 상태 확인 ===" -ForegroundColor Cyan
Write-Host ""

# HypervisorPlatform
$hp = Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -ErrorAction SilentlyContinue
if ($hp) {
    $status = if ($hp.State -eq "Enabled") { "활성화됨" } else { "비활성화됨" }
    Write-Host "Windows Hypervisor Platform: $status"
} else {
    Write-Host "Windows Hypervisor Platform: 확인 불가 (관리자 권한 필요)"
}

# VirtualMachinePlatform
$vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
if ($vmp) {
    $status = if ($vmp.State -eq "Enabled") { "활성화됨" } else { "비활성화됨" }
    Write-Host "가상 머신 플랫폼: $status"
}

# SystemInfo Hyper-V
Write-Host "`n시스템 정보 (Hyper-V):"
systeminfo | Select-String -Pattern "Hyper-V"
