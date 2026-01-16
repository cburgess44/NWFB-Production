public with sharing class RequestSelector {

//    private static RequestSelector instance = null;
//
//    public static RequestSelector getInstance() {
//        if (instance == null) {
//        instance = new RequestSelector();
//        }
//        return instance;
//    }

//    public List<Service__c> getRequestsByStopsIds(Set<Id> stopIds){
//        return [SELECT
//                Id, Name, Area__r.ZipCode__c, Area__r.Street__c,
//                Area__r.PhysicalAddress__c,
//                Area__r.Name, Area__r.Timeframe__c, Contact__c,
//                Contact__r.Name, Stop__r.Trip__c,Stop__r.Trip__r.Status__c
//                ,(SELECT Id,Name FROM ServiceItems__r)
//                FROM Service__c
//                WHERE Stop__c IN: stopIds];
//    }

//    public List<Service__c> getRequestsByDate(Date reqDate){
//        return [SELECT
//                Id, Name, Area__r.ZipCode__c, Area__r.Street__c,
//                Area__r.PhysicalAddress__c,
//                Area__r.Name, Area__r.Timeframe__c, Contact__c,
//                Contact__r.Name, Stop__r.Trip__c,Stop__r.Trip__r.Status__c,
//                Stop__c
//                ,(SELECT Id,Name FROM ServiceItems__r)
//                FROM Service__c
//                WHERE Date__c =: reqDate];
//    }

//    public List<Service__c> getRequestsByContactId(Set<Id> contactIdset){
//        return [SELECT
//                Id,
//                Name,
//                Area__r.ZipCode__c,
//                Area__r.Street__c,
//                Area__r.PhysicalAddress__c,
//                Area__r.Name,
//                Area__r.Timeframe__c,
//                Contact__c,
//                Contact__r.Name,
//                Stop__r.Trip__c,
//                Stop__r.Trip__r.Status__c
//        ,(SELECT Id,Name FROM ServiceItems__r)
//        FROM Service__c
//        WHERE
//         Contact__c IN: contactIdset];
//    }

//    public List<AggregateResult> getRequestsByContactIdAndDate(Set<Id> contactIdSet){
//
//        List<AggregateResult> aggreateResultList = [
//            SELECT COUNT(Id) RequestAmount__c, Contact__c
//            FROM Service__c
//            WHERE Contact__c  IN : contactIdSet AND createdDate = LAST_N_MONTHS:12
//        	GROUP BY Contact__c
//        ];
//
//        return aggreateResultList;
//    }
    
//    public List<Service__c> getRequestById(Set<Id> requestIds){
//        return [SELECT
//        Id, Name, Area__r.ZipCode__c, Area__r.Street__c, Location__r.Name, Location__c, Location__r.Address__c, Location__r.TwilioPhoneNumber__c,
//        Area__r.PhysicalAddress__c, Location__r.RedirecPhonetNumber__c, Date__c,
//        Area__r.Name, Area__r.Timeframe__c, Contact__c, OwnerId,
//        Contact__r.Name, Contact__r.MobilePhone, Contact__r.Email, Stop__r.Trip__c,Stop__r.Trip__r.Status__c
//        ,(SELECT Id,Name FROM ServiceItems__r WHERE Product__r.Category__c = 'Mattresses' AND Product__r.Invoiceable__c = true), LogCallAttempts__c,
//        EmailAttempts__c,
//        OutgoingSMSAttempts__c
//        FROM Service__c
//        WHERE Id IN: requestIds];
//    }

//    public Map<Id, Service__c> getRequestByIds(Set<Id> requestIds){
//        return new Map<Id, Service__c>([SELECT
//        Id, Name, Area__r.ZipCode__c, Area__r.Street__c, Location__r.Name, Location__c, Location__r.Address__c, Location__r.TwilioPhoneNumber__c,
//        Area__r.PhysicalAddress__c, Location__r.RedirecPhonetNumber__c,
//        Area__r.Name, Area__r.Timeframe__c, Contact__c, OwnerId,
//        Contact__r.Name, Contact__r.MobilePhone, Contact__r.Email, Stop__r.Trip__c,Stop__r.Trip__r.Status__c
//        ,(SELECT Id,Name FROM ServiceItems__r)
//        FROM Service__c
//        WHERE Id IN: requestIds]);
//    }

}