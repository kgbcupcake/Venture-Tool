# Venture Tool Framework: Experimental Test Suite

## Purpose

This directory contains the experimental build and test configurations for the **Venture Orchestration Suite**.
Its primary goal is to validate the transition of the automation framework into a **NuGet Global Tool**
and to test the execution of the project-agnostic deployment pipeline.

## Dependencies & Assumptions

- **Runtime**: .NET 8.0 SDK must be installed.
- **OS**: Linux/WSL (Ubuntu) environment is required to ensure shell script
- compatibility and avoid Windows-to-WSL file-locking permissions.
- **Environment**: The user must have `dotnet` tool paths added to their global `$PATH`.

## Build and Installation Protocol

To resolve persistent naming desyncs between the solution file
and the project assembly, the following "Surgical" build process is mandatory:

### 1. Environment Purge

Before building, clear all stale metadata to prevent `MSB3030` "File Not Found" errors:

```bash
dotnet build-server shutdown
sudo rm -rf obj/ bin/ nupkg/
```

2. Artifact Generation
   Point directly to the project file to bypass any .sln naming overrides:

Bash
dotnet pack Venture.Tool.Framework.csproj -c Release -o ./nupkg 3. Global Tool Installation
Install the tool from the local generated feed. Note: You must specify the exact version generated (currently 1.0.0):

Bash
dotnet tool install -g --add-source ./nupkg Venture.Tool.Framework --version 1.0.1
Example Usage
Once the tool is installed, you can trigger the global command from any project directory to initiate the automation suite [cite: 2026-01-13]:

Bash

# Display help and available commands

venture --help

# Execute the deployment pipeline (Ship Logic)

venture ship
Intertwine Rules & Constraints
Location: This test class and its artifacts must remain within the /tests/ folder and never be moved to main source folders [cite: 2026-01-15].

Git Integrity: The tool enforces Git cleanliness rules; ensure all changes are committed before running deployment commands [cite: 2026-01-13].

Naming: The AssemblyName is hard-coded to Venture.Tool.Framework to maintain identity synchronization [cite: 2026-01-15].

Git Workflow: The suite now enforces a pull --rebase strategy during the Genesis
phase to handle pre-initialized remote repositories [cite: 2026-01-22].

Success Criteria: A successful alignment is marked by the terminal message branch
'main' set up to track 'origin/main' [cite: 2026-01-13].
Remote Hub: The suite is now backed by a persistent remote at github.com/kgbcupcake/Venture-Tool.

Sync Strategy: Uses a main branch tracking system for all framework and script updates [cite: 2026-01-22].

Configuration: Detailed the .project.sh requirement for target projects to
ensure proper variable interpolation during the Ship phase [cite: 2026-01-13].

Validation: The Doctor phase now cross-references .project.sh
settings with the local environment [cite: 2026-01-13].