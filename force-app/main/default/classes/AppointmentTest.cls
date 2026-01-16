@IsTest
public with sharing class AppointmentTest {

    @IsTest
    public static void sendEmailConfirmationBasedOnStatusTest() {

        Account account = createAccount();
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Service__c service = createService(contact);
        insert service;

        Appointment__c appointment = createScheduledAppointment(service);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AppointmentMock());
        insert appointment;
        Test.stopTest();

        Task task = [SELECT Id FROM Task LIMIT 1];

        System.assertEquals(true, task != null);
    }

    @IsTest
    public static void serviceStatusChangeTest() {

        Account account = createAccount();
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Service__c service = createService(contact);
        service.RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'General Delivery');
        service.SubType__c = 'Event';
        insert service;

        Appointment__c appointment = createScheduledAppointment(service);


        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AppointmentMock());
        insert appointment;
        Test.stopTest();

        Service__c updatedService = [SELECT Id, Status__c FROM Service__c LIMIT 1];

        System.assertEquals('Processing', updatedService.Status__c);
    }

    private static Account createAccount() {
        return new Account(
                Name = 'Test Account',
                Type = 'Agency',
                Active__c = true
        );
    }

    private static Contact createContact(Account account) {
        return new Contact(
                AccountId = account.Id,
                FirstName = 'Test Contact',
                LastName = 'Last name test contact',
                Email = 'testEmail@exemple.com',
                MobilePhone = '9999999999'
        );
    }

    private static Service__c createService(Contact contact) {
        return new Service__c(
                Contact__c = contact.Id,
                Status__c = 'Processing',
                Pickup_type__c = 'Delivery',
                RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request'),
                SubType__c = 'Delivery'
        );
    }

    private static Appointment__c createScheduledAppointment(Service__c service) {
        return new Appointment__c(
                Service__c = service.Id,
                Status__c = 'Scheduled',
                Time__c = '9:15am',
                Date__c = System.today()
        );
    }

    @IsTest
    public static void updateServiceStatusAndAppointment() {
        Account account = createAccount();
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Service__c service = createService(contact);
//
//        service.RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request');
//        service.SubType__c = 'Delivery';

        insert service;

        Appointment__c appointment = createScheduledAppointment(service);
        Appointment__c noShowAppointment = createScheduledAppointment(service);
        noShowAppointment.Status__c = 'No Show';
        
        TriggerManagement.disableTrigger('ServiceTrigger');
        Test.setMock(HttpCalloutMock.class, new AppointmentMock());
        
        Test.startTest();
        insert appointment;
        insert noShowAppointment;
        Test.stopTest();
        
        TriggerManagement.disableTrigger('TaskTrigger');

        Service__c updatedService = [SELECT Id, Status__c FROM Service__c WHERE Id = :service.Id];
        System.assertEquals('Scheduled', updatedService.Status__c);
    }

    @IsTest
    public static void testCreateEmailTask() {
        TriggerManagement.disableTrigger('ServiceTrigger');
        TriggerManagement.disableTrigger('AppointmentTrigger');

        Account account = createAccount();
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Service__c service = createService(contact);
        insert service;

        Appointment__c scheduledAppointment = createScheduledAppointment(service);
        insert scheduledAppointment;

        Task createdTask = Appointment.createEmailTask(
                scheduledAppointment,
                service,
               null
        );

        System.assert(createdTask != null);
    }
}