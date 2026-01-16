public without sharing class TruckSchedulerController {
    public TruckSchedulerController() {

    }
    @AuraEnabled
    public static Boolean calculateTrip(Id tripId){
        try {
            return TripService.buildStopsTrip(tripId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean createStop(Marker stop, Id tripId){
        try {
            List<Stop__c> tripStops = StopSelector.getInstance().getStopsByTripId(new Set<Id>{tripId});
            Stop__c newStop = new Stop__c();
            newStop.Name = (String) stop.description;
            newStop.Trip__c = tripId;
            insert newStop;
            if(stop.title == 'Pickup'){
                Pickup__c pick = new Pickup__c();
                pick.Id = (Id) stop.id;
                pick.Stop__c = newStop.Id;
                update pick;
            } else {
                Service__c req = new Service__c();
                req.Id = (Id) stop.id;
                req.Stop__c = newStop.Id;
                update req;
            }
            return true;
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }
    @AuraEnabled(cacheable = true)
    public static List<Marker> getPickupsAndRequests(Date tripDate){
        try {
            List<Marker> stops = new List<Marker>();
            List<Marker> deliveries = setMarkers(ServiceSelector.getInstance().getServicesByDate(tripDate), 'Delivery');
            List<Marker> pickups = setMarkers(PickupSelector.getInstance().getPickupsByDate(tripDate), 'Pickup');
            stops.addAll(deliveries);
            stops.addAll(pickups);
            return stops;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
    }
    private static List<Marker> setMarkers(List<SObject> stops, String type){
        List<Marker> markers = new List<Marker>();
        for(SObject stop : stops){
            Marker marker = new Marker();
            marker.id = stop.Id;
            marker.isChecked = true;
            marker.location = new Location();
            marker.label = stop.getSObject('Area__r')?.get('ZipCode__c');
            marker.value = stop.getSObject('Area__r')?.get('ZipCode__c');
            marker.timeFrame = stop.getSObject('Area__r')?.get('Timeframe__c');
            marker.title = type;
            marker.contact = stop.get('Contact__c') != null ? '/' + stop.get('Contact__c') : '';
            marker.contactName = stop.getSObject('Contact__r')?.get('Name');
            marker.eta = '30 minutes';
            marker.isAddable = stop.get('Stop__c') != null ? true : false;
            marker.items = getItems(stop);
            marker.numberOfItems = getNumberOfItems(stop);
            marker.description = stop.getSObject('Area__r')?.get('PhysicalAddress__c');
            marker.location.PostalCode = stop.getSObject('Area__r')?.get('ZipCode__c');
            marker.location.Street = stop.getSObject('Area__r')?.get('Street__c');
            marker.location.Country = 'USA';
            marker.location.State = 'WA';
            marker.mapIcon = type == 'Pickup' ? 'https://webportal.site/images/blue-dot.png' : 'https://webportal.site/images/red-dot.png';
            marker.icon = type == 'Pickup' ? 'custom:custom93' : 'custom:custom33';
            markers.add(marker);
        }
        return markers;
    }
    private static String getItems(SObject stop){
        Map<String, Object> stopMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(stop));
        stopMap = (Map<String, Object>) stopMap?.get('ProductItems__r');
        if(stopMap == null){
            return '';
        }
        List<Object> itemsList = (List<Object>) stopMap?.get('records');
        if(itemsList == null){
            return '';
        } 
        String itemsText = '';
        for(Object item : itemsList){
            Map<String, Object> convertedItem = (Map<String, Object>) item;
            itemsText += convertedItem.get('Name') + '\n';
        }
        return itemsText;
    }
    private static Integer getNumberOfItems(SObject stop){
        Map<String, Object> stopMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(stop));
        stopMap = (Map<String, Object>) stopMap?.get('ProductItems__r');
        if(stopMap == null){
            return 0;
        }
        List<Object> itemsList = (List<Object>) stopMap?.get('records');
        if(itemsList == null){
            return 0;
        } 
        return itemsList.size();
    }
    public class Marker {
        @AuraEnabled
        public Object isChecked {get;set;}
        @AuraEnabled
        public Object id {get;set;}
        @AuraEnabled
        public Object contact {get;set;}
        @AuraEnabled
        public Object contactName {get;set;}
        @AuraEnabled
        public Object eta {get;set;}
        @AuraEnabled
        public Object items {get;set;}
        @AuraEnabled
        public Object label {get;set;}
        @AuraEnabled
        public Object value {get;set;}
        @AuraEnabled
        public Object timeFrame {get;set;}
        @AuraEnabled
        public Object title {get;set;}
        @AuraEnabled
        public Object description {get;set;}
        @AuraEnabled
        public Location location {get;set;}
        @AuraEnabled
        public Object mapIcon {get;set;}
        @AuraEnabled
        public Object icon {get;set;}
        @AuraEnabled
        public Object numberOfItems {get;set;}    
        @AuraEnabled
        public Object isAddable {get;set;}    
        
    }
    public class Location {
        @AuraEnabled
        public Object PostalCode {get;set;}
        @AuraEnabled
        public Object Street {get;set;}
        @AuraEnabled
        public Object Country {get;set;}
        @AuraEnabled
        public Object State {get;set;}
    }
}