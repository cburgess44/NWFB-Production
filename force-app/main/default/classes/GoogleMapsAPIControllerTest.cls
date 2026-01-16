/**
 * Created by Eric Solari on 04/01/2024.
 */
@IsTest
public with sharing class GoogleMapsAPIControllerTest {

    @IsTest
    public static void testBuildGetDirectionsURL(){
        Id recordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName().get('ClientRequest').getRecordTypeId();
        Service__c service = new Service__c(Address__c = '3222 E D Street', City__c = 'Tacoma', State__c ='WA', Zip__c='98404', RecordTypeId = recordTypeId, SubType__c='Delivery');
        insert service;
        Stop__c stop = new Stop__c(Service__c = service.Id);
        insert stop;
        List<Stop__c> stops = [SELECT id, Address__c, Service__c, Service__r.RecordType.DeveloperName, StopOrder__c, Customer__r.Name, Service__r.SubType__c FROM Stop__c];

        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        Test.startTest();
        GoogleMapsAPIController.buildGetDirectionsURL(stops , 'Tacoma');
        GoogleMapsAPIController.getIframeMapsUrl(null,stops, 'Tacoma', true );
        GoogleMapsAPIController.getMapDirections(stops , 'Tacoma');
        Test.stopTest();
    }

    @IsTest
    public static void testAPICall(){
        Id recordTypeId = Schema.SObjectType.Service__c.getRecordTypeInfosByDeveloperName().get('ClientRequest').getRecordTypeId();
        Service__c service = new Service__c(Address__c = '3222 E D Street', City__c = 'Tacoma', State__c ='WA', Zip__c='98404', RecordTypeId = recordTypeId, SubType__c='Delivery');
        insert service;
        Stop__c stop = new Stop__c(Service__c = service.Id);
        insert stop;
        List<Stop__c> stops = [SELECT id, Address__c, Service__c, Service__r.RecordType.DeveloperName, StopOrder__c, Customer__r.Name, Service__r.SubType__c FROM Stop__c];

        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        Test.startTest();
        GoogleMapsIntegrationApi api = new GoogleMapsIntegrationApi();
        api.getRoute('Tacoma', stops);
        Test.stopTest();
    }
}