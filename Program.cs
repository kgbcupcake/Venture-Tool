using System.Diagnostics;
using Spectre.Console;

// Reverting to Top-Level Statements to resolve CS0017 entry point conflicts
bool keepRunning = true;

while (keepRunning)
{
	AnsiConsole.Clear();

	// 1. Header
	var header = new FigletText("VENTURE");
	header.Color = Color.Cyan1;
	AnsiConsole.Write(header);

	// 2. Interactive Menu
	var command = AnsiConsole.Prompt(
		new SelectionPrompt<string>()
			.Title("[yellow]Venture Orchestration Suite[/] - Select an operation:")
			.PageSize(10)
			.AddChoices(new[] {
				"doctor", "check-health", "ship", "update", "genesis", "[red]Exit[/]"
			}));

	if (command.Contains("Exit"))
	{
		keepRunning = false;
		continue;
	}

	// 3. Resolve and Normalize Path [cite: 2026-01-13]
	string baseDir = AppDomain.CurrentDomain.BaseDirectory;
	string scriptPath = Path.Combine(baseDir, "scripts", $"{command}.sh").Replace("\\", "/");

	// Surgical WSL Path Strip
	if (scriptPath.Contains("wsl.localhost/"))
	{
		int index = scriptPath.IndexOf("Ubuntu_Final/");
		if (index != -1) scriptPath = "/" + scriptPath.Substring(index + "Ubuntu_Final/".Length);
	}
	scriptPath = scriptPath.Replace("//", "/");

	// 4. Execution
	if (!File.Exists(scriptPath))
	{
		AnsiConsole.MarkupLine($"[red]❌ Error:[/] Command [white]'{command}'[/] not found.");
	}
	else
	{
		AnsiConsole.MarkupLine($"[cyan]🚀 Launching {command}...[/]");

		var startInfo = new ProcessStartInfo
		{
			FileName = "bash",
			Arguments = scriptPath,
			UseShellExecute = false,
			CreateNoWindow = false,
			WorkingDirectory = Directory.GetCurrentDirectory()
		};

		// Ensure the shell script knows exactly where the user is standing
		startInfo.Environment["VENTURE_PROJECT_ROOT"] = Directory.GetCurrentDirectory();

		using (var process = Process.Start(startInfo))
		{
			process?.WaitForExit();
		}
	}

	// 5. The "Return to Menu" Pause
	AnsiConsole.WriteLine();
	AnsiConsole.MarkupLine("[grey]───────────────────────────────────────[/]");
	AnsiConsole.MarkupLine("✅ [yellow]Task Complete.[/] Press [green]ENTER[/] to return to the main menu...");

	while (Console.ReadKey(true).Key != ConsoleKey.Enter) { }
}

return 0;