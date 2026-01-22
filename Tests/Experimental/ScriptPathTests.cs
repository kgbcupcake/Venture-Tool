using NUnit.Framework;

namespace Venture.Tool.Framework.Tests.Experimental
{
	[TestFixture]
	public class ScriptPathTests
	{
		[Test]
		public void VerifyScriptPathNormalization()
		{
			string mockWslPath = @"\\wsl.localhost\Ubuntu_Final\home\onlyo\VsProject\Venture-Tool\bin\Debug\net8.0\scripts\doctor.sh";

			// Replicating your Program.cs logic
			string scriptPath = mockWslPath.Replace("\\", "/");
			if (scriptPath.Contains("wsl.localhost/"))
			{
				int index = scriptPath.IndexOf("Ubuntu_Final/");
				if (index != -1) scriptPath = "/" + scriptPath.Substring(index + "Ubuntu_Final/".Length);
			}

			Assert.That(scriptPath, Is.EqualTo("/home/onlyo/VsProject/Venture-Tool/bin/Debug/net8.0/scripts/doctor.sh"));
		}
	}
}