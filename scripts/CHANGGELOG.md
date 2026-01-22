# Changelog

All notable framework changes are documented here.

## [1.0.0] – Security & Distribution 2024-06-15

### Added

-   GitHub Actions CI wiring
-   Multi-language build support
-   Plugin execution framework
-   Framework doctor validation
-   Plugin signing and verification
-   Framework self-update command
-   Per-language ship extensions
-   Artifact checksum and SBOM generation

### Notes

This release adds extensibility without modifying flagship scripts.
All features are opt-in and non-invasive.
Per-language ship extensions allow custom actions during the ship phase.
See `scripts/languages/ship-*.sh` for examples.
Plugins can now hook into various phases of the build and ship process.
See `scripts/plugins/` for available plugins.
The framework now validates its environment before executing commands.
Run `framework doctor` to check for common issues.

Refactor: Converted update.sh to a fully project-agnostic workflow [cite: 2026-01-21].

Fix: Resolved pathing ambiguity by forcing cd "$PROJECT_ROOT" before executing Git or Dotnet commands.

Improvement: Added dynamic branch detection to allow updates on feature branches instead of just main.