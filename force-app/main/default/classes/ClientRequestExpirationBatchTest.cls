/**
 * Created by Eric Solari on 03/01/2024.
 */
@IsTest
public with sharing class ClientRequestExpirationBatchTest {
    @IsTest
    public static void testBatch(){
        Id recordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName().get('ClientRequest').getRecordTypeId();
        Location__c location = new Location__c(Name = 'Tacoma');
        insert location;
        Service__c service = new Service__c(RecordTypeId = recordTypeId, Location__c = location.Id, SubType__c='Delivery');
        insert  service;

        ClientRequestExpirationBatch scb = new ClientRequestExpirationBatch();
        Id jobid= Database.executeBatch(scb,5);
    }

    @IsTest
    public static void testBatchClientExpired(){
        Id recordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName().get('ClientRequest').getRecordTypeId();
        Id contactRT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Case_Manager').getRecordTypeId();

        Account acc = createAccount();
        insert acc;
        Contact contact = createContact(acc);
        contact.npe01__WorkEmail__c = 'eemail@test.com';
        contact.RecordTypeId = contactRT;
        contact.npe01__Preferred_Email__c = 'Work';
        insert contact;

        Location__c location = new Location__c(Name = 'Tacoma');
        insert location;
        Service__c service = new Service__c(Agency__c= acc.Id, Caseworker__c = contact.Id, RecordTypeId = recordTypeId, Location__c = location.Id, SubType__c='Delivery');
        insert  service;
        Test.setCreatedDate(service.Id, System.today().addDays(-60));
        Test.startTest();
        ClientRequestExpirationBatch scb = new ClientRequestExpirationBatch();
        Id jobid= Database.executeBatch(scb,5);
        Test.stopTest();
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
                MobilePhone = '99999999'
        );
    }
}