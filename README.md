# 🪐 Venture Orchestration Suite (Venture-Tool)

**Venture-Tool** is a project-agnostic automation framework designed to eliminate manual code migration and deployment overhead
[cite: 2026-01-13]. It encapsulates the **Ship Logic** pipeline into a high-performance
NuGet Global Tool, enabling a unified workflow across diverse project environments.

---

## 🚀 Ship Logic: The Deployment Pipeline
The suite executes a phased deployment pipeline via shell scripts located in the `/scripts` directory [cite: 2026-01-13]:

1.  **Doctor**: Performs system health checks and verifies dependency diagnostics [cite: 2026-01-13].
2.  **Check-Health**: Executes project-specific validation, including unit tests and linting [cite: 2026-01-13].
3.  **Genesis**: Aligns local repositories with remote origins and performs initial synchronization [cite: 2026-01-22].
4.  **Ship**: Orchestrates final versioning, artifact bundling, and deployment [cite: 2026-01-13].

---

## 💻 Command Reference
Once installed, the following commands are available globally from any project directory:

| Command | Phase | Description |
| :--- | :--- | :--- |
| `venture doctor` | **Diagnose** | Checks Git status, .NET environment, and script permissions. |
| `venture genesis` | **Initialize** | Sets up Git, aligns remotes, and pushes the initial "Birth" commit. |
| `venture check-health` | **Validate** | Runs tests and code analysis defined in the project logic [cite: 2026-01-13]. |
| `venture ship` | **Deploy** | Executes the full Ship Logic pipeline for production release [cite: 2026-01-13]. |
| `venture update` | **Refresh** | Pulls the latest framework updates from the master repository [cite: 2026-01-22]. |

---

## 🛠 Installation & Reforge
To build and install the suite locally as a global tool, use the **Reforge** sequence:

```bash
# 1. Build & Pack
dotnet build -c Release
dotnet pack -c Release -o ./nupkg

# 2. Refresh Global Installation
dotnet tool uninstall -g Venture.Tool.Framework
dotnet tool install -g --add-source ./nupkg Venture.Tool.Framework



📋 Configuration & Rules
Project Metadata
Place a .project.sh file in your target project's root to define specific variables
such as project name, language, and deployment targets [cite: 2026-01-13].

⚖️ Intertwine Rules
Git Cleanliness: The tool strictly enforces clean working directories
and linear history via rebasing before any Ship phase [cite: 2026-01-13, 2026-01-22].

Agnostic Pathing: Uses AppDomain.CurrentDomain.BaseDirectory to ensure
scripts are resolved correctly regardless of where the command is invoked [cite: 2026-01-13].



📝 Maintenance
Version: 1.0.1 [cite: 2026-01-22]

Framework: .NET 8.0 [cite: 2026-01-22]

UI Engine: Spectre.Console 0.54.0 [cite: 2026-01-22]

Environment: Optimized for WSL/Ubuntu with PAT-based Git authentication [cite: 2026-01-22].