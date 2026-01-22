#!/bin/bash
set -e

# -------------------------------------
# 3. Project Anchor (FIXED LOCATION)
# -------------------------------------
if [[ -n "$VENTURE_PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$VENTURE_PROJECT_ROOT"
else
    PROJECT_ROOT="$(pwd)"
fi

cd "$PROJECT_ROOT"
export PROJECT_ROOT

# 1. Clear guards to force a fresh load of the API
unset CORE_LOADED

# 2. Framework Anchor (Internal Tool Path)
# This finds the scripts folder inside the global tool's store
INTERNAL_TOOL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 4. Source the libraries using the Internal Tool Anchor
source "$INTERNAL_TOOL_ROOT/framework/core.sh"
source "$INTERNAL_TOOL_ROOT/framework/core-extended.sh"

assert_core_api_version "1.0.0"
load_project_manifest
enable_traps

# -------------------------------------
# Health Guard (prevents recursion)
# -------------------------------------
if [[ "${HEALTH_INTERNAL_RUN:-false}" == "true" ]]; then
    exit 0
fi
export HEALTH_INTERNAL_RUN="true"

# -------------------------------------
# Project Detection (Dotnet)
# -------------------------------------
detect_dotnet_project() {
    local csproj
    csproj=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | head -n 1)
    [[ -z "$csproj" ]] && die "No .csproj file found in $PROJECT_ROOT"

    DOTNET_CSPROJ="$csproj"
    APP_NAME="$(basename "$csproj" .csproj)"
}

detect_dotnet_project

# -------------------------------------
# UI Enhancements
# -------------------------------------
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
WHITE_SOFT='\033[38;5;250m'
BG_RED='\033[41;37m'
BG_GREEN='\033[42;30m'
SPIN_CYAN='\033[38;5;51m'

_spinner_pid=""
start_spinner() {
    local msg="$1"
    echo -ne "${SPIN_CYAN}⏳ $msg ${NC}"
    ( while true; do for c in ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏; do echo -ne "\b$c"; sleep 0.1; done; done ) &
    _spinner_pid=$!
}

stop_spinner() {
    if [[ -n "$_spinner_pid" ]]; then
        kill "$_spinner_pid" &>/dev/null || true
        wait "$_spinner_pid" 2>/dev/null || true
        _spinner_pid=""
        echo -ne "\b "
    fi
}

# -------------------------------------
# UI Header
# -------------------------------------
clear
echo -e "${MAGENTA}    🩺 D I A G N O S T I C   M O N I T O R"
echo -e "    ═══════════════════════════════════${NC}"
echo -e "${WHITE_SOFT}Target: ${APP_NAME}${NC}\n"


echo -e "${CYAN}📡 PHASE 1: SYSTEM ENVIRONMENT AUDIT${NC}"

# Removed 'iscc' from tools to stay lean
tools=(dotnet git gh zip sed grep tar)

for tool in "${tools[@]}"; do
    echo -ne " ${GRAY}🔍 Tool Check:${NC} ${WHITE_SOFT}$tool${NC} … "
    if command -v "$tool" &>/dev/null; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}MISSING${NC}"
        die "Required tool missing: $tool"
    fi
done

# -------------------------------------
# PHASE 2: FILESYSTEM INTEGRITY
# -------------------------------------
echo -e "\n${CYAN}📂 PHASE 2: FILESYSTEM INTEGRITY${NC}"

anchors=(
    "$DOTNET_CSPROJ"
    "$PROJECT_ROOT/README.md"
)

for file in "${anchors[@]}"; do
    name="$(basename "$file")"
    echo -ne " ${GRAY}📎 Anchor:${NC} ${WHITE_SOFT}$name${NC} … "
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}VERIFIED${NC}"
    else
        echo -e "${RED}MISSING${NC}"
        # We don't 'die' for README, but we do for .csproj
        [[ "$name" == *.csproj ]] && die "Expected $name in project root"
        echo -e "${YELLOW}WARNING: Optional file missing${NC}"
    fi
done

# -------------------------------------
# PHASE 3: LOGIC & UNIT DIAGNOSTICS (KEEP YOUR SHIT!)
# -------------------------------------
echo -e "\n${CYAN}🧠 PHASE 3: LOGIC & UNIT DIAGNOSTICS${NC}"

start_spinner "Restoring dependencies"
dotnet restore "$DOTNET_CSPROJ" --nologo -v quiet >/dev/null 2>&1
stop_spinner
echo -e " ${GREEN}✔ Dependencies restored${NC}"

echo -e "\n ${GRAY}🧪 Initiating Test Simulations…${NC}"
echo -e "${GRAY}─────────────────────────────────────────────────────────${NC}"

set +e
dotnet test "$DOTNET_CSPROJ" --nologo --verbosity minimal
TEST_RESULT=$?
set -e

echo -e "${GRAY}─────────────────────────────────────────────────────────${NC}"

if [[ $TEST_RESULT -eq 0 ]]; then
    echo -e " ${GREEN}✅ Simulations stable${NC}"
else
    echo -e " ${RED}❌ Critical logic failure detected${NC}"
    exit 1
fi

# -------------------------------------
# PHASE 4: CLOUD ALIGNMENT
# -------------------------------------
echo -e "\n${CYAN}🛰️  PHASE 4: CLOUD ALIGNMENT CHECK${NC}"

echo -ne " ${GRAY}📦 Git Workspace:${NC} "
if [[ -z "$(git status -s 2>/dev/null)" ]]; then
    echo -e "${GREEN}CLEAN${NC}"
else
    echo -e "${YELLOW}DIRTY (Uncommitted Changes)${NC}"
fi

echo -ne " ${GRAY}🔐 Cloud Authentication:${NC} "
if gh auth status &>/dev/null; then
    echo -e "${GREEN}AUTHORIZED${NC}"
else
    echo -e "${YELLOW}UNAUTHORIZED${NC}"
fi

# -------------------------------------
# PHASE 5: FINAL REPORT
# -------------------------------------
echo -e "\n${CYAN}═════════════════════════════════════════════════════════${NC}"
echo -e " ${BG_GREEN} 🚀 DIAGNOSTICS PASSED — ${APP_NAME^^} CLEARED FOR SHIP ${NC}"
echo -e "${CYAN}═════════════════════════════════════════════════════════${NC}\n"

export HEALTH_INTERNAL_RUN="false"