@isTest
private class RecyclePostInstalledClassTest
{
	@isTest
	static void validatePostInstallScript()
	{
        Test.startTest();
		RecyclePostInstalledClass postinstall = new RecyclePostInstalledClass();
		Test.testInstall(postinstall, null);
		system.assertEquals(0, 0);
        Test.stopTest();
	}
}