#!/usr/bin/env bash
set -euo pipefail

flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

if [[ "${1:-}" == "--build-android" ]]; then
  flutter build apk --debug
fi

echo "Repository verification completed successfully."
