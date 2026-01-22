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
assert_core_api_version "1.0.0"
load_project_manifest
enable_traps


# -------------------------------------
# Extra Colors (extension only)
# -------------------------------------
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'

# -------------------------------------
# Project Detection (Dotnet)
# -------------------------------------
detect_dotnet_project() {
  local csproj
  csproj=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | head -n 1)
  [[ -z "$csproj" ]] && die "No .csproj found in project root"

  DOTNET_CSPROJ="$csproj"
  APP_NAME="$(basename "$csproj" .csproj)"

  CURRENT_VERSION="$(grep -m 1 -oP '(?<=<Version>).*?(?=</Version>)' "$csproj" | tr -d '\r' | xargs)"
  [[ -z "$CURRENT_VERSION" ]] && die "No <Version> tag found in $csproj"
}

detect_dotnet_project

echo -e "${MAGENTA}🧠 VENTURE VERSION PULSE INITIATED...${NC}"
echo -e "${CYAN}  » Project: ${APP_NAME}${NC}"
echo -e "${CYAN}  » Current State: v${CURRENT_VERSION}${NC}"

cd "$PROJECT_ROOT"

# -------------------------------------
# Safety Check: Workspace Cleanliness
# -------------------------------------
if [[ -n "$(git status -s | grep -v "$(basename "$DOTNET_CSPROJ")")" ]]; then
  echo -e "${YELLOW}⚠️  WARNING: Uncommitted changes detected.${NC}"
  echo -e "${GRAY}It is recommended to commit logic changes before bumping versions.${NC}"
  confirm "Continue anyway?" || exit 1
fi

# -------------------------------------
# Version Bump Logic (Patch)
# -------------------------------------
[[ -z "$NEW_VERSION" ]] && die "Version evolution failed"

[[ -z "$major" || -z "$minor" || -z "$patch" ]] && die "Invalid semantic version format"

NEW_VERSION="${major}.${minor}.$((patch + 1))"

# -------------------------------------
# Write Version Update
# -------------------------------------
sed -i "s/<Version>${CURRENT_VERSION}<\/Version>/<Version>${NEW_VERSION}<\/Version>/" "$DOTNET_CSPROJ"

# -------------------------------------
# Git Commit
# -------------------------------------
echo -ne " ${CYAN}📝 [GIT] Logging version evolution... ${NC}"
git add "$DOTNET_CSPROJ"
git commit -m "release: evolve to v${NEW_VERSION}" --quiet
echo -e "${GREEN}COMMITTED${NC}"

# -------------------------------------
# Final Report
# -------------------------------------
echo -e "\n${GREEN}✨ SUCCESS: ${APP_NAME} evolved to v${NEW_VERSION}${NC}"
echo -e "${MAGENTA}🚀 READY FOR NEXT PHASE.${NC}"
echo -e "${GRAY}---------------------------------------------------------${NC}"
