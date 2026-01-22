#!/usr/bin/env bash

# ============================================================
# DEPRECATED SCRIPT — COMPATIBILITY WRAPPER
# ============================================================
# This script has been superseded by:
#
#   • neural-pulse.sh   → version evolution
#   • debug-uplink.sh   → debug build + release
#
# This file is intentionally kept to avoid breaking
# muscle memory or old documentation.
# ============================================================

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

# 4. Now the command will be found
assert_core_api_version "1.0.0"
load_project_manifest
enable_traps
# ------------------------------

phase "DEPRECATION NOTICE"

echo -e "${YELLOW}⚠️  version-bumber.sh is deprecated.${NC}"
echo -e "${GRAY}➡ Redirecting to neural-pulse.sh (version evolution)...${NC}\n"

exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/neural-pulse.sh"

