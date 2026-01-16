public with sharing class LocationSelector {

    private static LocationSelector instance = null;

    public static LocationSelector getInstance() {
        if (instance == null) {
        instance = new LocationSelector();
        }
        return instance;
    }

    public Map<Id, Location__c> getLocationByIds(Set<Id> locationIdSet){
        return new Map<Id, Location__c>([
                SELECT Id, TaxRate__c                
                FROM Location__c 
                WHERE Id =: locationIdSet
        ]);
    }

    public List<Location__c> getLocationByCityName(Set<String> citiesName) {
        return new List<Location__c>([
            SELECT
                    Id,
                    Name,
                    City__c
            FROM Location__c
            WHERE City__c IN :citiesName
        ]);
    }
}