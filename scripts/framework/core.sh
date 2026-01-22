# =====================================
# Universal Script Core Library
# =====================================
# Sourced by all project scripts
# DO NOT execute directly

# -------------------------------------
# Resolve Script Directory (ONCE)
# -------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -------------------------------------
# Plugin Security (must be first)
# -------------------------------------
source "$SCRIPT_DIR/../infrastructure/plugin-security.sh"

# -------------------------------------
# Prevent double-loading
# -------------------------------------
if [[ -n "${CORE_LOADED:-}" ]]; then
  return
fi
CORE_LOADED=1

# -------------------------------------
# Color System (No raw white)
# -------------------------------------
NC='\033[0m'

RED='\033[38;5;196m'
GREEN='\033[38;5;82m'
YELLOW='\033[38;5;220m'
BLUE='\033[38;5;75m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;141m'
GRAY='\033[38;5;244m'
WHITE_SOFT='\033[38;5;250m'

BG_RED='\033[48;5;196;38;5;231m'
BG_GREEN='\033[48;5;82;38;5;232m'

# -------------------------------------
# Logging (emoji-semantic, CI-safe)
# -------------------------------------
log_info()  { echo -e "${CYAN}ℹ️  $*${NC}"; }
log_warn()  { echo -e "${YELLOW}⚠️  $*${NC}"; }
log_error() { echo -e "${RED}❌ $*${NC}"; }
log_step()  { echo -e "${BLUE}▶️  $*${NC}"; }
log_ok()    { echo -e "${GREEN}✔ $*${NC}"; }

die() {
  local msg="$1"
  local code="${2:-1}"
  log_error "$msg"
  exit "$code"
}

# -------------------------------------
# Debugging
# -------------------------------------
DEBUG="${DEBUG:-false}"

debug() {
  [[ "$DEBUG" == "true" ]] && echo -e "${MAGENTA}🐞 DEBUG:${NC} ${GRAY}$*${NC}"
}

# -------------------------------------
# Strict / Trap Mode (opt-in)
# -------------------------------------
enable_strict_mode() {
  set -Eeuo pipefail
}

trap_error() {
  local code=$?
  spinner_stop || true
  log_error "Failure in ${SCRIPT_NAME:-unknown} (exit code $code)"
  exit "$code"
}

enable_traps() {
  trap trap_error ERR
  trap spinner_stop EXIT
}

# -------------------------------------
# Paths & Identity
# -------------------------------------
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
SCRIPT_NAME="$(basename "$0")"

# -------------------------------------
# Project Manifest
# -------------------------------------
load_project_manifest() {
  [[ -f ".project.sh" ]] && source ".project.sh"

  PROJECT_NAME="${PROJECT_NAME:-$(basename "$PROJECT_ROOT")}"
  PROJECT_LANG="${PROJECT_LANG:-unknown}"
  REPO_VISIBILITY="${REPO_VISIBILITY:-private}"
  VERSION_STRATEGY="${VERSION_STRATEGY:-semver}"
  DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
  ENABLE_CI="${ENABLE_CI:-true}"
  ENABLE_DOCKER="${ENABLE_DOCKER:-false}"
}

# -------------------------------------
# Guards & Validation
# -------------------------------------
require_command() {
  command -v "$1" &>/dev/null || die "Missing required command: $1" "$EXIT_ENV"
}

require_file() {
  [[ -f "$1" ]] || die "Required file not found: $1" "$EXIT_CONFIG"
}

has() {
  command -v "$1" &>/dev/null
}

# -------------------------------------
# CI Awareness
# -------------------------------------
is_ci() {
  [[ "${CI:-false}" == "true" ]]
}

confirm() {
  if is_ci; then
    debug "CI auto-confirm: $1"
    return 0
  fi

  echo -ne "${WHITE_SOFT}$1${NC} ${GRAY}[y/N]: ${NC}"
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

# -------------------------------------
# Git Helpers
# -------------------------------------
is_git_repo() {
  git rev-parse --is-inside-work-tree &>/dev/null
}

ensure_git_repo() {
  is_git_repo || git init
}

current_branch() {
  git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

# -------------------------------------
# OS Detection
# -------------------------------------
detect_os() {
  case "$(uname -s)" in
    Linux*) echo "linux" ;;
    Darwin*) echo "macos" ;;
    CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
    *) echo "unknown" ;;
  esac
}

OS="$(detect_os)"

# -------------------------------------
# Phase / UX Helpers
# -------------------------------------
phase() {
  echo
  echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
  echo -e "${CYAN}🚀 $*${NC}"
  echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}"
}

# -------------------------------------
# Spinner Helpers (safe, CI-aware)
# -------------------------------------
_spinner_pid=""

spinner_start() {
  local msg="$1"
  is_ci && return 0

  echo -ne "${CYAN}⏳ $msg ${NC}"
  (
    while true; do
      for c in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do
        echo -ne "\b$c"
        sleep 0.1
      done
    done
  ) &
  _spinner_pid=$!
}

spinner_stop() {
  is_ci && return 0

  if [[ -n "${_spinner_pid:-}" ]]; then
    kill "$_spinner_pid" &>/dev/null || true
    wait "$_spinner_pid" 2>/dev/null || true
    _spinner_pid=""
    echo -ne "\b "
  fi
}

# -------------------------------------
# Timing Helpers
# -------------------------------------
now() { date +%s; }
elapsed() { echo "$(( $(date +%s) - $1 ))s"; }

# -------------------------------------
# File Helpers
# -------------------------------------
ensure_dir() { mkdir -p "$1"; }
safe_rm() { [[ -n "$1" && -e "$1" ]] && rm -rf "$1"; }

# -------------------------------------
# Dry Run Support
# -------------------------------------
DRY_RUN="${DRY_RUN:-false}"

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_warn "[DRY-RUN] $*"
  else
    "$@"
  fi
}

# -------------------------------------
# Version Helpers (Semantic, Validated)
# -------------------------------------
parse_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Invalid semantic version: $1" "$EXIT_LOGIC"
  IFS='.' read -r SEMVER_MAJOR SEMVER_MINOR SEMVER_PATCH <<< "$1"
}

bump_patch() { parse_semver "$1"; echo "$SEMVER_MAJOR.$SEMVER_MINOR.$((SEMVER_PATCH + 1))"; }
bump_minor() { parse_semver "$1"; echo "$SEMVER_MAJOR.$((SEMVER_MINOR + 1)).0"; }
bump_major() { parse_semver "$1"; echo "$((SEMVER_MAJOR + 1)).0.0"; }

# -------------------------------------
# Version Strategy (Bootstrap Only)
# -------------------------------------
initial_version() {
  case "$VERSION_STRATEGY" in
    semver) echo "0.1.0" ;;
    date) date +"%Y.%m.%d" ;;
    incremental) echo "1" ;;
    *) echo "0.0.1" ;;
  esac
}

# -------------------------------------
# Plugin System Link (last)
# -------------------------------------
if [[ -f "$SCRIPT_DIR/plugins/plugin-runner.sh" ]]; then
  source "$SCRIPT_DIR/plugins/plugin-runner.sh"
fi

# -------------------------------------
# Structured Exit Codes
# -------------------------------------
EXIT_CONFIG=10
EXIT_ENV=20
EXIT_LOGIC=30
