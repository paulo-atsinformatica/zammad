#!/bin/bash
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
# Hook: regenerate generated files when their sources change.

# Mesmo arranjo de lint-after-edit.sh: no ambiente Windows o pnpm vive dentro do
# container de desenvolvimento, e sem este fallback o hook só imprimia
# "pnpm: command not found" a cada edição em app/graphql.
CONTAINER=''
if ! command -v pnpm >/dev/null 2>&1; then
  CONTAINER=$(docker ps -q -f name=zc-run 2>/dev/null | head -1)
  [[ -z "$CONTAINER" ]] && exit 0
fi

run_tool() {
  if [[ -n "$CONTAINER" ]]; then
    docker exec "$CONTAINER" bash -lc "cd /app && $*"
  else
    eval "$*"
  fi
}

CHANGED_FILES=$(git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)

NEEDS_GRAPHQL=false
NEEDS_SETTINGS=false

while IFS= read -r file; do
  [[ -z "$file" ]] && continue

  case "$file" in
    app/graphql/*)          NEEDS_GRAPHQL=true ;;
    app/frontend/*.graphql) NEEDS_GRAPHQL=true ;;
    app/models/setting.rb)  NEEDS_SETTINGS=true ;;
    db/seeds/settings.rb)   NEEDS_SETTINGS=true ;;
  esac
done <<< "$CHANGED_FILES"

EXIT_CODE=0

if $NEEDS_GRAPHQL; then
  echo "GraphQL schema changed — regenerating types..." >&2
  run_tool 'pnpm generate-graphql-api' >&2 || EXIT_CODE=2
fi

if $NEEDS_SETTINGS; then
  echo "Settings changed — regenerating types..." >&2
  run_tool 'pnpm generate-setting-types' >&2 || EXIT_CODE=2
fi

exit $EXIT_CODE
