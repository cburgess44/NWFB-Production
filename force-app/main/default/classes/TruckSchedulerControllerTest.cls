/**
 * Created by Gustavo on 05/01/24.
 */

@IsTest
private class TruckSchedulerControllerTest {
    @IsTest
    static void testBehavior() {

        TruckSchedulerController.Marker marker = new TruckSchedulerController.Marker();
        TruckSchedulerController.Location location = new TruckSchedulerController.Location();

        location.PostalCode='123';
        location.Street='street';
        location.Country='country';
        location.State = 'state';





        Schema.DescribeSObjectResult describeService = Service__c.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = describeService.getRecordTypeInfosByName();

        Location__c locations = new Location__c(
                Name = 'Test - NWFB'
        );
        insert locations;

        Truck__c truck = new Truck__c(
                LicensePlate__c = '00001',
                Active__c = true
        );
        insert truck;
        Pickup__c pick = new Pickup__c();
        insert pick;
        Trip__c trip = new Trip__c(
                Name = 'Test Trip',
                Date__c = Date.today(),
                Location__c = locations.Id,
                Status__c = 'Active',
                Truck__c = truck.Id
        );
        insert trip;
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
                SubType__c = 'Event',
                Date__c = System.today()
        );
        insert service;


        Stop__c stop = new Stop__c(
                Service__c = service.Id
        );
        insert stop;

        TruckSchedulerController.getPickupsAndRequests(System.today());

        marker.isChecked = true;
        marker.id=pick.Id;
        marker.contact='contact';
        marker.contactName='name';
        marker.eta='10';
        marker.items='items';
        marker.label='label';
        marker.value='value';
        marker.timeFrame='timeframe';
        marker.title='Pickup';
        marker.description='description';
        marker.location=location;
        marker.mapIcon='mapIcon';
        marker.icon='icon';
        marker.numberOfItems='number';
        marker.isAddable='isAdd';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        TruckSchedulerController.createStop(marker, trip.Id);
        marker.title = 'Delivery';
        marker.id =service.id;
        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        TruckSchedulerController.createStop(marker, trip.Id);
        Test.stopTest();
    }

    @IsTest
    static void testBehaviorCalculate() {

        TruckSchedulerController.Marker marker = new TruckSchedulerController.Marker();
        TruckSchedulerController.Location location = new TruckSchedulerController.Location();

        location.PostalCode='123';
        location.Street='street';
        location.Country='country';
        location.State = 'state';





        Schema.DescribeSObjectResult describeService = Service__c.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = describeService.getRecordTypeInfosByName();

        Location__c locations = new Location__c(
                Name = 'Test - NWFB'
        );
        insert locations;

        Truck__c truck = new Truck__c(
                LicensePlate__c = '00001',
                Active__c = true
        );
        insert truck;
        Pickup__c pick = new Pickup__c();
        insert pick;
        Trip__c trip = new Trip__c(
                Name = 'Test Trip',
                Date__c = Date.today(),
                Location__c = locations.Id,
                Status__c = 'Active',
                Truck__c = truck.Id
        );
        insert trip;
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
                SubType__c = 'Event',
                Date__c = System.today()
        );
        insert service;


        Stop__c stop = new Stop__c(
                Service__c = service.Id
        );
        insert stop;

        TruckSchedulerController.getPickupsAndRequests(System.today());

        marker.isChecked = true;
        marker.id=pick.Id;
        marker.contact='contact';
        marker.contactName='name';
        marker.eta='10';
        marker.items='items';
        marker.label='label';
        marker.value='value';
        marker.timeFrame='timeframe';
        marker.title='Pickup';
        marker.description='description';
        marker.location=location;
        marker.mapIcon='mapIcon';
        marker.icon='icon';
        marker.numberOfItems='number';
        marker.isAddable='isAdd';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        TruckSchedulerController.calculateTrip(trip.Id);
        Test.stopTest();
    }
}