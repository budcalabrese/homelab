#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "Checking for retired-service references..."
if rg -n "victoria-logs|VictoriaLogs|Victoria Logs|fluent-bit|Fluent Bit" \
  AGENTS.md README.md docs n8n-workflows alpine-utility \
  --glob '!docs/planning/**' --glob '!*.png' --glob '!scripts/audit_repo_docs.sh'; then
  fail "Retired logging stack references found in active docs or workflows"
fi

echo "Checking workflow index references..."
while IFS= read -r file; do
  [ -f "$file" ] || fail "Referenced workflow missing: $file"
done < <(grep -oE '`[^`]+\.json`' n8n-workflows/README.md | tr -d '`' | sed 's#^#n8n-workflows/#')

echo "Checking workflow naming conventions..."
while IFS= read -r file; do
  base="$(basename "$file")"
  if [[ "$base" =~ Final|final|copy|Copy|fixed|Fixed|temp|Temp ]]; then
    fail "Workflow filename uses weak naming: $file"
  fi
done < <(find n8n-workflows -maxdepth 1 -type f -name '*.json' | sort)

echo "Checking README markdown links..."
for doc in README.md docs/README.md alpine-utility/README.md n8n-workflows/README.md alpine-utility/scripts/README.md; do
  doc_dir="$(dirname "$doc")"
  while IFS= read -r path; do
    [ -z "$path" ] && continue
    resolved="$doc_dir/$path"
    [ -e "$resolved" ] || fail "$doc references missing path: $path"
  done < <(
    grep -oE '\[[^]]+\]\(([^)#]+)\)' "$doc" \
      | sed -E 's/.*\(([^)#]+)\)/\1/' \
      | grep -vE '^(http|https|mailto:|#)' \
      | sed '/^$/d'
  )
done

echo "Checking critical canonical files..."
[ -f alpine-utility/scripts/docker-monitor.sh ] || fail "Missing canonical docker-monitor script"
[ ! -e alpine-utility/docker-monitor.sh ] || fail "Legacy duplicate docker-monitor.sh exists"

echo "Checking env tracking policy..."
tracked_env="$(git ls-files 'env/*')"
echo "$tracked_env" | grep -q '^env/.env.template$' || fail "env/.env.template must be tracked"
if echo "$tracked_env" | grep -Ev '^env/\.env(\.[^.]+)?\.template$' | grep -q .; then
  fail "Non-template env files are tracked"
fi

echo "Repo audit passed."
