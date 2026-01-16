/**
 * Created by Gustavo on 28/02/23.
 */

public without sharing class AreaSelector {

    private static AreaSelector instance = null;

    public static AreaSelector getInstance() {
        if (instance == null) {
            instance = new AreaSelector();
        }
        return instance;
    }

    public List<Area__c> getAreaByIds(Set<Id> areaIds) {
        return [
                SELECT
                        Id,
                        Name,
                        DaysOfWeek__c,
                        Delivery__c,
                        Location__c,
                        MinimumItems__c,
                        PhysicalAddress__c,
                        Pickup__c,
                        Street__c,
                        Timeframe__c,
                        ZipCode__c
                FROM Area__c
                WHERE Id IN :areaIds
        ];
    }


    public List<Area__c> getAreaByZipCode(Set<String> zipCodes) {
        return [
                SELECT
                        Id,
                        Name,
                        DaysOfWeek__c,
                        Delivery__c,
                        Location__c,
                        MinimumItems__c,
                        PhysicalAddress__c,
                        Pickup__c,
                        Street__c,
                        Timeframe__c,
                        ZipCode__c
                FROM Area__c
                WHERE ZipCode__c IN :zipCodes
        ];
    }

}