#!/usr/bin/env bash

# Source core to get access to logging and variables
source "$(dirname "${BASH_SOURCE[0]}")/../../core.sh"
source "$SCRIPT_DIR/infrastructure/artifact-metadata.sh"

log_info "🔍 Verifying environment variables..."
log_step "🔌 PLUGIN: sign-artifacts active"

# 2. Execute the infrastructure function
generate_checksums "$PROJECT_ROOT/dist"

# Define required variables for a successful ship
REQUIRED_VARS=("GITHUB_TOKEN" "PROJECT_ROOT")

MISSING=0
for var in "${REQUIRED_VARS[@]}"; do
if [[ -z "${!var}" ]]; then
    log_error "Missing required env var: $var"
    MISSING=1
fi
done

if [[ $MISSING -eq 1 ]]; then
die "Environment verification failed. Aborting ship."
fi

log_ok "Environment secure."




