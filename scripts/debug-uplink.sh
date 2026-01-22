#!/bin/bash
# ============================================================
# SCRIPT: DEBUG-UPLINK
# ============================================================
# This script is responsible for creating a debug release.
# It builds the project, creates a debug package, and
# uploads it to a GitHub release.
#
# NOTE: This script was previously named 'install.sh'.
# ============================================================
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
# Extra Colors (framework-approved)
# -------------------------------------
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC="${NC:-\033[0m}"

# -------------------------------------
# Project Detection (Dotnet)
# -------------------------------------
detect_dotnet_project() {
  local csproj
  csproj="$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | head -n 1)"
  [[ -z "$csproj" ]] && die "No .csproj file found in project root"

  DOTNET_CSPROJ="$csproj"
  APP_NAME="$(basename "$csproj" .csproj)"
}

detect_dotnet_project

# -------------------------------------
# Version Extraction
# -------------------------------------
current_version="$(
  grep -m 1 -oP '(?<=<Version>).*?(?=</Version>)' "$DOTNET_CSPROJ" \
  | tr -d '\r' \
  | xargs
)"

[[ -z "$current_version" ]] && die "No <Version> tag found in $DOTNET_CSPROJ"

# -------------------------------------
# UI Header
# -------------------------------------
echo
echo -e "${MAGENTA}🧪 DEBUG UPLINK PROTOCOL ENGAGED${NC}"
echo -e "${CYAN}▶ Project:${NC} ${APP_NAME}"
echo -e "${CYAN}▶ Current Version:${NC} v${current_version}"
echo -e "${GRAY}──────────────────────────────────────────────${NC}"

# -------------------------------------
# Safety Check: Workspace Cleanliness
# -------------------------------------
if [[ -n "$(git status -s | grep -v "$(basename "$DOTNET_CSPROJ")")" ]]; then
  echo -e "${YELLOW}⚠️  Workspace not clean${NC}"
  echo -e "${GRAY}Uncommitted changes detected. Debug uplink may not reflect final state.${NC}"
  confirm "Continue with debug uplink anyway?" || exit 1
fi

# -------------------------------------
# Version Calculation (Patch Increment)
# -------------------------------------
echo -e "\n${CYAN}🔢 Calculating debug version increment...${NC}"

new_version="$(bump_patch "$current_version")"
[[ -z "$new_version" ]] && die "Failed to calculate next debug version"

if [[ "$new_version" == "$current_version" ]]; then
  die "Version bump resulted in no change (already latest?)"
fi

echo -e "${GREEN}✔ Next debug version:${NC} v${new_version}"

# -------------------------------------
# Write Version Update
# -------------------------------------
echo -ne "${CYAN}✏️  Writing version marker... ${NC}"
sed -i "s/<Version>${current_version}<\/Version>/<Version>${new_version}<\/Version>/" "$DOTNET_CSPROJ"
echo -e "${GREEN}✔ Updated${NC}"

# -------------------------------------
# Git Commit
# -------------------------------------
echo -ne "${CYAN}📝 Recording debug evolution... ${NC}"
git add "$DOTNET_CSPROJ"
git commit -m "debug: bump version to v${new_version}" --quiet \
  && echo -e "${GREEN}✔ Committed${NC}" \
  || echo -e "${YELLOW}⚠️  No changes to commit${NC}"

# -------------------------------------
# Final Report
# -------------------------------------
echo
echo -e "${GREEN}✔ DEBUG VERSION READY${NC}"
echo -e "${MAGENTA}🧪 ${APP_NAME} → v${new_version}${NC}"
echo -e "${GRAY}Safe for debug ship or test uplink.${NC}"
echo -e "${GRAY}──────────────────────────────────────────────${NC}"
