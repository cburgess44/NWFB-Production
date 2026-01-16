/**
 * Created by Gustavo on 08/01/24.
 */

@IsTest
private class GenericTripListViewControllerTest {
    @IsTest
    static void getLocations() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Location__c location = new Location__c(
                Name = 'Test - NWFB'
        );
        insert location;

        Area__c area = new Area__c(
                Location__c = location.Id,
                Name = 'Test Area',
                Timeframe__c = 'Morning'
        );
        insert area;

        Truck__c truck = new Truck__c(
                LicensePlate__c = '12313',
                Name = 'Test',
                Active__c = true,
                Location__c = location.Id
        );
        insert truck;

        Trip__c trip = new Trip__c(
                Name = 'Test Trip',
                Date__c = Date.today(),
                Location__c = location.Id,
                Status__c = 'Active',
                Truck__c = truck.Id
        );
        insert trip;

        TriggerManagement.disableTrigger('ServiceTrigger');
        Service__c service = new Service__c(
                Contact__c = contact.Id
        );
        insert service;

        TriggerManagement.disableTrigger('StopTrigger');
        Stop__c stop = new Stop__c(
                Service__c = service.Id,
                Trip__c = trip.Id
        );
        insert stop;
        TriggerManagement.enableTrigger('StopTrigger');

        service.Stop__c = stop.Id;
        update service;
        TriggerManagement.enableTrigger('ServiceTrigger');

        Pickup__c pickup = new Pickup__c(
                Name = 'Test',
                Stop__c = stop.Id,
                Location__c = location.Id,
                Contact__c = contact.Id,
                Area__c = area.Id
        );
        insert pickup;


        System.assert(!GenericTripListViewController.getLocations(trip.Id, 'Id', '').isEmpty());
    }
}