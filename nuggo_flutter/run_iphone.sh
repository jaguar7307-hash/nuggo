#!/bin/bash
# Nuggo 앱을 연결된 아이폰(YS의 iPhone)에서 실행합니다.
# --release: 케이블 없이도 앱이 정상 동작 (디버거 연결 불필요)

cd "$(dirname "$0")"
flutter run -d "00008130-000918EA14A2001C" --release
