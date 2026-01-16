public without sharing class ServiceItemSelector {
//    public List<ServiceItem__c> getRequestItemByIds(Set<Id> requestItemIdSet) {
//        return [
//                SELECT
//                        Id,
//                        Name,
//                        Description__c,
//                        TotalItemPrice__c,
//                        Pickup__c,
//                        Product__c,
//                        Quantity__c,
//                        Service__c,
//                        Status__c,
//                        Stop__c,
//                        TaxableItem__c,
//                        Total_Estimated_Value__c,
//                        Total_Fee__c,
//                        Service__r.RecordTypeId,
//                        Service__r.RecordType.DeveloperName,
//                        Product__r.Pick_up_Fee__c,
//                        Product__r.Product_Fee__c,
//                        Product__r.Estimated_Value__c
//                FROM ServiceItem__c
//                WHERE Id IN :requestItemIdSet
//
//        ];
//
//    }

    public List<ServiceItem__c> getServiceItemsByServiceId(Id serviceId){
        return [
                SELECT
                        Id,
                        Name,
                        Description__c,
                        TotalItemPrice__c,
                        Pickup__c,
                        Product__r.Name,
                        Product__c,
                        Quantity__c,
                        Service__c,
                        Status__c,
                        Stop__c,
                        TaxableItem__c,
                        Total_Estimated_Value__c,
                        Override_Product_Fee__c,
                        Total_Fee__c
                FROM ServiceItem__c
                WHERE Service__c = :serviceId
        ];
    }

    public List<ServiceItem__c> getServiceItemsByServiceIds(Set<Id> serviceIds){
        return [
                SELECT
                        Id,
                        Name,
                        Description__c,
                        TotalItemPrice__c,
                        Pickup__c,
                        Product__r.Name,
                        Product__c,
                        Quantity__c,
                        Service__c,
                        Status__c,
                        Stop__c,
                        TaxableItem__c,
                        Total_Estimated_Value__c,
                        Override_Product_Fee__c,
                        Total_Fee__c
                FROM ServiceItem__c
                WHERE Service__c IN :serviceIds
        ];
    }


    public List<ServiceItem__c> getTaxableServiceItemsById(Set<Id> serviceId){
        return [
                SELECT
                        Id,
                        Name,
                        Description__c,
                        TotalItemPrice__c,
                        Pickup__c,
                        Product__c,
                        Quantity__c,
                        Service__c,
                        Status__c,
                        Stop__c,
                        TaxableItem__c,
                        Total_Estimated_Value__c,
                        Total_Fee__c
                FROM ServiceItem__c
                WHERE Service__c IN :serviceId AND TaxableItem__c = TRUE
        ];
    }
}