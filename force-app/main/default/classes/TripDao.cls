public without sharing class TripDao extends GenericDao {
    @TestVisible
    private static TripDao mock;

    public TripDao() {
    }

    private TripDao(List<SObject> services, Map<Id, SObject> oldServicesById) {
        super(services, oldServicesById);
    }

    private TripDao(List<SObject> services) {
        super(services);
    }

    public static TripDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new TripDao(new List<Stop__c>());
        }
    }

    public override void afterInsert() {
        rollup();
    }

    public override void afterUpdate() {
        sendSMSOnTripStart();
        rollup();
    }
    public override void afterDelete() {
        rollup();
    }

    public override void beforeInsert() {
        setTripName();
        setTripStatusAndDate();
    }

    public override void beforeUpdate() {
        setTripStatusAndDate();
        setStopTravelTimes();
    }

    private void rollup() {
        Database.update(dlrs.RollupService.rollup(this.records), false);
    }

    private void setStopTravelTimes(){
        Set<Id> tripIds = new Set<Id>();

        for (Trip__c trip : (List<Trip__c>) this.records) {
            tripIds.add(trip.Id);
        }

       System.enqueueJob(new GoogleMapsIntegrationQueuable(tripIds));
    }

    private void setTripStatusAndDate() {
        Map<Id, SObject> tripByService = Utils.listToMap('Service__c', this.records);

        Map<Id, SObject> servicesByIds = Utils.listToMap(
                'Id',
                (List<SObject>) new ServiceSelector().getServiceByIds(tripByService.keySet())
        );

        Map<Id, Trip__c> oldRecordsMap = new Map<Id, Trip__c>();
        oldRecordsMap = (Map<Id, Trip__c>) this.oldRecordsById;

        Map<Id, Service__c> serviceToUpdate = new Map<Id, Service__c>();

        for (Trip__c trip : (List<Trip__c>) this.records) {
            if (trip.Service__c == null || oldRecordsMap?.get(trip.Id)?.Service__c == trip.Service__c) continue;

            Service__c service = (Service__c) servicesByIds.get(trip.Service__c);

            if (service.Status__c != 'Routing' && oldRecordsMap?.get(trip.Id) == null) {
                trip.addError('Can not insert a trip if the Service Status is not "Routing"');
                continue;
            }

            if (service.RecordType.DeveloperName == 'ClientRequest' && service?.Delivery_Type__c == 'Will Call') {
                trip.addError('Can not select this status because the related Service Delivery type is a "will call"');
                continue;
            }

            service.Status__c = 'Shopping';
            serviceToUpdate.put(service.Id, service);
            trip.Date__c = service.Date__c;
        }

        TriggerManagement.disableTrigger('ServiceTrigger');
        if (!serviceToUpdate.isEmpty()) {
            Database.update(serviceToUpdate.values(), false);
        }
        TriggerManagement.enableTrigger('ServiceTrigger');

    }

    private void setTripName() {
        for (Trip__c trip : (List<Trip__c>) this.records) {
            if (trip.CustomName__c == null) continue;

            trip.Name = trip.CustomName__c + ' ' + trip.Date__c.format();
        }
    }

    private void sendSMSOnTripStart() {
        Set<Id> tripIds = new Set<Id>();

        for (Trip__c trip : (List<Trip__c>) records) {
            Trip__c oldTrip = (Trip__c) oldRecordsById.get(trip.Id);
            if (oldTrip.Status__c == 'Started' && trip.Status__c == 'Started') continue;
            if (trip.Status__c != 'Started') continue;
            tripIds.add(trip.Id);
        }

        Map<String, List<SObject>> stopsByTrip = Utils.listToMapLists(
                'Trip__c',
                new StopSelector().getStopsByTripId(tripIds)
        );


        for (Trip__c trip : (List<Trip__c>) records) {
            Trip__c oldTrip = (Trip__c) oldRecordsById.get(trip.Id);

            if (oldTrip.Status__c == 'Started' && trip.Status__c == 'Started') continue;
            if (trip.Status__c != 'Started') continue;

            List<Stop__c> stops = (List<Stop__c>) stopsByTrip.get(trip.Id);
            Stop__c firstStop = null;

            for (Stop__c stop : stops) {
                if (stop.StopComplete__c != null) continue;
                firstStop = stop;
                break;
            }

            if (firstStop == null) continue;

            System.enqueueJob(
                    new SendSMSQueueable(
                            firstStop.Service__r.Location__r.City__c,
                            firstStop.Customer__r.MobilePhone,
                            firstStop.TripStartedMessage__c
                    )
            );

            System.enqueueJob(
                    new SendSMSQueueable(
                            firstStop.Service__r.Location__r.City__c,
                            firstStop.Customer__r.MobilePhone,
                            firstStop.StopStartedMessage__c
                    )
            );
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new TripDao(objects, oldObjectsById);
        }
    }
}