# Run FeedERP on web (Windows PowerShell)
# Set your credentials:
$env:SUPABASE_URL      = "https://YOUR_PROJECT_REF.supabase.co"
$env:SUPABASE_ANON_KEY = "your_anon_key_here"

flutter run -d chrome `
  --dart-define="SUPABASE_URL=$env:SUPABASE_URL" `
  --dart-define="SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY"
