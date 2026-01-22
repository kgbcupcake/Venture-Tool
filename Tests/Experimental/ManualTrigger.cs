using NUnit.Framework;

namespace Venture.Tool.Framework.Tests.Experimental
{
	[TestFixture]
	public class ManualTrigger
	{
		[Test]
		public void Ping()
		{
			// If this runs, the "Call" mechanism is working.
			Console.WriteLine("Test Engine Uplink: ACTIVE");
			Assert.Pass();
		}
	}
}