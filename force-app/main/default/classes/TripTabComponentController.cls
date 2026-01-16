public without sharing class TripTabComponentController {
    public TripTabComponentController() {

    }
    @AuraEnabled(cacheable = true)
    public static List<Tab> getLocations(){
        try {
            Map<String,Tab> tabs = new Map<String,Tab>();
            List<Location__c> locations = [SELECT Id,Name FROM Location__c];
            Map<Id,Trip__c> trips = new Map<Id,Trip__c>([SELECT Id,Name, Date__c, Location__c, Status__c, (SELECT Id FROM Stops__r) FROM Trip__c]);
            Map<Id,Stop__c> stopMap = new Map<Id,Stop__c>([SELECT Id FROM Stop__c WHERE Trip__c IN : trips.keySet()]);
            List<Service__c> requests = ServiceSelector.getInstance().getServicesByStopsIds(stopMap.keySet()); 
            List<Pickup__c> pickups = PickupSelector.getInstance().getPickupsByStopsIds(stopMap.keySet());
            Map<String,Trip> tripsMap = new Map<String,Trip>();
            
            for(Trip__c trip : trips.values()){
                tripsMap.put(trip.Id, new Trip(trip.Id));
                System.debug(new Trip(trip.Id));
            }

            for(Service__c request : requests){
                Trip trip = tripsMap.get(request.Stop__r.Trip__c) != null ? tripsMap.get(request.Stop__r.Trip__c) : new Trip(request.Stop__r.Trip__c);
                trip.deliveries += 1;
                //trip.destination += request.City__c;
                trip.destination += trip.destination == '' ? request.Name : ', ' + request.Name;
                tripsMap.put(trip.id, trip);
            }

            for(Pickup__c pickup : pickups){
                Trip trip = tripsMap.get(pickup.Stop__r.Trip__c) != null ? tripsMap.get(pickup.Stop__r.Trip__c) : new Trip(pickup.Stop__r.Trip__c);
                trip.pickups += 1;
                //trip.destination += pickup.City__c;
                
                trip.destination += trip.destination == '' ? pickup.Name : ', ' + pickup.Name;
                tripsMap.put(trip.id, trip);
            }

            for(Trip trip : tripsMap.values()){
                trip.tripDate = trips.get(trip.id).Date__c;
                trip.locationId = trips.get(trip.id).Location__c;
                trip.status = trips.get(trip.id).Status__c;
                trip.trip = trips.get(trip.id);
                tripsMap.put(trip.id, trip);
                System.debug(trip);
            }
            System.debug(tripsMap);
            
            for(Location__c loc : locations){
                Tab tab = new Tab();
                tab.name = loc.Name;
                tab.id = loc.Id;
                tabs.put(tab.id,tab);
            }
            
            for(Trip trip : tripsMap.values()){
                Tab tab = tabs.get(trip.locationId);
                if(trip.status == 'Active'){
                    tab.activeData.add(trip);
                } else if(trip.status == 'Completed'){
                    tab.completeData.add(trip);
                } else if(trip.status == 'Pending'){
                    tab.pendingData.add(trip);
                }
                tabs.put(trip.locationId, tab);
            }

            return tabs.values();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class Tab {
        @AuraEnabled
        public List<Trip> activeData {get;set;}
        @AuraEnabled
        public List<Trip> completeData {get;set;}
        @AuraEnabled
        public List<Trip> pendingData {get;set;}
        @AuraEnabled
        public Object name {get;set;}
        @AuraEnabled
        public Id id {get;set;}

        Tab(){
            this.activeData = new List<Trip>();
            this.completeData = new List<Trip>();
            this.pendingData = new List<Trip>();
        }
    }
    public class Trip {
        @AuraEnabled
        public Date tripDate {get;set;}
        @AuraEnabled
        public Id locationId {get;set;}
        @AuraEnabled
        public Trip__c trip {get;set;}
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public String destination {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public Integer pickups {get;set;}
        @AuraEnabled
        public Integer deliveries {get;set;}

        Trip(Id id){
            this.id = id;
            this.pickups = 0;
            this.deliveries = 0;
            this.destination = '';
        }
    }
}