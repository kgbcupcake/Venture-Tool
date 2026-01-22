#!/usr/bin/env bash

generate_checksums() {
    local target_dir="$1"
    log_info "🛰️  Infra: Scanning artifacts in $target_dir"
    
    if [[ -d "$target_dir" ]]; then
        # Creates a manifest of all files and their SHA256 hashes
        find "$target_dir" -type f -exec sha256sum {} + > "$target_dir/manifest.checksums"
        log_ok "Manifest generated."
    else
        log_warn "Target directory $target_dir not found. Skipping."
    fi
}

generate_sbom() {
  local dir="$1"
  phase "Generating SBOM"
  syft dir:"$dir" -o json > "$dir/sbom.json" || log_warn "SBOM generation skipped"
}
