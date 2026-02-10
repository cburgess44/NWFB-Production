@isTest
private class DuplicateReviewControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Household'
        );
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Person',
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    @isTest
    static void testGetMatchingServicesNoMatches() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Get ClientRequest record type
        RecordType clientRequestRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Service__c' 
            AND DeveloperName = 'ClientRequest' 
            LIMIT 1
        ];
        
        // Create a service with unique address
        Service__c testService = new Service__c(
            RecordTypeId = clientRequestRT.Id,
            Contact__c = testContact.Id,
            Address__c = '123 Unique Street',
            City__c = 'Seattle',
            State__c = 'WA',
            Zip__c = '98101',
            SubType__c = 'Delivery'
        );
        insert testService;
        
        Test.startTest();
        List<Service__c> results = DuplicateReviewController.getMatchingServices(testService.Id);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return no matches for unique address');
    }
    
    @isTest
    static void testGetMatchingServicesWithMatches() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        RecordType clientRequestRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Service__c' 
            AND DeveloperName = 'ClientRequest' 
            LIMIT 1
        ];
        
        // Create first service at an address
        Service__c service1 = new Service__c(
            RecordTypeId = clientRequestRT.Id,
            Contact__c = testContact.Id,
            Address__c = '456 Main Street',
            City__c = 'Tacoma',
            State__c = 'WA',
            Zip__c = '98402',
            SubType__c = 'Delivery'
        );
        insert service1;
        
        // Create second service at same address (different apartment)
        Service__c service2 = new Service__c(
            RecordTypeId = clientRequestRT.Id,
            Contact__c = testContact.Id,
            Address__c = '456 Main Avenue Apt 2',
            City__c = 'Tacoma',
            State__c = 'WA',
            Zip__c = '98402',
            SubType__c = 'Delivery'
        );
        insert service2;
        
        Test.startTest();
        List<Service__c> results = DuplicateReviewController.getMatchingServices(service2.Id);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return 1 match with same street number');
        System.assertEquals(service1.Id, results[0].Id, 'Should return the first service as match');
    }
    
    @isTest
    static void testGetMatchingServicesNullAddress() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        RecordType clientRequestRT = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Service__c' 
            AND DeveloperName = 'ClientRequest' 
            LIMIT 1
        ];
        
        // Create service with null address
        Service__c testService = new Service__c(
            RecordTypeId = clientRequestRT.Id,
            Contact__c = testContact.Id,
            City__c = 'Seattle',
            State__c = 'WA',
            Zip__c = '98101',
            SubType__c = 'Delivery'
        );
        insert testService;
        
        Test.startTest();
        List<Service__c> results = DuplicateReviewController.getMatchingServices(testService.Id);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null address');
    }
}
