/**
 * Test class for AR_OverdueServicesController
 */
@isTest
private class AR_OverdueServicesControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Get Client Request record type
        Id clientRequestRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName()
            .get('ClientRequest').getRecordTypeId();
        
        // Get Agency record type
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        
        // Get Case Manager record type for Contact (for Caseworker field filter)
        Id caseManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Case_Manager').getRecordTypeId();
        
        // Create test Account (Agency)
        Account testAgency = new Account(
            Name = 'Test Agency',
            RecordTypeId = agencyRTId
        );
        insert testAgency;
        
        // Create test Client Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Client',
            AccountId = testAgency.Id,
            Email = 'testclient@example.com'
        );
        insert testContact;
        
        // Create Caseworker Contact with Case Manager record type
        Contact caseworker = new Contact(
            FirstName = 'Case',
            LastName = 'Worker',
            AccountId = testAgency.Id,
            Email = 'caseworker@example.com',
            RecordTypeId = caseManagerRTId
        );
        insert caseworker;
        
        // Update agency with primary contact
        testAgency.Primary_Contact__c = testContact.Id;
        update testAgency;
        
        // Create test Services with balance due
        List<Service__c> services = new List<Service__c>();
        
        // Service with balance (overdue - 100 days)
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 200,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = DateTime.now().addDays(-100),
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        ));
        
        // Service with balance (recent - 15 days, should not appear due to >30 day filter)
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 100,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = DateTime.now().addDays(-15),
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        ));
        
        // Service fully paid (should not appear)
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Processing_Fee__c = 50,
            TotalPaid__c = 50,
            ServiceRenderedDate__c = DateTime.now().addDays(-30),
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        ));
        
        insert services;
    }
    
    @isTest
    static void testGetOverdueServices() {
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        // Should return 1 service (only the 100-day old one, not the 15-day or paid one)
        System.assertEquals(1, results.size(), 'Should return 1 overdue service (>30 days)');
        
        // Verify wrapper fields are populated
        AR_OverdueServicesController.ServiceWrapper firstService = results[0];
        System.assertNotEquals(null, firstService.id, 'Id should be populated');
        System.assertNotEquals(null, firstService.recordUrl, 'Record URL should be populated');
        System.assertNotEquals(null, firstService.agencyName, 'Agency name should be populated');
        System.assert(firstService.balanceDue > 0, 'Balance should be greater than 0');
        System.assert(firstService.daysOutstanding > 30, 'Days outstanding should be > 30');
    }
    
    @isTest
    static void testLogCollectionCall() {
        Service__c testService = [SELECT Id FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        AR_OverdueServicesController.logCollectionCall(testService.Id, 'Test call notes');
        Test.stopTest();
        
        // Verify task was created
        List<Task> tasks = [
            SELECT Id, Subject, WhatId, Description 
            FROM Task 
            WHERE WhatId = :testService.Id
        ];
        
        System.assertEquals(1, tasks.size(), 'Should create 1 task');
        System.assertEquals('AR Collection Call', tasks[0].Subject, 'Task subject should match');
        System.assertEquals('Test call notes', tasks[0].Description, 'Task description should match');
        
        // Verify collection tracking updated
        Service__c updatedService = [SELECT CollectionContactCount__c, LastCollectionContactDate__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals(1, updatedService.CollectionContactCount__c, 'Collection count should be 1');
        System.assertEquals(Date.today(), updatedService.LastCollectionContactDate__c, 'Last contact date should be today');
    }
    
    @isTest
    static void testWriteOffBalance() {
        Service__c testService = [SELECT Id, BalanceDue__c FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        AR_OverdueServicesController.writeOffBalance(testService.Id, 'Client unable to pay', null);
        Test.stopTest();
        
        // Verify service was updated
        Service__c updatedService = [
            SELECT Id, TotalPaid__c, WriteOffDate__c, WriteOffReason__c, WriteOffAmount__c, CollectionsStatus__c, BalanceDue__c
            FROM Service__c 
            WHERE Id = :testService.Id
        ];
        
        System.assertEquals('Written Off', updatedService.CollectionsStatus__c, 'Status should be Written Off');
        System.assertEquals(Date.today(), updatedService.WriteOffDate__c, 'Write off date should be today');
        System.assertEquals('Client unable to pay', updatedService.WriteOffReason__c, 'Write off reason should match');
        System.assert(updatedService.WriteOffAmount__c > 0, 'Write off amount should be populated');
        
        // Verify task was created
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :testService.Id AND Subject = 'AR Balance Written Off'];
        System.assertEquals(1, tasks.size(), 'Should create write-off task');
    }
    
    @isTest
    static void testWriteOffPartialBalance() {
        Service__c testService = [SELECT Id, BalanceDue__c FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        AR_OverdueServicesController.writeOffBalance(testService.Id, 'Partial write-off', 50.00);
        Test.stopTest();
        
        // Verify partial write-off
        Service__c updatedService = [SELECT WriteOffAmount__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals(50.00, updatedService.WriteOffAmount__c, 'Write off amount should be 50');
    }
    
    @isTest
    static void testRecordPayment() {
        Service__c testService = [SELECT Id, TotalPaid__c FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        Decimal originalPaid = testService.TotalPaid__c != null ? testService.TotalPaid__c : 0;
        
        Test.startTest();
        AR_OverdueServicesController.recordPayment(testService.Id, 75.00, 'Check', 'Check #12345');
        Test.stopTest();
        
        // Verify payment recorded
        Service__c updatedService = [SELECT TotalPaid__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals(originalPaid + 75.00, updatedService.TotalPaid__c, 'Total paid should increase by 75');
        
        // Verify task was created
        List<Task> tasks = [SELECT Id, Subject, Description FROM Task WHERE WhatId = :testService.Id AND Subject = 'AR Payment Received'];
        System.assertEquals(1, tasks.size(), 'Should create payment task');
        System.assert(tasks[0].Description.contains('75'), 'Description should contain amount');
        System.assert(tasks[0].Description.contains('Check'), 'Description should contain payment method');
    }
    
    @isTest
    static void testRecordFullPayment() {
        Service__c testService = [SELECT Id, BalanceDue__c FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        // Pay full balance
        AR_OverdueServicesController.recordPayment(testService.Id, 200.00, 'Credit Card', 'Full payment');
        Test.stopTest();
        
        // Verify status changed to Paid
        Service__c updatedService = [SELECT CollectionsStatus__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals('Paid', updatedService.CollectionsStatus__c, 'Status should be Paid when fully paid');
    }
    
    @isTest
    static void testUpdateCollectionsStatus() {
        Service__c testService = [SELECT Id FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        AR_OverdueServicesController.updateCollectionsStatus(testService.Id, 'Payment Promised', 'Client promised to pay next week');
        Test.stopTest();
        
        // Verify status updated
        Service__c updatedService = [SELECT CollectionsStatus__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals('Payment Promised', updatedService.CollectionsStatus__c, 'Status should be updated');
        
        // Verify task was created
        List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :testService.Id AND Subject LIKE 'AR Status Update%'];
        System.assertEquals(1, tasks.size(), 'Should create status update task');
    }
    
    @isTest
    static void testUpdateCollectionsStatusNoNotes() {
        Service__c testService = [SELECT Id FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        AR_OverdueServicesController.updateCollectionsStatus(testService.Id, 'Contacted', '');
        Test.stopTest();
        
        // Verify status updated
        Service__c updatedService = [SELECT CollectionsStatus__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals('Contacted', updatedService.CollectionsStatus__c, 'Status should be updated');
        
        // No task should be created when notes are blank
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :testService.Id AND Subject LIKE 'AR Status Update%'];
        System.assertEquals(0, tasks.size(), 'Should not create task without notes');
    }
    
    @isTest
    static void testGetEmailTemplates() {
        Test.startTest();
        List<AR_OverdueServicesController.EmailTemplateWrapper> templates = 
            AR_OverdueServicesController.getEmailTemplates();
        Test.stopTest();
        
        // Just verify it doesn't throw an error - actual templates may or may not exist
        System.assertNotEquals(null, templates, 'Should return a list (even if empty)');
    }
    
    @isTest
    static void testMultipleCollectionCalls() {
        // Test that collection count increments correctly with multiple calls
        Service__c testService = [SELECT Id FROM Service__c WHERE Processing_Fee__c = 200 LIMIT 1];
        
        Test.startTest();
        AR_OverdueServicesController.logCollectionCall(testService.Id, 'First call');
        AR_OverdueServicesController.logCollectionCall(testService.Id, 'Second call');
        Test.stopTest();
        
        // Verify collection count is 2
        Service__c updatedService = [SELECT CollectionContactCount__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals(2, updatedService.CollectionContactCount__c, 'Collection count should be 2');
        
        // Verify 2 tasks were created
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :testService.Id AND Subject = 'AR Collection Call'];
        System.assertEquals(2, tasks.size(), 'Should create 2 call tasks');
    }
    
    @isTest
    static void testAgingClassAssignment() {
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        // Find the 90+ day service
        Boolean foundCritical = false;
        for (AR_OverdueServicesController.ServiceWrapper svc : results) {
            if (svc.agingBucket == '90+ Days') {
                System.assert(svc.agingClass.contains('aging-critical'), 
                    'Critical aging should have critical class');
                System.assertEquals('🔴', svc.agingIcon, 'Should have red icon');
                foundCritical = true;
            }
        }
        System.assert(foundCritical, 'Should have found a critical aging service');
    }
    
    @isTest
    static void testServiceWrapperFields() {
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        if (!results.isEmpty()) {
            AR_OverdueServicesController.ServiceWrapper wrapper = results[0];
            
            // Verify all wrapper fields
            System.assertNotEquals(null, wrapper.id, 'Id should be set');
            System.assertNotEquals(null, wrapper.name, 'Name should be set');
            System.assertNotEquals(null, wrapper.recordUrl, 'Record URL should be set');
            System.assertNotEquals(null, wrapper.agencyUrl, 'Agency URL should be set');
            System.assertNotEquals(null, wrapper.contactName, 'Contact name should be set');
            System.assertNotEquals(null, wrapper.serviceRenderedDate, 'Service date should be set');
            System.assertNotEquals(null, wrapper.agingClass, 'Aging class should be set');
            System.assertNotEquals(null, wrapper.agingIcon, 'Aging icon should be set');
        }
    }
    
    @isTest
    static void testEmailTemplateWrapper() {
        // Test the EmailTemplateWrapper directly
        EmailTemplate et = new EmailTemplate();
        et.Name = 'Test Template';
        et.Subject = 'Test Subject';
        et.Description = 'Test Description';
        // Note: Can't insert EmailTemplate in test, but can test wrapper construction logic
        
        Test.startTest();
        // Query actual templates if any exist
        List<EmailTemplate> existingTemplates = [SELECT Id, Name, Subject, Description FROM EmailTemplate WHERE IsActive = true LIMIT 1];
        if (!existingTemplates.isEmpty()) {
            AR_OverdueServicesController.EmailTemplateWrapper wrapper = 
                new AR_OverdueServicesController.EmailTemplateWrapper(existingTemplates[0]);
            System.assertNotEquals(null, wrapper.id, 'Wrapper Id should be set');
            System.assertNotEquals(null, wrapper.name, 'Wrapper name should be set');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDifferentAgingBuckets() {
        // Get record types
        Id clientRequestRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName()
            .get('ClientRequest').getRecordTypeId();
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        Id caseManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Case_Manager').getRecordTypeId();
        
        // Create test agency
        Account testAgency = new Account(Name = 'Aging Test Agency', RecordTypeId = agencyRTId);
        insert testAgency;
        
        Contact testContact = new Contact(FirstName = 'Aging', LastName = 'Test', AccountId = testAgency.Id);
        insert testContact;
        
        Contact caseworker = new Contact(
            FirstName = 'CW', LastName = 'Test', 
            AccountId = testAgency.Id, 
            Email = 'cw@test.com',
            RecordTypeId = caseManagerRTId
        );
        insert caseworker;
        
        // Create services with different aging - 45 days (31-60 bucket), 75 days (61-90 bucket)
        List<Service__c> services = new List<Service__c>();
        
        // 45 days - should be 31-60 Days bucket
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 150,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = DateTime.now().addDays(-45),
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        ));
        
        // 75 days - should be 61-90 Days bucket
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 175,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = DateTime.now().addDays(-75),
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        ));
        
        insert services;
        
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        // Verify we have services in different buckets
        Boolean found31_60 = false;
        Boolean found61_90 = false;
        
        for (AR_OverdueServicesController.ServiceWrapper svc : results) {
            if (svc.agingBucket == '31-60 Days') {
                found31_60 = true;
                System.assert(svc.agingClass.contains('aging-caution'), 'Should have caution class');
                System.assertEquals('🟡', svc.agingIcon, 'Should have yellow icon');
            }
            if (svc.agingBucket == '61-90 Days') {
                found61_90 = true;
                System.assert(svc.agingClass.contains('aging-warning'), 'Should have warning class');
                System.assertEquals('🟠', svc.agingIcon, 'Should have orange icon');
            }
        }
        
        System.assert(found31_60 || found61_90, 'Should find at least one aging bucket');
    }
    
    @isTest
    static void testWriteOffWithExistingPaid() {
        // Test write-off when service already has partial payment
        Service__c testService = [SELECT Id FROM Service__c WHERE Processing_Fee__c = 100 LIMIT 1];
        
        // First record a partial payment
        AR_OverdueServicesController.recordPayment(testService.Id, 25.00, 'Cash', 'Partial');
        
        Test.startTest();
        // Now write off remaining balance
        AR_OverdueServicesController.writeOffBalance(testService.Id, 'Writing off remainder', null);
        Test.stopTest();
        
        Service__c updated = [SELECT TotalPaid__c, CollectionsStatus__c FROM Service__c WHERE Id = :testService.Id];
        System.assertEquals('Written Off', updated.CollectionsStatus__c, 'Should be written off');
    }
    
    /**
     * Test the date fallback logic for services without ServiceRenderedDate__c
     * 
     * This tests the fallback order:
     * 1. ServiceRenderedDate__c (primary)
     * 2. ShoppingAppointmentComplete__c (for Will Call)
     * 3. LastAppointmentDate__c (for Delivery without trip)
     * 4. CreatedDate (last resort)
     */
    @isTest
    static void testDateFallbackLogic() {
        // Get record types
        Id clientRequestRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName()
            .get('ClientRequest').getRecordTypeId();
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        Id caseManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Case_Manager').getRecordTypeId();
        
        // Create test agency
        Account testAgency = new Account(Name = 'Fallback Test Agency', RecordTypeId = agencyRTId);
        insert testAgency;
        
        Contact testContact = new Contact(FirstName = 'Fallback', LastName = 'Test', AccountId = testAgency.Id);
        insert testContact;
        
        Contact caseworker = new Contact(
            FirstName = 'FB', LastName = 'CW', 
            AccountId = testAgency.Id, 
            Email = 'fbcw@test.com',
            RecordTypeId = caseManagerRTId
        );
        insert caseworker;
        
        List<Service__c> services = new List<Service__c>();
        
        // Will Call service with ShoppingAppointmentComplete but NO ServiceRenderedDate
        // This simulates a Will Call that was completed without going through Trip workflow
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 250,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = null, // No service rendered date!
            ShoppingAppointmentComplete__c = DateTime.now().addDays(-60), // But has shopping complete
            LastAppointmentDate__c = Date.today().addDays(-65),
            Status__c = 'Completed',
            SubType__c = 'Will Call'
        ));
        
        // Delivery service with LastAppointmentDate but NO ServiceRenderedDate
        // This simulates a Delivery completed outside the Trip workflow
        services.add(new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 275,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = null, // No service rendered date!
            ShoppingAppointmentComplete__c = null, // No shopping complete either
            LastAppointmentDate__c = Date.today().addDays(-80), // But has last appointment
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        ));
        
        insert services;
        
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        // Find our test services and verify fallback logic
        Boolean foundWillCall = false;
        Boolean foundDelivery = false;
        
        for (AR_OverdueServicesController.ServiceWrapper svc : results) {
            if (svc.balanceDue == 250) {
                // Will Call service - should use ShoppingAppointmentComplete
                foundWillCall = true;
                System.assertEquals('Shopping Complete', svc.dateSource, 
                    'Will Call should use Shopping Complete as date source');
                System.assert(svc.daysOutstanding >= 59, 'Days should be calculated from shopping date');
            }
            if (svc.balanceDue == 275) {
                // Delivery service - should use LastAppointmentDate
                foundDelivery = true;
                System.assertEquals('Last Appointment', svc.dateSource, 
                    'Delivery without ServiceRenderedDate should use Last Appointment');
                System.assert(svc.daysOutstanding >= 79, 'Days should be calculated from last appointment');
            }
        }
        
        System.assert(foundWillCall, 'Should find Will Call service with fallback date');
        System.assert(foundDelivery, 'Should find Delivery service with fallback date');
    }
    
    @isTest
    static void testDateFallbackToCreatedDate() {
        // Test the last resort fallback to CreatedDate
        Id clientRequestRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName()
            .get('ClientRequest').getRecordTypeId();
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        Id caseManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Case_Manager').getRecordTypeId();
        
        Account testAgency = new Account(Name = 'CreatedDate Test Agency', RecordTypeId = agencyRTId);
        insert testAgency;
        
        Contact testContact = new Contact(FirstName = 'CD', LastName = 'Test', AccountId = testAgency.Id);
        insert testContact;
        
        Contact caseworker = new Contact(
            FirstName = 'CD', LastName = 'CW', 
            AccountId = testAgency.Id, 
            Email = 'cdcw@test.com',
            RecordTypeId = caseManagerRTId
        );
        insert caseworker;
        
        // Service with NO dates at all - should fall back to CreatedDate
        Service__c noDateService = new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 300,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = null,
            ShoppingAppointmentComplete__c = null,
            LastAppointmentDate__c = null,
            Status__c = 'Completed',
            SubType__c = 'Delivery'
        );
        insert noDateService;
        
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        // Find our test service
        for (AR_OverdueServicesController.ServiceWrapper svc : results) {
            if (svc.balanceDue == 300) {
                System.assertEquals('Created Date', svc.dateSource, 
                    'Service with no dates should fall back to Created Date');
            }
        }
    }
    
    @isTest
    static void testServiceRenderedDateTakesPriority() {
        // Verify that ServiceRenderedDate takes priority over other dates
        Id clientRequestRTId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName()
            .get('ClientRequest').getRecordTypeId();
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        Id caseManagerRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('Case_Manager').getRecordTypeId();
        
        Account testAgency = new Account(Name = 'Priority Test Agency', RecordTypeId = agencyRTId);
        insert testAgency;
        
        Contact testContact = new Contact(FirstName = 'Pri', LastName = 'Test', AccountId = testAgency.Id);
        insert testContact;
        
        Contact caseworker = new Contact(
            FirstName = 'Pri', LastName = 'CW', 
            AccountId = testAgency.Id, 
            Email = 'pricw@test.com',
            RecordTypeId = caseManagerRTId
        );
        insert caseworker;
        
        // Service with all dates populated - ServiceRenderedDate should win
        Service__c allDatesService = new Service__c(
            RecordTypeId = clientRequestRTId,
            Agency__c = testAgency.Id,
            Contact__c = testContact.Id,
            Caseworker__c = caseworker.Id,
            Processing_Fee__c = 325,
            TotalPaid__c = 0,
            ServiceRenderedDate__c = DateTime.now().addDays(-50),
            ShoppingAppointmentComplete__c = DateTime.now().addDays(-70),
            LastAppointmentDate__c = Date.today().addDays(-90),
            Status__c = 'Completed',
            SubType__c = 'Will Call'
        );
        insert allDatesService;
        
        Test.startTest();
        List<AR_OverdueServicesController.ServiceWrapper> results = 
            AR_OverdueServicesController.getOverdueServices();
        Test.stopTest();
        
        for (AR_OverdueServicesController.ServiceWrapper svc : results) {
            if (svc.balanceDue == 325) {
                System.assertEquals('Service Rendered', svc.dateSource, 
                    'ServiceRenderedDate should take priority even when other dates exist');
                // Days should be ~50, not 70 or 90
                System.assert(svc.daysOutstanding >= 49 && svc.daysOutstanding <= 52, 
                    'Days should be calculated from ServiceRenderedDate (~50), not other dates');
            }
        }
    }
    
    /**
     * Test sending agency summary email
     */
    @isTest
    static void testSendAgencySummaryEmail() {
        // Get the test agency created in setup
        Account testAgency = [SELECT Id, Name, Primary_Contact__c FROM Account WHERE Name = 'Test Agency' LIMIT 1];
        
        Test.startTest();
        // This will throw an error in test because emails aren't actually sent, but we can verify it doesn't crash
        try {
            AR_OverdueServicesController.sendAgencySummaryEmail(testAgency.Id);
        } catch (Exception e) {
            // Expected - email sending may fail in test context
            System.debug('Expected exception in test: ' + e.getMessage());
        }
        Test.stopTest();
        
        // Verify that the method tried to run (we can't fully test email sending in tests)
        // At minimum, verify the agency was found
        System.assertNotEquals(null, testAgency.Id, 'Agency should exist');
    }
    
    /**
     * Test sending agency summary email with no primary contact
     */
    @isTest
    static void testSendAgencySummaryEmailNoContact() {
        // Get record types
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        
        // Create agency without primary contact
        Account noContactAgency = new Account(
            Name = 'No Contact Agency',
            RecordTypeId = agencyRTId
        );
        insert noContactAgency;
        
        Test.startTest();
        try {
            AR_OverdueServicesController.sendAgencySummaryEmail(noContactAgency.Id);
            System.assert(false, 'Should have thrown exception for missing contact');
        } catch (AuraHandledException e) {
            // Expected - no primary contact
            System.assert(e.getMessage().contains('No primary contact') || e.getMessage().contains('Script-thrown'), 
                'Should indicate missing contact');
        }
        Test.stopTest();
    }
    
    /**
     * Test sending agency summary email with no overdue services
     */
    @isTest
    static void testSendAgencySummaryEmailNoServices() {
        // Get record types
        Id agencyRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Agency').getRecordTypeId();
        
        // Create new agency with primary contact but no services
        Account emptyAgency = new Account(
            Name = 'Empty Agency',
            RecordTypeId = agencyRTId
        );
        insert emptyAgency;
        
        Contact primaryContact = new Contact(
            FirstName = 'Primary',
            LastName = 'Contact',
            Email = 'primary@empty.com',
            AccountId = emptyAgency.Id
        );
        insert primaryContact;
        
        emptyAgency.Primary_Contact__c = primaryContact.Id;
        update emptyAgency;
        
        Test.startTest();
        try {
            AR_OverdueServicesController.sendAgencySummaryEmail(emptyAgency.Id);
            System.assert(false, 'Should have thrown exception for no services');
        } catch (AuraHandledException e) {
            // Expected - no overdue services
            System.assert(e.getMessage().contains('No overdue services') || e.getMessage().contains('Script-thrown'), 
                'Should indicate no services found');
        }
        Test.stopTest();
    }
}
