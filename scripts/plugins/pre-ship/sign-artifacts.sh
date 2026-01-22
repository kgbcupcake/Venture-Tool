#!/usr/bin/env bash

# ---------------------------------------------------------
# PLUGIN: Artifact Signer
# PHASE: Pre-Ship
# ---------------------------------------------------------

# 1. Load Infrastructure using the Framework's known SCRIPT_DIR
# This ensures it works whether called locally or via 'venture'
source "$SCRIPT_DIR/framework/core.sh"
source "$SCRIPT_DIR/infrastructure/artifact-metadata.sh"
source "$SCRIPT_DIR/infrastructure/plugin-security.sh"

log_step "🔌 PLUGIN: Initiating Artifact Signing Protocol"

# 2. Configuration
# We use PROJECT_ROOT (set by the C# wrapper) to ensure we are in the user's project
DIST_DIR="$PROJECT_ROOT/dist"
PRIVATE_KEY="$PROJECT_ROOT/infrastructure/plugin.key" 
CHECKSUM_FILE="$DIST_DIR/SHA256SUMS"

# 3. Validation
# Verify the 'requires' from your manifest
if ! command -v openssl &> /dev/null; then
    log_error "❌ openssl not found in PATH. Required by sign-artifacts plugin."
    exit 1
fi

if [[ ! -d "$DIST_DIR" ]]; then
    log_warn "⚠️  Dist directory missing at $DIST_DIR. Build likely skipped."
    exit 0
fi

# 4. Execution
# generate_checksums is provided by artifact-metadata.sh
if [[ ! -f "$CHECKSUM_FILE" ]]; then
    log_info "Generating fresh checksums in $DIST_DIR..."
    generate_checksums "$DIST_DIR"
fi

# Sign the checksum file
log_info "🔏 Signing artifact manifest..."
openssl dgst -sha256 -sign "$PRIVATE_KEY" -out "${CHECKSUM_FILE}.sig" "$CHECKSUM_FILE"

if [[ $? -eq 0 ]]; then
    log_ok "Signature attached: ${CHECKSUM_FILE}.sig"
    # Record the event in the metadata log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SIGNED - $CHECKSUM_FILE" >> "$PROJECT_ROOT/ship.log"
else
    die "Failed to sign artifacts."
fi