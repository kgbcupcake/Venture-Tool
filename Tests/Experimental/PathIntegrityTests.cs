using NUnit.Framework;
using System.IO;

namespace Venture.Tool.Framework.Tests.Experimental
{
	[TestFixture]
	public class PathIntegrityTests
	{
		[Test]
		public void VerifyProjectRootDiscovery()
		{
			// This simulates how your scripts should find the .csproj
			var currentDir = new DirectoryInfo(Directory.GetCurrentDirectory());

			// Travel up until we find the .csproj or hit the root
			DirectoryInfo? root = currentDir;
			while (root != null && root.GetFiles("*.csproj").Length == 0)
			{
				root = root.Parent;
			}

			Assert.That(root, Is.Not.Null, "Could not locate .csproj in any parent directory. Pathing is broken!");
			TestContext.WriteLine($"✅ Project Anchor Found at: {root!.FullName}");
		}
	}
}