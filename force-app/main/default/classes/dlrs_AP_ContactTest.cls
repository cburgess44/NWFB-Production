/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_AP_ContactTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_AP_ContactTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new AP_Contact__c());
    }
}