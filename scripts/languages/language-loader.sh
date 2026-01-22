#!/usr/bin/env bash

LANGUAGE_HANDLERS=()

load_languages() {
  for f in "$SCRIPT_DIR/languages/"*.sh; do
    [[ -f "$f" ]] || continue
    source "$f"
    if language_detect; then
      LANGUAGE_HANDLERS+=("$f")
    fi
  done
}

run_language_builds() {
  for f in "${LANGUAGE_HANDLERS[@]}"; do
    source "$f"
    log_info "Building via $(language_name)"
    language_build
  done
}

run_language_tests() {
  for f in "${LANGUAGE_HANDLERS[@]}"; do
    source "$f"
    log_info "Testing via $(language_name)"
    language_test
  done
}
#!/usr/bin/env bash

run_language_ship_extensions() {
  for f in "$SCRIPT_DIR/languages/ship-"*.sh; do
    [[ -f "$f" ]] || continue
    source "$f"
    language_ship
  done
}
