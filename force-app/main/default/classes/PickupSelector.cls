public with sharing class PickupSelector {

    private static PickupSelector instance = null;

    public static PickupSelector getInstance() {
        if (instance == null) {
        instance = new PickupSelector();
        }
        return instance;
    }
    public List<Pickup__c> getPickupsByStopsIds(Set<Id> stopIds){
        return [SELECT Id, Name, Area__r.ZipCode__c, Area__r.Street__c,
                Area__r.PhysicalAddress__c,
                Area__r.Name, Area__r.Timeframe__c, Contact__c,
                Contact__r.Name, Stop__r.Trip__c, Stop__r.Trip__r.Status__c
                ,(SELECT Id,Name FROM ServiceItems__r)
                FROM Pickup__c
                WHERE Stop__c IN: stopIds];
    }
    public List<Pickup__c> getPickupsByDate(Date pickDate){
        return [SELECT Id, Name, Area__r.ZipCode__c, Area__r.Street__c,
                Area__r.PhysicalAddress__c,
                Area__r.Name, Area__r.Timeframe__c, Contact__c,
                Contact__r.Name, Stop__r.Trip__c, Stop__r.Trip__r.Status__c,
                Stop__c
                ,(SELECT Id,Name FROM ServiceItems__r)
                FROM Pickup__c
                WHERE Date__c =: pickDate];
    }
}