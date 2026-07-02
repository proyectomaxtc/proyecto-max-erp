#!/usr/bin/env bash
set -euo pipefail

if [ -z "${SUPABASE_URL:-}" ]; then
  echo "Missing SUPABASE_URL environment variable"
  exit 1
fi

if [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "Missing SUPABASE_ANON_KEY environment variable"
  exit 1
fi

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi

export PATH="$PATH:$HOME/flutter/bin"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
