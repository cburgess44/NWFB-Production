/**
 * Created by Gustavo on 05/01/24.
 */

@IsTest
private class ServiceDaoTest {
    @IsTest
    public static void setServiceName() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id
        );

        insert service;
        ServiceDao.getInstance().setServiceName();

        Service__c updatedService = [SELECT Id, Name FROM Service__c WHERE Id = :service.Id LIMIT 1];
        System.assert(updatedService.Name != null);
    }

    @IsTest
    public static void sendTripScheduledNotification() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test',
                Email = 'test@gmail.com'
        );
        insert contact;

        Location__c location = new Location__c(
                Name = 'Tacoma',
                City__c = 'Tacoma'
        );
        insert location;

        Truck__c truck = new Truck__c(
                LicensePlate__c = '00001',
                Active__c = true
        );
        insert truck;

        Trip__c trip = new Trip__c(
                Name = 'Test',
                Location__c = location.Id,
                Truck__c = truck.Id,
                PrimaryTimeframe__c = 'Morning',
                Date__c = Date.today()
        );
        insert trip;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Trip__c = trip.Id,
                Location__c = location.Id,
                Status__c = 'Routing',
                SubType__c = 'Delivery',
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request')
        );
        insert service;

        service.Status__c = 'Shopping';
        update service;

        System.assert(Limits.getEmailInvocations() > 0);
    }

    @IsTest
    public static void setAreaByZipCode() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Area__c area = new Area__c(
                ZipCode__c = '123'
        );
        insert area;

        Service__c service = new Service__c(
                Zip__c = '123',
                Contact__c = contact.Id
        );
        insert service;

        ServiceDao.getInstance().setAreaByZipCode();
        Service__c updatedService = [SELECT Id, Area__c FROM Service__c WHERE Id = :service.Id LIMIT 1];
        System.assert(updatedService.Area__c != null);
    }

    @IsTest
    public static void setPossibleDeleteDate() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id
        );
        insert service;

        Appointment__c appointment = new Appointment__c(
                Status__c = 'Scheduled',
                Service__c = service.Id
        );
        TriggerManagement.disableTrigger('AppointmentTrigger');
        insert appointment;
        TriggerManagement.enableTrigger('AppointmentTrigger');
        update service;


        ServiceDao.getInstance().setPossibleDeleteDate();
        Service__c updatedService = [SELECT Id, DeletionDate__c FROM Service__c WHERE Id = :service.Id LIMIT 1];

        System.assert(updatedService.DeletionDate__c != null);
    }

    @IsTest(SeeAllData=true)
    public static void sendEmailBasedOnStatus() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );

        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Status__c = 'Scheduled',
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request'),
                SubType__c = 'Will Call'
        );

        insert service;
    }

    @IsTest
    static void generateInvoiceAndSendPDF() {
        Account account = new Account(
                Name = 'Test Account',
                Type = 'Agency',
                Active__c = true
        );
        insert account;

        Contact serviceContact = new Contact(
                FirstName = 'Test',
                LastName = 'Test',
                Email = 'test@example.com'
        );

        insert serviceContact;


        Contact caseworker = new Contact(
                FirstName = 'caseworker',
                LastName = 'test',
                Email = 'caseworkertest@example.com',
                AccountId = account.Id,
                AP_Contact_Email__c = 'caseworkertest@example.com'
        );
        insert caseworker;
        caseworker.RecordTypeId = Utils.getRecordTypeId(Contact.SObjectType, 'Case Manager');
        update caseworker;

        AP_Contact__c apContact = new AP_Contact__c(
                Name = 'Test',
                Case_Worker__c = caseworker.Id,
                APContact__c = serviceContact.Id
        );
        insert apContact;

        Service__c service = new Service__c(
                Contact__c = serviceContact.Id,
                Status__c = 'Scheduled',
                Caseworker__c = caseworker.Id,
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request'),
                SubType__c = 'Will Call'
        );
        insert service;

        System.assert(ServiceDao.callGenerateInvoiceAndSendPDF(service.Id, true, true, true) == 'SentEmails');
    }

    @IsTest
    public static void testSendScheduledPickupMessage() {
        Contact serviceContact = new Contact(
                FirstName = 'Test',
                LastName = 'Test',
                Email = 'test@example.com',
                MobilePhone = '1123123123'
        );
        insert serviceContact;

        Location__c location = new Location__c(
                Name = 'Tacoma',
                City__c = 'Tacoma'
        );
        insert location;

        Truck__c truck = new Truck__c(
                LicensePlate__c = '00001',
                Active__c = true
        );
        insert truck;

        Trip__c trip = new Trip__c(
                Name = 'Test',
                Location__c = location.Id,
                Truck__c = truck.Id,
                PrimaryTimeframe__c = 'Morning',
                Date__c = Date.today()
        );
        insert trip;

        Service__c service = new Service__c(
                Contact__c = serviceContact.Id,
                Status__c = 'Processing',
                Trip__c = trip.Id,
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Donation Pickup'),
                SubType__c = 'Donation'
        );
        TriggerManagement.disableTrigger('ServiceTrigger');
        insert service;
        TriggerManagement.enableTrigger('ServiceTrigger');

        service.Status__c = 'Pick Up';
        update service;

        Service__c updatedService = [SELECT Id, Name FROM Service__c WHERE Id = :service.Id];

        String taskSubject = 'Donation Pickup ' + updatedService.Name + ' Confirmed';

        Task donationPickupConfirmedTask = [SELECT Id FROM Task WHERE WhatId =: service.Id AND Subject = :taskSubject];
        System.assert(donationPickupConfirmedTask != null);
    }

    @isTest
    public static void testLitTodelete() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );

        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Status__c = 'Scheduled',
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request'),
                SubType__c = 'Will Call'
        );

        insert service;

        List<Service__c> toDelete = new List<Service__c>{
                service
        };
        List<List<SObject>> listfromListToDelete = new List<List<SObject>>{
                toDelete
        };
        ServiceDao serviceClass = new ServiceDao();
        serviceClass.deleteDuplicateRecords(listfromListToDelete);
    }

    @IsTest
    public static void testAdjustTruckNotes() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );

        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Status__c = 'Scheduled',
                TruckNotes__c = 'Test',
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request'),
                SubType__c = 'Will Call'
        );
        insert service;

        service.TruckNotes__c = 'Testing';
        update service;
    }


}