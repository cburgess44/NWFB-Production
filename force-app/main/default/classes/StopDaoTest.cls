/**
 * Created by Gustavo on 04/01/24.
 */

@IsTest
public with sharing class StopDaoTest {

    @TestSetup
    static void setup() {
        Schema.DescribeSObjectResult describeService = Service__c.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = describeService.getRecordTypeInfosByName();

        Truck__c truck = new Truck__c(
                LicensePlate__c = '00001',
                Active__c = true
        );
        insert truck;

        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Address__c = 'Teste',
                Status__c = 'Routing',
                RecordTypeId = recordTypeInfoMap.get('General Pickup').getRecordTypeId(),
                SubType__c = 'Event'
        );
        insert service;

//        Trip__c trip = new Trip__c(
//                Name = 'Test',
//                Truck__c = truck.Id,
//                Date__c = Date.today(),
//                Contact__c = contact.Id,
//                Service__c = service.Id
//        );
//        insert trip;


        Stop__c stop = new Stop__c(
                Service__c = service.Id
        );
        insert stop;
    }

    @IsTest
    public static void stopComplete() {
        Stop__c stop = [SELECT Id FROM Stop__c LIMIT 1];
        update stop;
    }

    @IsTest
    public static void calculateStopTime() {
        Schema.DescribeSObjectResult describeService = Service__c.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = describeService.getRecordTypeInfosByName();

        Truck__c truck = new Truck__c(
                LicensePlate__c = '00001',
                Active__c = true
        );
        insert truck;

        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Address__c = 'Teste',
                Status__c = 'Routing',
                RecordTypeId = recordTypeInfoMap.get('Donation Pickup').getRecordTypeId(),
                SubType__c = 'Event'
        );
        insert service;

        ServiceItem__c serviceItem = new ServiceItem__c(
                Quantity__c = 13,
                Service__c = service.Id
        );
        insert serviceItem;

        Stop__c stop = new Stop__c(
                Service__c = service.Id
        );

        insert stop;
    }
//
//    @IsTest
//    public static void sendSMSToNextStop() {
//        Stop__c stop = [SELECT Id FROM Stop__c LIMIT 1];
//        stop.StopComplete__c = null;
//        update stop;
//    }
}