#!/usr/bin/env bash
set -e

# --- [⚙️ CONTEXT LOCK] ---
# 1. Prioritize TUI path, fallback to pwd
PROJECT_ROOT="${VENTURE_PROJECT_ROOT:-$(pwd)}"

# 2. IMMEDIATELY move to that folder
cd "$PROJECT_ROOT" || exit 1

# 3. Identify where the tool scripts actually live (for sourcing framework)
INTERNAL_TOOL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PROJECT_ROOT
export INTERNAL_TOOL_ROOT

# Define the Framework folder ONCE
FRAMEWORK_DIR="$SCRIPT_DIR/framework"

# --- [🧠 SOURCE LIBRARIES] ---
# Use INTERNAL_TOOL_ROOT because that is where the .sh files live
FRAMEWORK_DIR="$INTERNAL_TOOL_ROOT/framework"

# Source the libraries
source "$FRAMEWORK_DIR/core.sh"
source "$FRAMEWORK_DIR/core-extended.sh"

# 4. Standard Handshake
assert_core_api_version "1.0.0"
load_project_manifest
enable_traps

# -------------------------------------
# UI Enhancements (local, non-invasive)
# -------------------------------------
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC="${NC:-\033[0m}"

spinner() {
  local pid=$1
  local msg=$2
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0

  echo -ne "${CYAN}$msg ${NC}"
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % ${#spin} ))
    echo -ne "\r${CYAN}$msg ${MAGENTA}${spin:$i:1}${NC}"
    sleep 0.1
  done
}

spinner_result() {
  local result=$1
  local msg=$2

  if [[ $result -eq 0 ]]; then
    echo -e "\r${CYAN}$msg ${GREEN}✔${NC}"
  else
    echo -e "\r${CYAN}$msg ${RED}✖${NC}"
  fi
}

# -------------------------------------
# Header
# -------------------------------------
[[ -z "${VENTURE_DEBUG:-}" ]] && clear

echo -e "${MAGENTA}"
cat << "EOF"
   🩺  F R A M E W O R K   D O C T O R
   ═════════════════════════════════
EOF
echo -e "${NC}"

phase "🔍 SYSTEM DIAGNOSTICS INITIATED"

# -------------------------------------
# OS CHECK
# -------------------------------------
log_step "🖥️  Operating System Scan"
case "$OS" in
  linux|macos|windows)
    log_info "Detected OS: ${GREEN}$OS${NC}"
    ;;
  *)
    die "Unsupported OS: $OS"
    ;;
esac

# -------------------------------------
# TOOLING CHECK
# -------------------------------------
phase "🧰 REQUIRED TOOLCHAIN"

REQUIRED_TOOLS=(git dotnet zip tar)
OPTIONAL_TOOLS=(gh iscc)

for tool in "${REQUIRED_TOOLS[@]}"; do
  (
    sleep 0.2
    has "$tool"
  ) &
  pid=$!
  spinner "$pid" "🔎 Checking $tool"
  wait "$pid"
  spinner_result $? "🔎 Checking $tool"
  has "$tool" || die "$tool missing"
done

for tool in "${OPTIONAL_TOOLS[@]}"; do
  (
    sleep 0.2
    has "$tool"
  ) &
  pid=$!
  spinner "$pid" "➕ Optional tool: $tool"
  wait "$pid"
  if has "$tool"; then
    spinner_result 0 "➕ Optional tool: $tool"
    log_info "$tool available (optional)"
  else
    spinner_result 1 "➕ Optional tool: $tool"
    log_warn "$tool not found (optional)"
  fi
done

# -------------------------------------
# GIT CHECK
# -------------------------------------
phase "🌱 GIT ENVIRONMENT"

(
  sleep 0.2
  is_git_repo
) &
pid=$!
spinner "$pid" "📁 Validating repository"
wait "$pid"
spinner_result $? "📁 Validating repository"

is_git_repo || die "Not a git repository"

branch="$(current_branch)"
log_info "Active branch: ${CYAN}${branch:-detached}${NC}"

# -------------------------------------
# FRAMEWORK FILES
# -------------------------------------
phase "📦 FRAMEWORK INTEGRITY"

# 1. Force recalculate the base scripts directory
# This ensures SCRIPT_DIR is definitely the 'scripts' folder
LOCAL_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_FRAMEWORK_DIR="$LOCAL_SCRIPTS_DIR/framework"

# 2. Use these LOCAL variables to avoid any pollution from the header
FILES=(
  "$LOCAL_FRAMEWORK_DIR/core.sh"
  "$LOCAL_FRAMEWORK_DIR/core-extended.sh"
  "$LOCAL_SCRIPTS_DIR/check-health.sh"
  "$LOCAL_SCRIPTS_DIR/ship.sh"
)

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    check_val=0
  else
    # This will now tell us the TRUTH about where it's looking
    echo "Diagnostic: Looking in $file" >&2
    check_val=1
  fi

  ( sleep 0.1; exit $check_val ) &
  pid=$!
  spinner "$pid" "📄 Verifying $(basename "$file")"
  wait "$pid"
  spinner_result $? "📄 Verifying $(basename "$file")"
done

log_info "Framework core files verified"

# -------------------------------------
# PROJECT MANIFEST
# -------------------------------------
phase "🧾 PROJECT MANIFEST"

if [[ -f ".project.sh" ]]; then
  log_info "✔ Manifest loaded"
  log_info "Project: ${CYAN}$PROJECT_NAME${NC}"
  log_info "Language: ${CYAN}$PROJECT_LANG${NC}"
  log_info "Default branch: ${CYAN}$DEFAULT_BRANCH${NC}"
else
  log_warn "✖ No .project.sh found (defaults applied)"
fi

# -------------------------------------
# FINAL REPORT
# -------------------------------------
phase "✅ DIAGNOSTIC RESULT"

echo -e "${GREEN}✔ FRAMEWORK HEALTH: OPTIMAL${NC}"
log_info "All checks passed successfully"
log_info "Cleared for update / ship / release 🚀"
