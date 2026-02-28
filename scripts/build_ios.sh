#!/bin/bash
# iOS 릴리즈 빌드 스크립트 (키는 dart_defines.env에서 읽음)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/dart_defines.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌ $ENV_FILE 파일이 없습니다. dart_defines.env를 생성해주세요."
  exit 1
fi

# env 파일 읽어서 dart-define 인자 생성
DART_DEFINES=""
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#.*$ ]] && continue
  [[ -z "$key" ]] && continue
  DART_DEFINES="$DART_DEFINES --dart-define=$key=$value"
done < "$ENV_FILE"

cd "$ROOT_DIR/nuggo_flutter"
echo "✅ iOS 릴리즈 빌드 시작..."
flutter build ios --release $DART_DEFINES
echo "✅ 빌드 완료: build/ios/iphoneos/Runner.app"
