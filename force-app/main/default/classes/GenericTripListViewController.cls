public without sharing class GenericTripListViewController {
    public GenericTripListViewController() {

    }
    @AuraEnabled(cacheable = true)
    public static List<Trip> getLocations(String recordId, String sObjectApiName, String filters){
//        try {
            String query = 'SELECT Id,Name, Date__c, Location__c, Truck__r.Name, (SELECT Id FROM Stops__r) FROM Trip__c WHERE ' + sObjectApiName + ' = ' + '\'' + recordId +'\' ' + filters;
            List<Location__c> locations = [SELECT Id,Name FROM Location__c];
            Map<Id,SObject> trips = new Map<Id,SObject>(Database.query(query));
            System.debug('trips => ' + trips);
            Map<Id,Stop__c> stopMap = new Map<Id,Stop__c>([SELECT Id FROM Stop__c WHERE Trip__c IN : trips.keySet()]);
            List<Service__c> requests = ServiceSelector.getInstance().getServicesByStopsIds(stopMap.keySet());
            List<Pickup__c> pickups = PickupSelector.getInstance().getPickupsByStopsIds(stopMap.keySet());
            Map<String,Trip> tripsMap = new Map<String,Trip>();
            
            for(Service__c request : requests){
                Trip trip = tripsMap.get(request.Stop__r.Trip__c) != null ? tripsMap.get(request.Stop__r.Trip__c) : new Trip(request.Stop__r.Trip__c);
                trip.deliveries += 1;
                //trip.destination += request.City__c;
                if(trip.timeframe == null){
                    trip.timeframe = request.Area__r.Timeframe__c == null ? '' : request.Area__r.Timeframe__c;
                } else {
                    trip.timeframe += trip.timeframe.contains(request.Area__r.Timeframe__c) ? '' : (', ' + request.Area__r.Timeframe__c);
                }
                trip.status = request.Stop__r.Trip__r.Status__c;
                trip.destination += trip.destination == '' ? request.Name : ', ' + request.Name;
                tripsMap.put(trip.id, trip);
            }

            for(Pickup__c pickup : pickups){
                Trip trip = tripsMap.get(pickup.Stop__r.Trip__c) != null ? tripsMap.get(pickup.Stop__r.Trip__c) : new Trip(pickup.Stop__r.Trip__c);
                trip.pickups += 1;
                trip.status = pickup.Stop__r.Trip__r.Status__c;
                //trip.destination += pickup.City__c;
                if(trip.timeframe == null){
                    trip.timeframe = pickup.Area__r.Timeframe__c == null ? '' : pickup.Area__r.Timeframe__c;
                } else {
                    trip.timeframe += trip.timeframe.contains(pickup.Area__r.Timeframe__c) ? '' : (', ' + pickup.Area__r.Timeframe__c);
                }
                trip.destination += trip.destination == '' ? pickup.Name : ', ' + pickup.Name;
                tripsMap.put(trip.id, trip);
            }

            for(Trip trip : tripsMap.values()){
                trip.tripDate = (Date) trips.get(trip.id).get('Date__c');
                trip.locationId = (Id) trips.get(trip.id).get('Location__c');
                trip.trip = trips.get(trip.id);
                trip.truckName = (String) trips.get(trip.id).getSObject('Truck__r').get('Name');
                tripsMap.put(trip.id, trip);
            }
            
            return tripsMap.values();

//        } catch (Exception e) {
//            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
//        }
    }

    public class Trip {
        @AuraEnabled
        public Date tripDate {get;set;}
        @AuraEnabled
        public Id locationId {get;set;}
        @AuraEnabled
        public SObject trip {get;set;}
        @AuraEnabled
        public Id id {get;set;}
        @AuraEnabled
        public String destination {get;set;}
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public String truckName {get;set;}
        @AuraEnabled
        public String timeframe {get;set;}
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