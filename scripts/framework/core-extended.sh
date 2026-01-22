# =====================================
# Core Extended Framework Layer
# =====================================
# Requires: core.sh
# Optional, opinionated, evolvable

# -------------------------------------
# Guard
# -------------------------------------
[[ -z "${CORE_LOADED:-}" ]] && {
  echo "core-extended.sh requires core.sh to be sourced first"
  exit 99
}


# -------------------------------------
# Core API Versioning
# -------------------------------------
CORE_API_VERSION="1.0.0"
export CORE_API_VERSION

assert_core_api_version() {
  local required="$1"
  [[ "$CORE_API_VERSION" == "$required" ]] || \
    die "Core API mismatch (need $required, have $CORE_API_VERSION)" "$EXIT_LOGIC"
}
assert_core_api() {
  assert_core_api_version "$@"
}

# -------------------------------------
# Logging Mode (TEXT | JSON)
# -------------------------------------
LOG_FORMAT="${LOG_FORMAT:-text}"

log_json() {
  printf '{"ts":%s,"level":"%s","msg":"%s"}\n' \
    "$(date +%s)" "$1" "${2//\"/\\\"}"
}

log_info() {
  [[ "$LOG_FORMAT" == "json" ]] && log_json info "$*" || \
    echo -e "${CYAN}ℹ️  $*${NC}"
}

log_warn() {
  [[ "$LOG_FORMAT" == "json" ]] && log_json warn "$*" || \
    echo -e "${YELLOW}⚠️  $*${NC}"
}

log_error() {
  [[ "$LOG_FORMAT" == "json" ]] && log_json error "$*" || \
    echo -e "${RED}❌ $*${NC}"
}

# -------------------------------------
# Spinner Auto-Wiring
# -------------------------------------
with_spinner() {
  local msg="$1"; shift
  spinner_start "$msg"
  "$@"
  spinner_stop
}

# -------------------------------------
# Plugin Permission Model
# -------------------------------------
declare -A PLUGIN_PERMS

register_plugin() {
  local name="$1"
  local perms="$2"
  PLUGIN_PERMS["$name"]="$perms"
}

require_plugin_perm() {
  local plugin="$1"
  local perm="$2"
  [[ "${PLUGIN_PERMS[$plugin]}" == *"$perm"* ]] || \
    die "Plugin '$plugin' lacks permission: $perm" "$EXIT_LOGIC"
}

# -------------------------------------
# Shell Test Harness
# -------------------------------------
TESTS_PASSED=0
TESTS_FAILED=0

test_case() {
  local name="$1"; shift
  if "$@"; then
    log_ok "TEST PASS: $name"
    ((TESTS_PASSED++))
  else
    log_error "TEST FAIL: $name"
    ((TESTS_FAILED++))
  fi
}

test_summary() {
  echo
  log_info "Tests passed: $TESTS_PASSED"
  log_info "Tests failed: $TESTS_FAILED"
  [[ "$TESTS_FAILED" -eq 0 ]]
}

# -------------------------------------
# Framework Self-Documentation
# -------------------------------------
core_help() {
  cat <<EOF
🚀 Core Framework (API $CORE_API_VERSION)

Core:
  - Logging, colors, guards
  - Version helpers
  - CI awareness
  - Plugin loader

Extended:
  - JSON logging
  - Plugin permissions
  - Spinner wrappers
  - Test harness
  - Framework introspection

Environment:
  LOG_FORMAT=text|json
  DEBUG=true|false
EOF
}
