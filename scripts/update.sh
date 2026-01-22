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
# Optional Infrastructure
# -------------------------------------
if [[ -f "$SCRIPT_DIR/infrastructure/artifact-metadata.sh" ]]; then
  source "$SCRIPT_DIR/infrastructure/artifact-metadata.sh"
fi

# -------------------------------------
# UI Enhancements (local only)
# -------------------------------------
GOLD='\033[38;5;220m'
GRAY='\033[38;5;244m'
MAGENTA='\033[0;35m'

draw_line() {
  echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

spin() {
  local msg=$1
  local frames=("🔄" "⚙️" "🧠" "✨")
  for i in {0..7}; do
    echo -ne "\r${CYAN}${msg} ${MAGENTA}${frames[$((i % 4))]}${NC}"
    sleep 0.15
  done
  echo -ne "\r${CYAN}${msg} ${GREEN}✔${NC}\n"
}

fail() {
  echo -e "${RED}✖ $1${NC}"
  exit 1
}

# -------------------------------------
# Framework Self-Update (Explicit, Gated)
# -------------------------------------
# The repository to use for the framework self-update.
# This should be the repository where the framework scripts are maintained.
FRAMEWORK_REPO="${FRAMEWORK_REPO:-https://github.com/gemini-cli-extensions/Venture-Tool-Framework.git}"
FRAMEWORK_DIR="$PROJECT_ROOT/.framework"

phase "FRAMEWORK SELF UPDATE"

confirm "Check for framework updates?" && {
  if [[ ! -d "$FRAMEWORK_DIR" ]]; then
    spin "Cloning framework"
    git clone "$FRAMEWORK_REPO" "$FRAMEWORK_DIR" || fail "Clone failed"
  else
    spin "Fetching framework updates"
    git -C "$FRAMEWORK_DIR" fetch || fail "Fetch failed"
  fi

  log_info "Diff preview (local → upstream):"
  git -C "$FRAMEWORK_DIR" diff HEAD..origin/main || true

  confirm "Apply framework update?" || exit 0

  spin "Applying framework update"
  git -C "$FRAMEWORK_DIR" pull || fail "Pull failed"
  rsync -av "$FRAMEWORK_DIR/scripts/" "$PROJECT_ROOT/scripts/" >/dev/null

  log_info "Framework successfully updated"
}

# -------------------------------------
# Project Detection (Dotnet)
# -------------------------------------
detect_dotnet_project() {
  DOTNET_CSPROJ="$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.csproj" | head -n 1)"
  SLN_FILE="$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.sln" | head -n 1)"

  [[ -z "$DOTNET_CSPROJ" ]] && fail "No .csproj found"
  [[ -z "$SLN_FILE" ]] && fail "No .sln found"

  APP_NAME="$(basename "$DOTNET_CSPROJ" .csproj)"
  CURRENT_VERSION="$(grep -m 1 -oP '(?<=<Version>)[^<]+' "$DOTNET_CSPROJ" | tr -d '\r' | xargs)"

  [[ -z "$CURRENT_VERSION" ]] && fail "No <Version> tag found"
}

detect_dotnet_project

# -------------------------------------
# Header (debug-safe)
# -------------------------------------
[[ -z "${VENTURE_DEBUG:-}" ]] && clear

echo -e "${CYAN}🔄 UPDATE PROTOCOL ENGAGED${NC}"
sleep 0.2
echo -e "${GOLD}
⚙️  ${APP_NAME^^}
CURRENT VERSION: v${CURRENT_VERSION}
${NC}"
draw_line

cd "$PROJECT_ROOT"

# -------------------------------------
# [1/4] SYNC WITH REMOTE
# -------------------------------------
spin "[1/4] 🔃 Synchronizing with remote"
git pull origin "$DEFAULT_BRANCH" --quiet || fail "Git pull failed"

# -------------------------------------
# [2/4] OPTIONAL VERSION EVOLUTION
# -------------------------------------
confirm "Bump patch version?" && {
  NEW_VERSION="$(bump_patch "$CURRENT_VERSION")"
  [[ -z "$NEW_VERSION" ]] && fail "Version bump failed"

  sed -i "s/<Version>${CURRENT_VERSION}<\/Version>/<Version>${NEW_VERSION}<\/Version>/" "$DOTNET_CSPROJ"
  echo -e "${GREEN}✔ Version evolved → v${NEW_VERSION}${NC}"
  CURRENT_VERSION="$NEW_VERSION"
}

# -------------------------------------
# [3/4] HEALTH CHECK
# -------------------------------------
spin "[3/4] 🛡️  Running logic guard"
bash "$SCRIPT_DIR/check-health.sh" >/dev/null 2>&1 \
  || fail "Health check failed"

# -------------------------------------
# [4/4] COMMIT & PUSH
# -------------------------------------
draw_line
read -r -p "$(echo -e "${CYAN} » Commit message:${NC} ")" msg
msg="${msg:-Update: v${CURRENT_VERSION}}"

spin "[4/4] 🚀 Pushing update"
git add .
git commit -m "$msg" --quiet || true
run git push origin "$DEFAULT_BRANCH" --quiet

# -------------------------------------
# OPTIONAL METADATA GENERATION
# -------------------------------------
if declare -f generate_sbom >/dev/null && declare -f generate_checksums >/dev/null; then
  confirm "Generate SBOM and checksums?" && {
    spin "Generating SBOM"
    generate_sbom "$PROJECT_ROOT/dist"

    spin "Generating checksums"
    generate_checksums "$PROJECT_ROOT/dist"
  }
fi

# -------------------------------------
# Final Report
# -------------------------------------
draw_line
echo -e " ${GREEN}✔ UPDATE COMPLETE${NC}"
echo -e " ${GRAY}Next step:${NC} ${CYAN}run ship.sh when ready to release${NC}"
draw_line
echo
