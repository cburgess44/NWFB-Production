public with sharing class CustomMetadataSelector {
    private static CustomMetadataSelector instance = null;

    public static CustomMetadataSelector getInstance() {
        if (instance == null) {
        instance = new CustomMetadataSelector();
        }
        return instance;
    }

    public List<ServiceFeesSettings__mdt> getMdtByStatus(){
        return [
            SELECT Id, FeeAmount__c, IsActive__c, DeveloperName, DeliveryFeeAmount__c
            FROM ServiceFeesSettings__mdt          
            WHERE IsActive__c = TRUE
        ];
    }
}