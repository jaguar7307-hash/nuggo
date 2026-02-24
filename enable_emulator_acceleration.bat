@echo off
:: Android 에뮬레이터 하드웨어 가속 활성화 스크립트
:: 관리자 권한으로 실행 필요

echo ========================================
echo Android 에뮬레이터 가상화 설정 활성화
echo ========================================
echo.

:: 1. Windows Hypervisor Platform 활성화
echo [1/2] Windows Hypervisor Platform 활성화 중...
DISM /Online /Enable-Feature /FeatureName:HypervisorPlatform /All /NoRestart
if %ERRORLEVEL% NEQ 0 (
    echo 오류: HypervisorPlatform 활성화 실패
    echo 관리자 권한으로 실행했는지 확인하세요.
    pause
    exit /b 1
)
echo 완료.
echo.

:: 2. 가상 머신 플랫폼 활성화 (선택)
echo [2/2] 가상 머신 플랫폼 활성화 중...
DISM /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart
if %ERRORLEVEL% NEQ 0 (
    echo 경고: VirtualMachinePlatform 활성화 실패 (이미 활성화되었을 수 있음)
) else (
    echo 완료.
)
echo.

echo ========================================
echo 설정이 완료되었습니다.
echo 적용을 위해 PC 재부팅이 필요합니다.
echo 재부팅 후 에뮬레이터를 다시 실행해 보세요.
echo ========================================
pause
