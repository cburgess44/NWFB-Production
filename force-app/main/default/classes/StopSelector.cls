public without sharing class StopSelector {

    private static StopSelector instance = null;

    public static StopSelector getInstance() {
        if (instance == null) {
        instance = new StopSelector();
        }
        return instance;
    }

    public List<Stop__c> getStopsByTripId(Set<Id> tripId){
        return [
                SELECT
                        Id,
                        Address__c,
                        StopOrder__c,
                        TravelTime__c,
                        Trip__c,
                        Customer__c,
                        StopStartedMessage__c,
                        TripStartedMessage__c,
                        Customer__r.MobilePhone,
                        StopComplete__c,
                        Customer__r.FirstName,
                        Customer__r.LastName,
                        Service__r.ContactName__c,
                        Service__r.DriverName__c,
                        Service__r.CopilotName__c,
                        Service__r.Copilot2Name__c,
                        Service__r.Location__r.City__c
                FROM Stop__c
                WHERE Trip__c IN :tripId
                ORDER BY StopOrder__c ASC
        ];
    }

    public List<Stop__c> byId(Set<Id> stopIds){
        return [
                SELECT
                        Id,
                        Address__c,
                        StopOrder__c,
                        TravelTime__c,
                        TripStartedMessage__c,
                        StopStartedMessage__c,
                        Customer__c,
                        Trip__c,
                        Customer__r.MobilePhone,
                        Customer__r.FirstName,
                        Customer__r.LastName,
                        Service__r.ContactName__c,
                        Service__r.DriverName__c,
                        Service__r.CopilotName__c,
                        Service__r.Copilot2Name__c
                FROM Stop__c
                WHERE Id IN :stopIds
                ORDER BY StopOrder__c ASC
        ];
    }


    public List<Stop__c> getIncompleteStopsById(Set<Id> tripIds){
        return [
                SELECT
                        Id,
                        Address__c,
                        StopOrder__c,
                        TravelTime__c,
                        TripStartedMessage__c,
                        StopStartedMessage__c,
                        StopComplete__c,
                        Customer__c,
                        Trip__c,
                        Customer__r.MobilePhone,
                        Customer__r.FirstName,
                        Customer__r.LastName,
                        Service__r.Location__r.City__c,
                        Service__r.ContactName__c,
                        Service__r.DriverName__c,
                        Service__r.CopilotName__c,
                        Service__r.Copilot2Name__c
                FROM Stop__c
                WHERE Trip__c IN :tripIds AND StopComplete__c = NULL
                ORDER BY StopOrder__c DESC
        ];
    }
}