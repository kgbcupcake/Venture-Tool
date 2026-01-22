#!/bin/bash
set -e

# 1. Clear guards to force a fresh load of the API
unset CORE_LOADED

# 2. Establish the Project Root (Absolute path)
# This finds the folder ABOVE 'scripts'
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 3. Source the libraries using the root anchor
source "$PROJECT_ROOT/scripts/framework/core.sh"
source "$PROJECT_ROOT/scripts/framework/core-extended.sh"

# 4. Now the command will be found
assert_core_api_version "1.0.0"
load_project_manifest
enable_traps

# Helper to parse the .plugin registry files (ini-like format)
read_registry_manifest() {
  local plugin_name="$1"
  local registry_file="$SCRIPT_DIR/registry/${plugin_name}.plugin"
  
  if [[ -f "$registry_file" ]]; then
    # Extract keys like 'requires' or 'phase'
    grep "^$2=" "$registry_file" | cut -d'=' -f2
  fi
}

run_plugins() {
  local phase="$1"
  local dir="$SCRIPT_DIR/plugins/$phase"

  [[ -d "$dir" ]] || return 0

  log_step "🔌 PLUGINS: Initializing $phase phase..."

  for plugin_script in "$dir"/*.sh; do
    [[ -x "$plugin_script" ]] || continue
    
    local name=$(basename "$plugin_script" .sh)
    
    # 1. LINK: Check Registry for metadata
    local requires=$(read_registry_manifest "$name" "requires")
    
    # 2. VALIDATION: Check dependencies defined in Registry
    if [[ -n "$requires" ]]; then
      for tool in $requires; do
        if ! command -v "$tool" &>/dev/null; then
          log_warn "⏩ Skipping $name: Missing required tool '$tool'"
          continue 2 # Skip to next plugin
        fi
      done
    fi

    # 3. EXECUTION
    log_info "Running plugin: $name"
    "$plugin_script" || die "Plugin $name failed execution"
  done
}