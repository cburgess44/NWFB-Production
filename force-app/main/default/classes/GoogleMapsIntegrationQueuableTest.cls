/**
 * Created by Eric Solari on 04/01/2024.
 */
@IsTest
public with sharing class GoogleMapsIntegrationQueuableTest {

    @IsTest
    public static void testQueuable(){
        Location__c tacoma = new Location__c(city__c ='Tacoma', State__c ='WA');
        insert tacoma;
        Truck__c truck = new Truck__c();
        insert truck;
        Id recordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName().get('ClientRequest').getRecordTypeId();
        Service__c service = new Service__c(Address__c = '3222 E D Street', City__c = 'Tacoma', State__c ='WA', Zip__c='98404', RecordTypeId = recordTypeId, SubType__c='Delivery');
        insert service;
        Trip__c trip = new Trip__c(Truck__c = truck.id, Location__c = tacoma.Id);
        insert trip;
        Stop__c stop = new Stop__c(Service__c = service.Id, Trip__c = trip.Id);
        insert stop;
        List<Stop__c> stops = [SELECT id, Address__c, Service__c, Service__r.RecordType.DeveloperName, Service__r.SubType__c FROM Stop__c];
        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        Test.startTest();
        GoogleMapsIntegrationQueuable scb = new GoogleMapsIntegrationQueuable(new Set<Id>{trip.Id});
        scb.execute(null);
        Test.stopTest();
    }
}