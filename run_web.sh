#!/bin/bash
# Run FeedERP on web with Supabase credentials
source .env 2>/dev/null || true

flutter run -d chrome \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
