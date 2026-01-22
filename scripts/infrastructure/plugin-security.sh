#!/usr/bin/env bash

PLUGIN_VERIFY="${PLUGIN_VERIFY:-true}"
PLUGIN_KEY_FILE="$SCRIPT_DIR/infrastructure/plugin.key"

verify_plugin() {
  local plugin="$1"

  [[ "$PLUGIN_VERIFY" == "true" ]] || return 0
  [[ -f "$PLUGIN_KEY_FILE" ]] || die "Plugin key missing"

  local sig="${plugin}.sig"
  [[ -f "$sig" ]] || die "Missing signature for $(basename "$plugin")"

  openssl dgst -sha256 -verify "$PLUGIN_KEY_FILE" \
    -signature "$sig" "$plugin" >/dev/null 2>&1 \
    || die "Plugin verification failed: $(basename "$plugin")"
}
