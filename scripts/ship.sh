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

# --- [🔍 AGNOSTIC PROJECT DETECTION] ---
# Find the first .csproj available in the root [cite: 2026-01-13]
CSPROJ=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | head -n 1)
[[ -z "$CSPROJ" ]] && die "No .csproj file found in $PROJECT_ROOT"

APP_NAME=$(basename "$CSPROJ" .csproj)
VERSION=$(grep -m 1 -oP '(?<=<Version>)[^<]+' "$CSPROJ" | tr -d '\r' | xargs || echo "1.0.0")

# Dynamically resolve GitHub Repo from git config
REPO_URL=$(git remote get-url origin 2>/dev/null | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//' || echo "")
REPO_PATH=$(echo "$REPO_URL" | awk -F'github.com/' '{print $2}')

DIST_DIR="$PROJECT_ROOT/dist"
WIN_DIST="$DIST_DIR/win"
LINUX_DIST="$DIST_DIR/linux"
mkdir -p "$WIN_DIST" "$LINUX_DIST"

# --- [🎨 COLOR PALETTE] ---
CYAN='\033[38;5;51m'
GOLD='\033[38;5;220m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;226m'
GRAY='\033[38;5;244m'
NC='\033[0m'

draw_line() {
  echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- [🚀 START PROTOCOL] ---
clear || true
echo -e "${CYAN}📡 NEURAL LINK ESTABLISHED...${NC}"
sleep 0.3
echo -e "${GOLD}
    ⚡ ${APP_NAME^^} : THE SHIP
    PROMETHEUS PROTOCOL // VERSION: v$VERSION
${NC}"
draw_line

# --- [1/5] 🛡️ PRE-FLIGHT DIAGNOSTICS ---
echo -ne "${CYAN}[1/5] 🛡️  LOGIC GUARD: ${NC}"
HEALTH_SCRIPT="$INTERNAL_TOOL_ROOT/check-health.sh"

# Pass the project root to the sub-health-check
if VENTURE_PROJECT_ROOT="$PROJECT_ROOT" "$HEALTH_SCRIPT" >/dev/null 2>&1; then
  echo -e "${GREEN}PASS (NUnit Clean)${NC}"
else
  echo -e "${RED}FAIL${NC}"
  die "Aborting uplink: Diagnostics detected a fault in $APP_NAME."
fi

# --- [2/5] 🛠️ FORGING WINDOWS ENGINE ---
echo -ne "${CYAN}[2/5] 🛠️  FORGING WINDOWS ENGINE: ${NC}"
if dotnet publish "$CSPROJ" -c Release -r win-x64 --self-contained true -o "$WIN_DIST" --nologo >/dev/null 2>&1; then
  (cd "$WIN_DIST" && zip -r "$DIST_DIR/${APP_NAME}-v${VERSION}-Win.zip" . >/dev/null 2>&1)
  echo -e "${YELLOW}ZIP GENERATED${NC}"
else
  die "Windows forge failed."
fi

# --- [3/5] 🐧 FORGING LINUX ENGINE ---
echo -ne "${CYAN}[3/5] 🐧 FORGING LINUX ENGINE: ${NC}"
if dotnet publish "$CSPROJ" -c Release -r linux-x64 --self-contained true -o "$LINUX_DIST" --nologo >/dev/null 2>&1; then
  tar -czf "$DIST_DIR/${APP_NAME}-v${VERSION}-Linux.tar.gz" -C "$LINUX_DIST" . >/dev/null 2>&1
  echo -e "${GREEN}TAR.GZ READY${NC}"
else
  die "Linux forge failed."
fi

# --- [4/5] 📝 SMART COMMIT & IGNITION ---
draw_line
echo -e "${GOLD}📝 DEPLOYMENT MANIFEST${NC}"
read -r -p " » Enter Neural Log Message: " msg
msg="${msg:-System Uplink: $APP_NAME v$VERSION}"

CURRENT_BRANCH=$(git branch --show-current)
[[ -z "$CURRENT_BRANCH" ]] && CURRENT_BRANCH="main"

echo -ne "\n${CYAN}[4/5] 🚀 IGNITING SYSTEM MEMORY... ${NC}"
git add .
git commit -m "🚀 $msg" >/dev/null 2>&1 || true
git push origin "$CURRENT_BRANCH" --quiet
echo -e "${GREEN}PUSH STABLE (Branch: $CURRENT_BRANCH)${NC}"

# --- [5/5] 🛰️ AUTOMATED RELEASE ---
echo -ne "${CYAN}[5/5] 🛰️  CLOUD SYNCING... ${NC}"

if [[ -z "$REPO_PATH" ]]; then
    echo -e "${YELLOW}SKIPPED (No Remote)${NC}"
else
    shopt -s nullglob
    ASSETS=("$DIST_DIR"/*.{zip,tar.gz})
    shopt -u nullglob

    if [ ${#ASSETS[@]} -gt 0 ]; then
      gh release create "v$VERSION" "${ASSETS[@]}" \
        --title "$APP_NAME v$VERSION" \
        --notes "$msg" \
        --repo "$REPO_PATH" \
        --clobber
      echo -e "${GREEN}UPLINKED TO ${REPO_PATH}${NC}"
    else
      die "EMPTY CARGO: No assets found in $DIST_DIR"
    fi
fi

# --- [🏁 POST-FLIGHT REPORT] ---
draw_line
echo -e " ${GREEN}✨ SUCCESS: UPLINK STATE STABLE${NC}"
echo -e " ${GRAY}⚡ Repository: ${REPO_URL:-Local Only}${NC}"
draw_line