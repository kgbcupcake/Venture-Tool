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
# Extra Colors (extension only)
# -------------------------------------
GOLD='\033[38;5;220m'
GRAY='\033[38;5;244m'
NC="${NC:-\033[0m}"

# -------------------------------------
# Project Detection (Dotnet)
# -------------------------------------
detect_dotnet_project() {
  local csproj
  csproj="$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | head -n 1)"

  [[ -z "$csproj" ]] && die "No .csproj found in project root"

  DOTNET_CSPROJ="$csproj"
  APP_NAME="$(basename "$csproj" .csproj)"
}

detect_dotnet_project

# Avoid destructive clears during diagnostics
[[ -z "${VENTURE_DEBUG:-}" ]] && clear

echo -e "${GOLD}🪐 VENTURE GENESIS — REPOSITORY ALIGNMENT${NC}"
echo -e "${CYAN}🎯 Target Project:${NC} ${APP_NAME}\n"

cd "$PROJECT_ROOT"

# -------------------------------------
# [1/3] LOCAL GIT INITIALIZATION
# -------------------------------------
echo -e "${YELLOW}[1/3] 💾 GIT — LOCAL INITIALIZATION${NC}"

if ! is_git_repo; then
  git init --quiet

  if [[ ! -f ".gitignore" ]]; then
    dotnet new gitignore >/dev/null 2>&1 || true
  fi

  echo -e "${GREEN}✔ Local git initialized${NC}"
else
  echo -e "${GRAY}⏩ Git repository already present — skipping${NC}"
fi

# -------------------------------------
# [2/3] GITHUB REMOTE ALIGNMENT
# -------------------------------------
echo -e "\n${YELLOW}[2/3] 🌐 GITHUB — REMOTE ALIGNMENT${NC}"
require_command gh

if ! git remote get-url origin &>/dev/null; then
  gh auth status &>/dev/null || die "GitHub CLI not authenticated"

  read -r -p "$(echo -e "${CYAN} » Repository description:${NC} ")" desc
  desc="${desc:-Universal Asset Vault: $APP_NAME}"

  gh repo create "$APP_NAME" \
    --"$REPO_VISIBILITY" \
    --description "$desc" \
    --source="." \
    --remote=origin

  echo -e "${GREEN}✔ GitHub repository created${NC}"
else
  echo -e "${GRAY}⏩ Remote 'origin' already configured — skipping${NC}"
fi

# -------------------------------------
# [3/3] FIRST PULSE
# -------------------------------------

# [3/3] 🚀 GENESIS — FIRST COMMIT
echo "[3/3] 🚀 GENESIS — FIRST COMMIT"

# Check if there are actually changes to commit
if [[ -z $(git status --porcelain) ]]; then
    echo "✅ Working tree clean — nothing to align."
else
    git add .
    git commit -m "chore: prometheus genesis alignment"
    
    # Attempt push with rebase fallback
    if ! git push -u origin main; then
        echo "⚠️ Remote divergence detected. Synchronizing..."
        git pull origin main --rebase --no-edit
        git push -u origin main
    fi
fi

# -------------------------------------
# Final Report
# -------------------------------------
echo -e "\n${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " ${GREEN}✨ GENESIS COMPLETE${NC}"
echo -e " ${GRAY}Repository:${NC} ${CYAN}$(git config --get remote.origin.url | sed 's/git@github.com:/https:\/\/github.com\//')${NC}"
echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
