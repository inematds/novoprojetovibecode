$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $root ".env"
$outputPath = Join-Path $root "lead-capture-config.js"

if (-not (Test-Path $envPath)) {
  throw ".env nao encontrado em $envPath"
}

$rawLines = Get-Content -Path $envPath -Encoding UTF8
$vars = @{}

foreach ($line in $rawLines) {
  $trimmed = $line.Trim()
  if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
    continue
  }

  $parts = $trimmed -split "=", 2
  if ($parts.Count -ne 2) {
    continue
  }

  $key = $parts[0].Trim()
  $value = $parts[1].Trim()
  $vars[$key] = $value
}

$supabaseUrl = $vars["SUPABASE_URL"]
$supabaseAnonKey = $vars["SUPABASE_ANON_KEY"]

if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
  throw "Defina SUPABASE_URL e SUPABASE_ANON_KEY no .env"
}

$js = @"
window.LEAD_CAPTURE_CONFIG = {
  supabaseUrl: "$supabaseUrl",
  supabaseAnonKey: "$supabaseAnonKey"
};
"@

Set-Content -Path $outputPath -Value $js -Encoding UTF8
Write-Output "Arquivo gerado: $outputPath"
