@echo off
echo Android Emulator 업그레이드...
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set ANDROID_HOME=C:\Users\jagua\AppData\Local\Android\Sdk
"%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --install "emulator"
echo.
echo 완료. 아무 키나 누르면 종료됩니다.
pause
