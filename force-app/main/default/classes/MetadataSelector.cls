public with sharing class MetadataSelector {

    private static MetadataSelector instance = null;

    public static MetadataSelector getInstance() {
        if (instance == null) {
        instance = new MetadataSelector();
        }
        return instance;
    }

    @AuraEnabled(cacheable=true)
    public static String getAgreementText(){
        return [SELECT Id, AgreementText__c FROM AgreementSetting__mdt LIMIT 1][0].AgreementText__c;
    }
}