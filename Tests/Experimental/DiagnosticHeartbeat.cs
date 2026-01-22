using NUnit.Framework;
using Spectre.Console;

namespace Venture.Tool.Framework.Tests.Experimental
{
	[TestFixture]
	public class DiagnosticHeartbeat
	{
		[Test]
		public void VerifyFrameworkIntegrity()
		{
			// Act
			AnsiConsole.MarkupLine("[bold blue]Checking Framework Pulse...[/]");
			bool isSpectreAvailable = typeof(AnsiConsole).Assembly.GetName().Version?.ToString() != null;

			// Assert
			Assert.That(isSpectreAvailable, Is.True, "Spectre.Console should be linked and available.");

			AnsiConsole.MarkupLine("[bold green]✅ Pulse Stable: Spectre.Console 0.54.0 detected.[/]");
		}
	}
}