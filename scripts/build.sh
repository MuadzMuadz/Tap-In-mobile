#!/bin/bash
# Build script untuk Tap-In Kasir
# Usage: ./scripts/build.sh [run|apk|appbundle]

set -e

SUPABASE_URL="https://uzyzqjwxaqellztmgxxy.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV6eXpxand4YXFlbGx6dG1neHh5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MjgzOTAsImV4cCI6MjA4NzQwNDM5MH0.IamIeYZQUHAjagmcT_cpnxww3elEtb3AVBpGHeMcRJU"

DEFINES="--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

CMD=${1:-run}

case "$CMD" in
  run)
    echo ">> Running app..."
    flutter run $DEFINES
    ;;
  apk)
    echo ">> Building APK release..."
    flutter build apk --release $DEFINES
    echo ""
    echo "APK tersimpan di: build/app/outputs/flutter-apk/app-release.apk"
    ;;
  appbundle)
    echo ">> Building App Bundle release..."
    flutter build appbundle --release $DEFINES
    echo ""
    echo "Bundle tersimpan di: build/app/outputs/bundle/release/app-release.aab"
    ;;
  *)
    echo "Usage: ./scripts/build.sh [run|apk|appbundle]"
    exit 1
    ;;
esac
