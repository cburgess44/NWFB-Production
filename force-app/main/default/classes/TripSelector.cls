public with sharing class TripSelector {

    private static TripSelector instance = null;

    public static TripSelector getInstance() {
        if (instance == null) {
        instance = new TripSelector();
        }
        return instance;
    }

    public List<Trip__c> getTripById(Id tripId){
        return [SELECT Id, Location__r.Address__c, Origin__r.PhysicalAddress__c, Destination__r.PhysicalAddress__c, (SELECT Id,Name, Address__c, TravelTime__c FROM Stops__r) FROM Trip__c WHERE Id = :tripId];
    }
    public List<Trip__c> getTripByIdSet(Set<Id> tripIdSet){
        return [SELECT Id, Location__r.Address__c, Origin__r.PhysicalAddress__c, Destination__r.PhysicalAddress__c, Service__r.Status__c, Service__r.RecordType.DeveloperName, Service__c,  (SELECT Id,Name, Address__c, TravelTime__c FROM Stops__r) FROM Trip__c WHERE Id IN :tripIdSet];
    }

}