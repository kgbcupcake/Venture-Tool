# ============================
# Project Manifest
# ============================
# This file defines project-specific metadata
# It is sourced by universal scripts
# DO NOT put logic in this file

PROJECT_NAME="MyApp"

FRAMEWORK_LEVEL="lite"   # lite | full | hardened

# Supported: dotnet | node | python | go | rust
PROJECT_LANG="dotnet"

# private | public | internal
REPO_VISIBILITY="private"

# semver | date | incremental
VERSION_STRATEGY="semver"

# Optional metadata (safe defaults applied if unset)
PROJECT_DESCRIPTION=""
DEFAULT_BRANCH="main"
ENABLE_CI="true"
ENABLE_DOCKER="false"
