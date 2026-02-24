#!/bin/bash
# Nuggo 앱을 **무선(Wi‑Fi)**으로 연결된 아이폰(YS의 iPhone)에서 실행합니다.
#
# [무선 연결 설정 방법]
# 1. 아이폰을 USB로 맥에 한 번 연결
# 2. Xcode 실행 → Window → Devices and Simulators (⇧⌘2)
# 3. 왼쪽에서 "YS의 iPhone" 선택 후 "Connect via network" 체크
# 4. 케이블 분리 후, 맥과 아이폰이 같은 Wi‑Fi에 연결되어 있으면 무선으로 인식됨

cd "$(dirname "$0")"
flutter run -d "00008130-000918EA14A2001C" --release --device-timeout=60
