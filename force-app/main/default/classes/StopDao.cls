public without sharing class StopDao extends GenericDao {
    @TestVisible
    private static StopDao mock;

    public StopDao() {
    }

    private StopDao(List<SObject> stops, Map<Id, SObject> oldStopsById) {
        super(stops, oldStopsById);
    }
    private StopDao(List<SObject> stops) {
        super(stops);
    }

    public static StopDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new StopDao(new List<Stop__c>());
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldStopsById) {
            return new StopDao(objects, oldStopsById);
        }
    }

    public override void afterInsert() {
        setTripStartedMessage();
        rollup();
    }

    public override void beforeInsert() {
        setStopName();
        calculateStopTime();
    }

    public override void beforeUpdate() {
        setStopName();
        calculateStopTime();
    }
    public override void afterUpdate() {
        stopComplete();
        setTripStartedMessage();
        rollup();
    }
    public override void afterDelete() {
        rollup();
    }

    private void rollup() {
        Database.update(dlrs.RollupService.rollup(this.records), false);
    }

    private void setStopName() {
        for (Stop__c stop : (List<Stop__c>) this.records) {
            stop.Name = stop.Address__c;
        }
    }

    private void calculateStopTime() {
        Set<Id> serviceIds = new Set<Id>();

        for (Stop__c stop : (List<Stop__c>) records) {
            if (stop.Service__c == null) continue;
            serviceIds.add(stop.Service__c);
        }

        Map<Id, SObject> serviceByIds = Utils.listToMap(
                'Id',
                ServiceSelector.getInstance().getServiceByIds(serviceIds)
        );

        List<String> usuallyItems = new List<String>{
                'Lamp',
                'Kitchen Items (boxed/bagged)',
                'Linens (boxed/bagged)',
                'Framed Art',
                'Appliance',
                'Mirror',
                'Accessories'
        };

        for (Stop__c stop : (List<Stop__c>) records) {
            Service__c currentService = (Service__c) serviceByIds.get(stop.Service__c);
            if (currentService == null) continue;

            if (currentService.RecordTypeName__c != 'DonationPickup') {
                stop.StopTime__c = 30;
                continue;
            }

            if (currentService.ServiceItems__r == null || currentService.ServiceItems__r.isEmpty()) continue;

            Decimal totalItems = 0;

            for (ServiceItem__c serviceItem : currentService.ServiceItems__r) {
                if (usuallyItems.contains(serviceItem.Product__r.Name)) {
                    totalItems++;
                    continue;
                }

                totalItems += serviceItem.Quantity__c;
            }

            if (totalItems >= 1 && totalItems <= 3) {
                stop.StopTime__c = 15;
            } else if (totalItems >= 4 && totalItems <= 5) {
                stop.StopTime__c = 20;
            } else if (totalItems >= 6 && totalItems <= 8) {
                stop.StopTime__c = 30;
            } else if (totalItems >= 9 && totalItems <= 12) {
                stop.StopTime__c = 45;
            } else if (totalItems >= 13) {
                stop.StopTime__c = 60;
            }
        }
    }

    private void setTripStartedMessage() {
        Map<Id, Stop__c> stopById = new Map<Id, Stop__c>((List<Stop__c>) records);
        List<Stop__c> stops = new StopSelector().byId(stopById.keySet());
        List<Stop__c> pendingStops = new List<Stop__c>();

        for (Stop__c stop : stops) {
            if (!String.isEmpty(stop.TripStartedMessage__c)) continue;

            String driverName = stop.Service__r.DriverName__c != null
                ? stop.Service__r.DriverName__c
                : '';

            String copilotName = stop.Service__r.CopilotName__c != null
                ? stop.Service__r.CopilotName__c
                : '';

            String copilot2Name = stop.Service__r.Copilot2Name__c != null
                ? stop.Service__r.Copilot2Name__c
                : '';

            String tripStartedMessage = 'Hello ' + stop.Service__r.ContactName__c + ',\n' +
                    '\n' +
                    'The NW Furniture Bank truck has been dispatched from the warehouse for pick-up and delivery service.  ' +
                    'Below is the crew that will be providing service today.  ' +
                    'We will send a text message when are leaving to head your way.\n' +
                    '\n' +
                    'Driver: ' + driverName + '\n' +
                    'Copilot: ' + copilotName + '\n' +
                    'Copilot 2: ' + copilot2Name ;

            String stopStartedMessage = 'This is NW Furniture Bank’s truck crew. We are on our way to your location. ' +
                    'We’ll see you shortly!';

            stop.StopStartedMessage__c = stopStartedMessage;
            stop.TripStartedMessage__c = tripStartedMessage;
            pendingStops.add(stop);
        }

        TriggerManagement.disableTrigger('StopTrigger');
        update pendingStops;
        TriggerManagement.enableTrigger('StopTrigger');
    }

    private void stopComplete() {
        Map<Id, Stop__c> oldStops = (Map<Id, Stop__c>) this.oldRecordsById;
        Set<Id> tripIds = new Set<Id>();

        Schema.DescribeSObjectResult describeService = Service__c.SObjectType.getDescribe();
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = describeService.getRecordTypeInfosByName();

        String generalPickUpDeveloperName = recordTypeInfoMap.get('General Pickup').getDeveloperName();
        String donationPickupDeveloperName = recordTypeInfoMap.get('Donation Pickup').getDeveloperName();

        for (Stop__c stop : (List<Stop__c>) this.records) {
            Stop__c oldStop = oldStops.get(stop.Id);
            Boolean wasChanged = (stop.StopComplete__c != null && (oldStop.StopComplete__c != stop.StopComplete__c));
            
            if (!wasChanged) continue;
            Date stopCompletedDate = stop.StopComplete__c.date();

            if (stopCompletedDate > Date.today()) continue;

            tripIds.add(stop.Trip__c);
        }
        
        Map<Id, Trip__c> tripMap = new Map<Id, Trip__c>(TripSelector.getInstance().getTripByIdSet(tripIds));
        Map<Id, Service__c> servicesToUpdate = new Map<Id, Service__c>();

        sendSMSToNextStop(tripIds);
        
        for (Stop__c stop : (List<Stop__c>) this.records) {
            String serviceStatus = tripMap?.get(stop.Trip__c)?.Service__r.Status__c;
            String serviceRecordType = tripMap?.get(stop.Trip__c)?.Service__r.RecordType.DeveloperName;

            if (serviceStatus != 'Pick Up' && serviceStatus != 'Delivery') continue;
            if (serviceRecordType != generalPickUpDeveloperName && serviceRecordType != donationPickupDeveloperName) continue;
           
            Service__c service = new Service__c (
                Id = tripMap?.get(stop.Trip__c)?.Service__c,
                Status__c = 'Review'
            );

            servicesToUpdate.put(service.Id, service);
        }

        if (servicesToUpdate == null || servicesToUpdate.isEmpty()) return;
        TriggerManagement.disableTrigger('ServiceTrigger');
        Database.update(servicesToUpdate.values(), false);
        TriggerManagement.enableTrigger('ServiceTrigger');
    }

    private static void sendSMSToNextStop(Set<Id> tripIds) {
        Map<Id, SObject> stopsById = Utils.listToMap(
            'Trip__c',
            new StopSelector().getIncompleteStopsById(tripIds)
        );

        for (Id tripId : tripIds) {
            Stop__c nextStop = (Stop__c) stopsById.get(tripId);

            if (nextStop == null || nextStop.StopComplete__c != null) continue;

            if (!Test.isRunningTest()) {
                System.enqueueJob(
                        new SendSMSQueueable(
                                nextStop.Service__r.Location__r.City__c,
                                nextStop.Customer__r.MobilePhone,
                                nextStop.StopStartedMessage__c
                        )
                );
            }
        }
    }
}