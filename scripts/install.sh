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


[[ -n "${BASHDB_VERSION:-}" || -n "${VENTURE_DEBUG:-}" ]] && set -x

# -------------------------------------
# Extra Colors (extension only)
# -------------------------------------
MAGENTA='\033[0;35m'
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

  VERSION="$(grep -m 1 -oP '(?<=<Version>)[^<]+' "$csproj" | tr -d '\r' | xargs)"
  [[ -z "$VERSION" ]] && die "No <Version> tag found in $csproj"
}

detect_dotnet_project

# Avoid destructive clears during diagnostics
[[ -z "${VENTURE_DEBUG:-}" ]] && clear

echo -e "${MAGENTA}🛠️  ${APP_NAME^^} DEBUG UPLINK INITIATED${NC}"
echo -e "${CYAN}🎯 Target Version: v${VERSION}${NC}\n"

cd "$PROJECT_ROOT" || exit 1
require_command zip
require_command gh

# -------------------------------------
# [1/3] BUILD / FORGE CHECK
# -------------------------------------
echo -e "${YELLOW}[1/3] 📦 BUILD — WINDOWS (win-x64)${NC}"

dotnet publish \
  -c Release \
  -r win-x64 \
  --self-contained true \
  -o "./dist/win" \
  --nologo

BUILD_RESULT=$?

ARTIFACT_NAME="${APP_NAME}-v${VERSION}-DEBUG.zip"
ARTIFACT_PATH="./${ARTIFACT_NAME}"

if [[ $BUILD_RESULT -eq 0 ]]; then
  echo -e "${GREEN}✔ Build succeeded — archiving artifacts${NC}"
  zip -r "$ARTIFACT_NAME" "./dist/win" >/dev/null 2>&1 \
    && echo -e "${GREEN}✔ Archive created: ${ARTIFACT_NAME}${NC}" \
    || echo -e "${RED}✖ Failed to create archive${NC}"
else
  echo -e "${RED}✖ Build failed — see compiler output above${NC}"
fi

# -------------------------------------
# [2/3] CLOUD AUTH CHECK
# -------------------------------------
echo -e "\n${YELLOW}[2/3] 🌐 AUTH — GITHUB${NC}"

if gh auth status &>/dev/null; then
  echo -e "${GREEN}✔ GitHub CLI authenticated${NC}"
else
  echo -e "${RED}✖ GitHub CLI not authenticated${NC}"
fi

# -------------------------------------
# [3/3] RELEASE UPLINK TEST
# -------------------------------------
echo -e "\n${YELLOW}[3/3] 🚀 RELEASE — DEBUG UPLINK${NC}"

# Ensure idempotent debug runs
gh release delete "v${VERSION}" --yes >/dev/null 2>&1 || true

if [[ -f "$ARTIFACT_PATH" ]]; then
  gh release create "v${VERSION}" "$ARTIFACT_PATH" \
    --title "Debug: ${APP_NAME} v${VERSION}" \
    --notes "Automated Debug Uplink for ${APP_NAME}" \
    --clobber

  RELEASE_RESULT=$?

  if [[ $RELEASE_RESULT -eq 0 ]]; then
    echo -e "${GREEN}✔ Release uploaded — debug package is live${NC}"
  else
    echo -e "${RED}✖ Release failed — check permissions or tag state${NC}"
  fi
else
  echo -e "${RED}✖ Release aborted — artifact missing (${ARTIFACT_PATH})${NC}"
fi

echo -e "\n${MAGENTA}🛠️  DEBUG PROTOCOL COMPLETE${NC}"
