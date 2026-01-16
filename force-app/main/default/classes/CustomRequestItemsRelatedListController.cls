public with sharing class CustomRequestItemsRelatedListController {
    @AuraEnabled(cacheable=true)
    public static Map<String, Id> getRecordTypeIdsByObject(String objectApiName) {
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        List<RecordType> rts = [SELECT Id, Name FROM RecordType WHERE SObjectType = :objectApiName];

        for (RecordType rt : rts) {
            recordTypeMap.put(rt.Name, rt.Id);
        }
        
        return recordTypeMap;
    }
}