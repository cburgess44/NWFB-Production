/**
 * Created by dudunato on 05/02/22.
 */

public without sharing class SObjectCRUDController {

    public static final GenericDao service;

    static {
        service = GenericDao.getInstance();
    }

    @AuraEnabled
    public static List<SObject> listSObjects(String objectName, List<String> fields, String filters) {
        return service.listSObjects(objectName, fields, filters);
    }

    @AuraEnabled
    public static List<SObject> saveSObjects(List<SObject> sObjects) {
        return service.saveSObjects(sObjects);
    }

    @AuraEnabled
    public static List<SObject> deleteSObjects(List<SObject> sObjects) {
        return service.deleteSObjects(sObjects);
    }

    @AuraEnabled
    public static List<SObject> deleteSObjectsByFilter(String objectName, String filters) {
        return service.deleteSObjectsByFilter(objectName, filters);
    }

    @AuraEnabled
    public static List<PicklistEnum.Entry> getPicklist(String objectName, String fieldName) {
        return service.getPicklist(objectName, fieldName);
    }

    @AuraEnabled(cacheable=true)
    public static NWFBSettings__c  getCustomSettings(){
        return NWFBSettings__c.getOrgDefaults();
    }
}