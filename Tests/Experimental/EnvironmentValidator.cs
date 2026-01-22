using NUnit.Framework;
using System.Runtime.InteropServices;

namespace Venture.Tool.Framework.Tests.Experimental
{
	[TestFixture]
	public class EnvironmentValidator
	{
		[Test]
		public void VerifyNoWindowsPathContamination()
		{
			// Check if we are running in the intended Linux environment
			bool isLinux = RuntimeInformation.IsOSPlatform(OSPlatform.Linux);
			Assert.That(isLinux, Is.True, "Venture Tool must be built/tested in the Linux/WSL environment.");

			// Check for common cross-contamination indicators in the working directory
			var currentDir = Directory.GetCurrentDirectory();
			Assert.That(currentDir, Does.Not.Contain("C:"), "Project path contains Windows drive letters. Potential cross-contamination!");
		}
	}
}