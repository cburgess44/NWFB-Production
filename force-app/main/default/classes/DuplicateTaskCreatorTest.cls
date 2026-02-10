@isTest
private class DuplicateTaskCreatorTest {
    
    @testSetup
    static void setupTestData() {
        // Create a test Contact
        Account testAccount = new Account(Name = 'Test Household');
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create a test Service record
        Id clientRequestRecordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName().get('ClientRequest').getRecordTypeId();
        
        Service__c testService = new Service__c(
            RecordTypeId = clientRequestRecordTypeId,
            Contact__c = testContact.Id,
            Address__c = '123 Test Street',
            City__c = 'Seattle',
            State__c = 'WA',
            Zip__c = '98101',
            SubType__c = 'Delivery'
        );
        insert testService;
    }
    
    @isTest
    static void testQueueableExecution() {
        Service__c testService = [SELECT Id, Name, Address__c, City__c, State__c, Zip__c FROM Service__c LIMIT 1];
        String fullAddress = testService.Address__c + ', ' + testService.City__c + ', ' + testService.State__c + ' ' + testService.Zip__c;
        
        Test.startTest();
        System.enqueueJob(new DuplicateTaskCreator(testService.Id, testService.Name, fullAddress));
        Test.stopTest();
        
        // Verify Task was created
        List<Task> tasks = [SELECT Id, Subject, WhatId, Priority, Status FROM Task WHERE WhatId = :testService.Id];
        System.assertEquals(1, tasks.size(), 'One Task should have been created');
        System.assertEquals('Potential Duplicate - Review Required', tasks[0].Subject, 'Task subject should match');
        System.assertEquals('High', tasks[0].Priority, 'Task priority should be High');
        System.assertEquals('Not Started', tasks[0].Status, 'Task status should be Not Started');
    }
    
    @isTest
    static void testInvocableMethod() {
        Service__c testService = [SELECT Id, Name, Address__c, City__c, State__c, Zip__c FROM Service__c LIMIT 1];
        String fullAddress = testService.Address__c + ', ' + testService.City__c + ', ' + testService.State__c + ' ' + testService.Zip__c;
        
        DuplicateTaskCreator.TaskRequest req = new DuplicateTaskCreator.TaskRequest();
        req.serviceId = testService.Id;
        req.serviceName = testService.Name;
        req.serviceAddress = fullAddress;
        
        Test.startTest();
        DuplicateTaskCreator.createTaskAsync(new List<DuplicateTaskCreator.TaskRequest>{req});
        Test.stopTest();
        
        // Verify Task was created
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :testService.Id];
        System.assertEquals(1, tasks.size(), 'One Task should have been created');
    }
}
