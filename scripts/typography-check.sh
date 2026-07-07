#!/usr/bin/env bash
# Typography gate — run before every PR.
# Authority: Documentation/PORTEOS INTELLIGENCE v2.06 — FONT SPECIFICATION.md
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIEWS="$ROOT/PorteosIntelligence"
FAIL=0

check() {
  local desc="$1" pattern="$2"
  local hits
  hits=$(rg -n "$pattern" "$VIEWS" --glob '*.swift' \
    --glob '!**/DesignTokens.swift' \
    --glob '!**/PorteosTextStyle.swift' \
    --glob '!**/PorteosFontLoader.swift' 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    echo "FAIL: $desc"
    echo "$hits"
    FAIL=1
  else
    echo "OK:   $desc"
  fi
}

check 'No raw JetBrains .custom() in views' '\.custom\("JetBrains Mono"'
check 'No DesignTokens.mono() in views' 'DesignTokens\.mono\('
check 'No Font.system' 'Font\.system'
check 'No SwiftUI semantic fonts' '\.font\(\.(headline|body|caption|subheadline|title[23]?)\)'

check 'No raw DesignTokens.font() in views' '\.font\(DesignTokens'

HITS=$(rg -n '\.tracking\(' "$VIEWS" --glob '*.swift' \
  --glob '!**/PorteosTextStyle.swift' \
  --glob '!**/TerminalButtonStyle.swift' 2>/dev/null || true)
if [[ -n "$HITS" ]]; then
  echo "FAIL: No ad-hoc tracking overrides"
  echo "$HITS"
  FAIL=1
else
  echo "OK:   No ad-hoc tracking overrides"
fi

if [[ $FAIL -ne 0 ]]; then
  echo ""
  echo "Fix: use PorteosText(\"…\", style: .metricValue) or .porteosTextStyle(.meta)"
  echo "See PorteosIntelligence/Utilities/PorteosTextStyle.swift"
  exit 1
fi

echo ""
echo "Typography gate passed."
