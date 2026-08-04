#!/bin/bash
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Hook: lint all changed/new files with the appropriate tools.
# Collects modified and untracked files from git, then runs the matching linters.

# A toolchain (bundle/pnpm) nem sempre está no PATH do host: no ambiente Windows
# ela vive dentro do container de desenvolvimento. run_tool executa direto quando
# as ferramentas estão disponíveis e, caso contrário, dentro do container. Sem
# nenhum dos dois o hook sai sem erro — bloquear a edição por falta de ferramenta
# só produz ruído a cada turno.
CONTAINER=''
if ! { command -v bundle >/dev/null 2>&1 && command -v pnpm >/dev/null 2>&1; }; then
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

# Aspas simples em cada caminho: dentro do container os argumentos são
# reinterpretados por um shell, então nome com espaço quebraria sem isto.
quote_files() {
  local file
  for file in "$@"; do
    printf " '%s'" "$file"
  done
}

RUBY_FILES=()
FRONTEND_TS_FILES=()
FRONTEND_JS_FILES=()
COFFEESCRIPT_FILES=()
STYLE_FILES=()
MARKDOWN_FILES=()
EXIT_CODE=0

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  case "$file" in
    *.rb)         RUBY_FILES+=("$file") ;;
    *.ts|*.vue)   FRONTEND_TS_FILES+=("$file") ;;
    *.js)         [[ "$file" == public/* ]] || FRONTEND_JS_FILES+=("$file") ;;
    *.coffee)     COFFEESCRIPT_FILES+=("$file") ;;
    *.scss|*.css) STYLE_FILES+=("$file") ;;
    *.md)         MARKDOWN_FILES+=("$file") ;;
  esac
done < <(git diff --name-only --diff-filter=ACMR HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null)

FRONTEND_ALL_FILES=("${FRONTEND_TS_FILES[@]}" "${FRONTEND_JS_FILES[@]}")

if [[ ${#RUBY_FILES[@]} -gt 0 ]]; then
  run_tool "bundle exec rubocop --autocorrect$(quote_files "${RUBY_FILES[@]}")" >&2 || EXIT_CODE=2
fi

if [[ ${#FRONTEND_ALL_FILES[@]} -gt 0 ]]; then
  FRONTEND_ARGS=$(quote_files "${FRONTEND_ALL_FILES[@]}")
  { run_tool "pnpm lint:js:oxlint:cmd --fix${FRONTEND_ARGS}" && \
    run_tool "pnpm lint:js:eslint:cmd --fix${FRONTEND_ARGS}" && \
    { run_tool "pnpm format:cmd${FRONTEND_ARGS}"; _fmt_rc=$?; (( _fmt_rc == 0 || _fmt_rc == 2 )); }; } >&2 || EXIT_CODE=2
fi

if [[ ${#FRONTEND_TS_FILES[@]} -gt 0 ]]; then
  run_tool 'pnpm lint:ts' >&2 || EXIT_CODE=2
fi

if [[ ${#COFFEESCRIPT_FILES[@]} -gt 0 ]]; then
  run_tool "coffeelint --reporter=csv --rules ./.dev/coffeelint/rules/detect_translatable_string.coffee$(quote_files "${COFFEESCRIPT_FILES[@]}")" >&2 || EXIT_CODE=2
fi

if [[ ${#STYLE_FILES[@]} -gt 0 ]]; then
  run_tool "pnpm lint:css:cmd --fix$(quote_files "${STYLE_FILES[@]}")" >&2 || EXIT_CODE=2
fi

if [[ ${#MARKDOWN_FILES[@]} -gt 0 ]]; then
  run_tool "pnpm lint:md:cmd --fix$(quote_files "${MARKDOWN_FILES[@]}")" >&2 || EXIT_CODE=2
fi

exit $EXIT_CODE
